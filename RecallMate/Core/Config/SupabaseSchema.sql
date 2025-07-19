-- Supabase Database Schema for RecallMate
-- Execute these SQL commands in your Supabase SQL Editor

-- Enable Row Level Security (RLS)
-- This ensures users can only access their own data

-- 1. Users table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users NOT NULL PRIMARY KEY,
    username TEXT UNIQUE,
    full_name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view and edit their own profile
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- 2. Study sessions table
CREATE TABLE IF NOT EXISTS public.study_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users NOT NULL,
    title TEXT NOT NULL,
    content TEXT,
    study_type TEXT NOT NULL, -- 'reading', 'exercise', 'lecture', etc.
    duration_seconds INTEGER NOT NULL DEFAULT 0,
    understanding_score INTEGER CHECK (understanding_score >= 0 AND understanding_score <= 100),
    tags TEXT[], -- Array of tag names
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.study_sessions ENABLE ROW LEVEL SECURITY;

-- Policy: Users can manage their own study sessions
CREATE POLICY "Users can view own study sessions" ON public.study_sessions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own study sessions" ON public.study_sessions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own study sessions" ON public.study_sessions
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own study sessions" ON public.study_sessions
    FOR DELETE USING (auth.uid() = user_id);

-- 3. Review records table
CREATE TABLE IF NOT EXISTS public.review_records (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users NOT NULL,
    study_session_id UUID REFERENCES public.study_sessions,
    recall_score INTEGER CHECK (recall_score >= 0 AND recall_score <= 100),
    review_method TEXT, -- 'active_recall', 'spaced_repetition', etc.
    next_review_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.review_records ENABLE ROW LEVEL SECURITY;

-- Policy: Users can manage their own review records
CREATE POLICY "Users can view own review records" ON public.review_records
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own review records" ON public.review_records
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 4. Study goals table
CREATE TABLE IF NOT EXISTS public.study_goals (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users NOT NULL,
    title TEXT NOT NULL,
    target_minutes INTEGER NOT NULL,
    period TEXT NOT NULL, -- 'daily', 'weekly', 'monthly'
    current_progress INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.study_goals ENABLE ROW LEVEL SECURITY;

-- Policy: Users can manage their own study goals
CREATE POLICY "Users can view own study goals" ON public.study_goals
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own study goals" ON public.study_goals
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own study goals" ON public.study_goals
    FOR UPDATE USING (auth.uid() = user_id);

-- 5. Shared learning groups (for collaborative features)
CREATE TABLE IF NOT EXISTS public.learning_groups (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    creator_id UUID REFERENCES auth.users NOT NULL,
    is_public BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.learning_groups ENABLE ROW LEVEL SECURITY;

-- 6. Group memberships
CREATE TABLE IF NOT EXISTS public.group_memberships (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    group_id UUID REFERENCES public.learning_groups NOT NULL,
    user_id UUID REFERENCES auth.users NOT NULL,
    role TEXT DEFAULT 'member', -- 'admin', 'member'
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(group_id, user_id)
);

-- Enable RLS
ALTER TABLE public.group_memberships ENABLE ROW LEVEL SECURITY;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_study_sessions_user_id ON public.study_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_study_sessions_created_at ON public.study_sessions(created_at);
CREATE INDEX IF NOT EXISTS idx_review_records_user_id ON public.review_records(user_id);
CREATE INDEX IF NOT EXISTS idx_review_records_next_review ON public.review_records(next_review_date);

-- Functions for automatic timestamp updates
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for automatic timestamp updates
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_study_sessions_updated_at BEFORE UPDATE ON public.study_sessions
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_study_goals_updated_at BEFORE UPDATE ON public.study_goals
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();