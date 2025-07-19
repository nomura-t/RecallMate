-- Friend System Database Schema for RecallMate
-- Execute these SQL commands in your Supabase SQL Editor

-- 1. Update profiles table to include study_code
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS study_code TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS nickname TEXT;

-- 2. Create friendships table
CREATE TABLE IF NOT EXISTS public.friendships (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users NOT NULL,
    friend_id UUID REFERENCES auth.users NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'accepted', 'blocked'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    accepted_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(user_id, friend_id),
    CHECK (user_id != friend_id) -- Prevent self-friendship
);

-- Enable RLS for friendships table
ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;

-- RLS Policies for friendships
CREATE POLICY "Users can view own friendships" ON public.friendships
    FOR SELECT USING (auth.uid() = user_id OR auth.uid() = friend_id);

CREATE POLICY "Users can create friend requests" ON public.friendships
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update friendships they're involved in" ON public.friendships
    FOR UPDATE USING (auth.uid() = user_id OR auth.uid() = friend_id);

CREATE POLICY "Users can delete own friendships" ON public.friendships
    FOR DELETE USING (auth.uid() = user_id);

-- 3. Function to generate unique study code
CREATE OR REPLACE FUNCTION generate_study_code()
RETURNS TEXT AS $$
DECLARE
    code TEXT;
    exists_check BOOLEAN;
BEGIN
    LOOP
        -- Generate 6-character alphanumeric code (excluding confusing characters)
        code := upper(
            substr(
                translate(
                    encode(gen_random_bytes(4), 'base64'),
                    'IL0O+/=',
                    'ABCDEF23'
                ),
                1, 6
            )
        );
        
        -- Check if code already exists
        SELECT EXISTS(SELECT 1 FROM public.profiles WHERE study_code = code) INTO exists_check;
        
        -- Exit loop if code is unique
        IF NOT exists_check THEN
            EXIT;
        END IF;
    END LOOP;
    
    RETURN code;
END;
$$ LANGUAGE plpgsql;

-- 4. Trigger to auto-generate study_code for new profiles
CREATE OR REPLACE FUNCTION auto_generate_study_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.study_code IS NULL THEN
        NEW.study_code := generate_study_code();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_generate_study_code
    BEFORE INSERT ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION auto_generate_study_code();

-- 5. Function to create mutual friendship
CREATE OR REPLACE FUNCTION create_mutual_friendship(
    requesting_user_id UUID,
    target_study_code TEXT
)
RETURNS JSON AS $$
DECLARE
    target_user_id UUID;
    friendship_exists BOOLEAN;
    result JSON;
BEGIN
    -- Find target user by study code
    SELECT id INTO target_user_id 
    FROM public.profiles 
    WHERE study_code = target_study_code;
    
    IF target_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Study code not found');
    END IF;
    
    -- Check if friendship already exists
    SELECT EXISTS(
        SELECT 1 FROM public.friendships 
        WHERE (user_id = requesting_user_id AND friend_id = target_user_id)
           OR (user_id = target_user_id AND friend_id = requesting_user_id)
    ) INTO friendship_exists;
    
    IF friendship_exists THEN
        RETURN json_build_object('success', false, 'error', 'Friendship already exists');
    END IF;
    
    -- Create mutual friendship (both directions)
    INSERT INTO public.friendships (user_id, friend_id, status, accepted_at)
    VALUES 
        (requesting_user_id, target_user_id, 'accepted', NOW()),
        (target_user_id, requesting_user_id, 'accepted', NOW());
    
    RETURN json_build_object(
        'success', true, 
        'friend_id', target_user_id,
        'message', 'Friend added successfully'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. View for easy friend querying
CREATE OR REPLACE VIEW user_friends AS
SELECT 
    f.user_id,
    f.friend_id,
    p.study_code as friend_study_code,
    p.nickname as friend_nickname,
    p.full_name as friend_full_name,
    f.created_at,
    f.accepted_at
FROM public.friendships f
JOIN public.profiles p ON f.friend_id = p.id
WHERE f.status = 'accepted';

-- Enable RLS for the view
ALTER VIEW user_friends SET (security_invoker = true);

-- 7. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_friendships_user_id ON public.friendships(user_id);
CREATE INDEX IF NOT EXISTS idx_friendships_friend_id ON public.friendships(friend_id);
CREATE INDEX IF NOT EXISTS idx_friendships_status ON public.friendships(status);
CREATE INDEX IF NOT EXISTS idx_profiles_study_code ON public.profiles(study_code);

-- 8. Update existing profiles with study codes (if any exist)
UPDATE public.profiles 
SET study_code = generate_study_code() 
WHERE study_code IS NULL;