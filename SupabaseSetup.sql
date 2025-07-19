-- RecallMate Friend System Database Schema
-- Execute this in Supabase SQL Editor

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Profiles table (extends auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    username TEXT,
    full_name TEXT,
    nickname TEXT,
    study_code TEXT UNIQUE,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Study sessions table
CREATE TABLE IF NOT EXISTS public.study_sessions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    start_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    end_time TIMESTAMP WITH TIME ZONE,
    duration INTERVAL DEFAULT '0 seconds',
    session_type TEXT DEFAULT 'general',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add is_active column if it doesn't exist (for existing tables)
DO $$ 
BEGIN 
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'study_sessions' 
        AND column_name = 'is_active'
    ) THEN
        ALTER TABLE public.study_sessions ADD COLUMN is_active BOOLEAN DEFAULT true;
    END IF;
END $$;

-- Friendships table
CREATE TABLE IF NOT EXISTS public.friendships (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    friend_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    status TEXT DEFAULT 'accepted',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    accepted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, friend_id)
);

-- User study stats table  
CREATE TABLE IF NOT EXISTS public.user_study_stats (
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    total_study_time INTERVAL DEFAULT '0 seconds',
    weekly_study_time INTERVAL DEFAULT '0 seconds',
    daily_study_time INTERVAL DEFAULT '0 seconds',
    longest_streak INTEGER DEFAULT 0,
    current_streak INTEGER DEFAULT 0,
    is_currently_studying BOOLEAN DEFAULT false,
    last_active_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Function to generate study code
CREATE OR REPLACE FUNCTION generate_study_code()
RETURNS TEXT AS $$
DECLARE
    chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- Excluding confusing characters
    result TEXT := '';
    i INTEGER;
BEGIN
    FOR i IN 1..6 LOOP
        result := result || substr(chars, floor(random() * length(chars) + 1)::integer, 1);
    END LOOP;
    
    -- Ensure uniqueness
    WHILE EXISTS (SELECT 1 FROM profiles WHERE study_code = result) LOOP
        result := '';
        FOR i IN 1..6 LOOP
            result := result || substr(chars, floor(random() * length(chars) + 1)::integer, 1);
        END LOOP;
    END LOOP;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to create mutual friendship
CREATE OR REPLACE FUNCTION create_mutual_friendship(
    requesting_user_id UUID,
    target_study_code TEXT
)
RETURNS JSON AS $$
DECLARE
    target_user_id UUID;
    result JSON;
BEGIN
    -- Find target user by study code
    SELECT id INTO target_user_id 
    FROM profiles 
    WHERE study_code = UPPER(target_study_code);
    
    -- Check if target user exists
    IF target_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Invalid study code'
        );
    END IF;
    
    -- Check if trying to add self
    IF target_user_id = requesting_user_id THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Cannot add yourself as friend'
        );
    END IF;
    
    -- Check if friendship already exists
    IF EXISTS (
        SELECT 1 FROM friendships 
        WHERE (user_id = requesting_user_id AND friend_id = target_user_id)
           OR (user_id = target_user_id AND friend_id = requesting_user_id)
    ) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Friendship already exists'
        );
    END IF;
    
    -- Create mutual friendship
    INSERT INTO friendships (user_id, friend_id, status, accepted_at)
    VALUES 
        (requesting_user_id, target_user_id, 'accepted', NOW()),
        (target_user_id, requesting_user_id, 'accepted', NOW());
    
    RETURN json_build_object(
        'success', true,
        'friend_id', target_user_id,
        'message', 'Friend added successfully'
    );
END;
$$ LANGUAGE plpgsql;

-- Create user_friends view for easy friend listing
CREATE OR REPLACE VIEW user_friends AS
SELECT 
    f.user_id,
    f.friend_id,
    p.study_code as friend_study_code,
    p.nickname as friend_nickname,
    p.full_name as friend_full_name,
    f.created_at,
    f.accepted_at
FROM friendships f
JOIN profiles p ON f.friend_id = p.id
WHERE f.status = 'accepted';

-- Create friends_study_ranking view
CREATE OR REPLACE VIEW friends_study_ranking AS
SELECT 
    uf.user_id,
    uf.friend_id,
    COALESCE(p.nickname, p.full_name, 'Anonymous') as display_name,
    p.study_code,
    COALESCE(EXTRACT(EPOCH FROM uss.total_study_time), 0) as total_study_time,
    COALESCE(EXTRACT(EPOCH FROM uss.weekly_study_time), 0) as weekly_study_time,
    COALESCE(EXTRACT(EPOCH FROM uss.daily_study_time), 0) as daily_study_time,
    COALESCE(uss.is_currently_studying, false) as is_currently_studying,
    uss.last_active_at,
    ROW_NUMBER() OVER (PARTITION BY uf.user_id ORDER BY uss.weekly_study_time DESC NULLS LAST) as rank
FROM user_friends uf
JOIN profiles p ON uf.friend_id = p.id
LEFT JOIN user_study_stats uss ON uf.friend_id = uss.user_id;

-- Function to handle new user signup (improved with error handling)
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- プロフィール作成（エラーハンドリング付き）
    BEGIN
        INSERT INTO public.profiles (id, study_code, created_at, updated_at)
        VALUES (NEW.id, generate_study_code(), NOW(), NOW());
    EXCEPTION WHEN OTHERS THEN
        -- プロフィール作成エラーをログに記録
        RAISE NOTICE 'Profile creation failed for user %: %', NEW.id, SQLERRM;
    END;
    
    -- 学習統計作成（エラーハンドリング付き）
    BEGIN
        INSERT INTO public.user_study_stats (
            user_id, 
            total_study_time, 
            weekly_study_time, 
            daily_study_time,
            longest_streak,
            current_streak,
            is_currently_studying,
            updated_at
        )
        VALUES (
            NEW.id, 
            '0 seconds'::INTERVAL, 
            '0 seconds'::INTERVAL, 
            '0 seconds'::INTERVAL,
            0,
            0,
            false,
            NOW()
        );
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Stats creation failed for user %: %', NEW.id, SQLERRM;
    END;
    
    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    -- 全体的なエラーハンドリング - ユーザー作成は継続
    RAISE NOTICE 'handle_new_user failed for user %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user creation
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Row Level Security (RLS)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_study_stats ENABLE ROW LEVEL SECURITY;

-- RLS Policies for profiles (drop existing first)
DROP POLICY IF EXISTS "Users can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
CREATE POLICY "Users can view all profiles" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- RLS Policies for study_sessions
DROP POLICY IF EXISTS "Users can manage own sessions" ON study_sessions;
CREATE POLICY "Users can manage own sessions" ON study_sessions FOR ALL USING (auth.uid() = user_id);

-- RLS Policies for friendships
DROP POLICY IF EXISTS "Users can view own friendships" ON friendships;
DROP POLICY IF EXISTS "Users can manage own friendships" ON friendships;
CREATE POLICY "Users can view own friendships" ON friendships FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own friendships" ON friendships FOR ALL USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- RLS Policies for user_study_stats
DROP POLICY IF EXISTS "Users can view friend stats" ON user_study_stats;
DROP POLICY IF EXISTS "Users can update own stats" ON user_study_stats;
DROP POLICY IF EXISTS "Users can insert own stats" ON user_study_stats;
CREATE POLICY "Users can view friend stats" ON user_study_stats FOR SELECT USING (
    auth.uid() = user_id OR 
    EXISTS (
        SELECT 1 FROM friendships 
        WHERE (user_id = auth.uid() AND friend_id = user_study_stats.user_id)
           OR (friend_id = auth.uid() AND user_id = user_study_stats.user_id)
    )
);
CREATE POLICY "Users can update own stats" ON user_study_stats FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own stats" ON user_study_stats FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Email settings: Disable email confirmation for development
-- Execute this in the Supabase Dashboard under Authentication > Settings
-- Set "Enable email confirmations" to OFF
-- This allows immediate sign-in after signup

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_profiles_study_code ON profiles(study_code);
CREATE INDEX IF NOT EXISTS idx_friendships_user_id ON friendships(user_id);
CREATE INDEX IF NOT EXISTS idx_friendships_friend_id ON friendships(friend_id);
CREATE INDEX IF NOT EXISTS idx_study_sessions_user_id ON study_sessions(user_id);

-- Create index for is_active column if it exists
DO $$ 
BEGIN 
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'study_sessions' 
        AND column_name = 'is_active'
    ) THEN
        CREATE INDEX IF NOT EXISTS idx_study_sessions_active ON study_sessions(user_id, is_active) WHERE is_active = true;
    END IF;
END $$;