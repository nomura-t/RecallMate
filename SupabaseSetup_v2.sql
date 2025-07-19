-- RecallMate Friend System Database Schema v2
-- Execute this in Supabase SQL Editor after complete reset

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Profiles table (extends auth.users)
CREATE TABLE public.profiles (
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
CREATE TABLE public.study_sessions (
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

-- Friendships table
CREATE TABLE public.friendships (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    friend_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    status TEXT DEFAULT 'accepted',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    accepted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, friend_id)
);

-- User study stats table  
CREATE TABLE public.user_study_stats (
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
    chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

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
    SELECT id INTO target_user_id 
    FROM profiles 
    WHERE study_code = UPPER(target_study_code);
    
    IF target_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Invalid study code');
    END IF;
    
    IF target_user_id = requesting_user_id THEN
        RETURN json_build_object('success', false, 'error', 'Cannot add yourself as friend');
    END IF;
    
    IF EXISTS (
        SELECT 1 FROM friendships 
        WHERE (user_id = requesting_user_id AND friend_id = target_user_id)
           OR (user_id = target_user_id AND friend_id = requesting_user_id)
    ) THEN
        RETURN json_build_object('success', false, 'error', 'Friendship already exists');
    END IF;
    
    INSERT INTO friendships (user_id, friend_id, status, accepted_at)
    VALUES 
        (requesting_user_id, target_user_id, 'accepted', NOW()),
        (target_user_id, requesting_user_id, 'accepted', NOW());
    
    RETURN json_build_object('success', true, 'friend_id', target_user_id, 'message', 'Friend added successfully');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create user_friends view
CREATE VIEW user_friends AS
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
CREATE VIEW friends_study_ranking AS
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

-- Row Level Security (RLS) - 最初は無効化
-- ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE study_sessions ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE user_study_stats ENABLE ROW LEVEL SECURITY;

-- Function to handle new user signup (詳細ログ付き)
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    RAISE LOG 'handle_new_user triggered for user: %', NEW.id;
    
    BEGIN
        RAISE LOG 'Creating profile for user: %', NEW.id;
        INSERT INTO public.profiles (id, study_code, nickname, created_at, updated_at)
        VALUES (NEW.id, generate_study_code(), '新規ユーザー', NOW(), NOW());
        RAISE LOG 'Profile created successfully for user: %', NEW.id;
    EXCEPTION WHEN OTHERS THEN
        RAISE LOG 'Profile creation FAILED for user %: % (SQLSTATE: %)', NEW.id, SQLERRM, SQLSTATE;
    END;
    
    BEGIN
        RAISE LOG 'Creating stats for user: %', NEW.id;
        INSERT INTO public.user_study_stats (
            user_id, total_study_time, weekly_study_time, daily_study_time,
            longest_streak, current_streak, is_currently_studying, updated_at
        )
        VALUES (NEW.id, '0 seconds', '0 seconds', '0 seconds', 0, 0, false, NOW());
        RAISE LOG 'Stats created successfully for user: %', NEW.id;
    EXCEPTION WHEN OTHERS THEN
        RAISE LOG 'Stats creation FAILED for user %: % (SQLSTATE: %)', NEW.id, SQLERRM, SQLSTATE;
    END;
    
    RAISE LOG 'handle_new_user completed for user: %', NEW.id;
    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    RAISE LOG 'handle_new_user COMPLETELY FAILED for user %: % (SQLSTATE: %)', NEW.id, SQLERRM, SQLSTATE;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user creation
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Indexes for performance
CREATE INDEX idx_profiles_study_code ON profiles(study_code);
CREATE INDEX idx_friendships_user_id ON friendships(user_id);
CREATE INDEX idx_friendships_friend_id ON friendships(friend_id);
CREATE INDEX idx_study_sessions_user_id ON study_sessions(user_id);
CREATE INDEX idx_study_sessions_active ON study_sessions(user_id, is_active) WHERE is_active = true;

-- Grant permissions
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;