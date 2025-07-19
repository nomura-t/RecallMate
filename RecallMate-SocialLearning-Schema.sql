-- ========================================
-- RecallMate ソーシャル学習プラットフォーム
-- 包括的データベーススキーマ v1.0
-- ========================================

-- 実行順序: この順番で実行してください
-- 1. 基本テーブル
-- 2. 関連テーブル
-- 3. インデックス
-- 4. ビュー
-- 5. 関数
-- 6. RLSポリシー
-- 7. Realtime設定

-- ========================================
-- 1. 基本テーブル
-- ========================================

-- 拡張プロフィールテーブル
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username VARCHAR(50) UNIQUE,
    full_name VARCHAR(100),
    nickname VARCHAR(50),
    bio TEXT,
    avatar_url TEXT,
    study_code VARCHAR(8) UNIQUE,
    
    -- 学習統計
    total_study_minutes INTEGER DEFAULT 0,
    total_memo_count INTEGER DEFAULT 0,
    level_points INTEGER DEFAULT 0,
    current_level INTEGER DEFAULT 1,
    longest_streak INTEGER DEFAULT 0,
    current_streak INTEGER DEFAULT 0,
    
    -- 状態管理
    is_studying BOOLEAN DEFAULT FALSE,
    study_start_time TIMESTAMPTZ,
    study_subject VARCHAR(100),
    status_message TEXT,
    
    -- 設定
    is_public BOOLEAN DEFAULT TRUE,
    allow_friend_requests BOOLEAN DEFAULT TRUE,
    allow_group_invites BOOLEAN DEFAULT TRUE,
    email_notifications BOOLEAN DEFAULT TRUE,
    
    -- システム
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_active_at TIMESTAMPTZ DEFAULT NOW()
);

-- フォローリレーション
CREATE TABLE IF NOT EXISTS follows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    follower_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    following_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(follower_id, following_id),
    CHECK (follower_id != following_id)
);

-- 学習セッション
CREATE TABLE IF NOT EXISTS study_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    subject VARCHAR(100),
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    duration_minutes INTEGER,
    memo_count INTEGER DEFAULT 0,
    review_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT,
    tags TEXT[], -- 学習タグ
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 学習グループ
CREATE TABLE IF NOT EXISTS study_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    group_code VARCHAR(8) UNIQUE NOT NULL,
    cover_image_url TEXT,
    
    -- 管理
    owner_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    max_members INTEGER DEFAULT 50,
    current_members INTEGER DEFAULT 1,
    
    -- 設定
    is_public BOOLEAN DEFAULT TRUE,
    allow_join_requests BOOLEAN DEFAULT TRUE,
    require_approval BOOLEAN DEFAULT FALSE,
    
    -- 学習設定
    study_goals TEXT[],
    study_schedule JSONB, -- 学習スケジュール
    
    -- システム
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- グループメンバー
CREATE TABLE IF NOT EXISTS group_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID REFERENCES study_groups(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    role VARCHAR(20) DEFAULT 'member', -- owner, admin, moderator, member
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    contribution_score INTEGER DEFAULT 0,
    UNIQUE(group_id, user_id)
);

-- グループ招待・参加申請
CREATE TABLE IF NOT EXISTS group_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID REFERENCES study_groups(id) ON DELETE CASCADE,
    inviter_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    invitee_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    type VARCHAR(20) DEFAULT 'invitation', -- invitation, request
    status VARCHAR(20) DEFAULT 'pending', -- pending, accepted, rejected, expired
    message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 days')
);

-- ========================================
-- 2. 掲示板・チャット機能
-- ========================================

-- 掲示板カテゴリー
CREATE TABLE IF NOT EXISTS board_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    icon VARCHAR(50),
    color VARCHAR(7), -- HEX色
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 掲示板投稿
CREATE TABLE IF NOT EXISTS board_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID REFERENCES board_categories(id) ON DELETE CASCADE,
    author_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    
    -- 投稿内容
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    images TEXT[], -- 画像URL配列
    tags TEXT[],
    
    -- 統計
    view_count INTEGER DEFAULT 0,
    like_count INTEGER DEFAULT 0,
    reply_count INTEGER DEFAULT 0,
    
    -- 設定
    is_pinned BOOLEAN DEFAULT FALSE,
    is_locked BOOLEAN DEFAULT FALSE,
    is_anonymous BOOLEAN DEFAULT FALSE,
    
    -- システム
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 掲示板返信
CREATE TABLE IF NOT EXISTS board_replies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID REFERENCES board_posts(id) ON DELETE CASCADE,
    author_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    parent_reply_id UUID REFERENCES board_replies(id) ON DELETE CASCADE, -- ネストした返信
    
    -- 返信内容
    content TEXT NOT NULL,
    images TEXT[],
    
    -- 統計
    like_count INTEGER DEFAULT 0,
    
    -- 設定
    is_anonymous BOOLEAN DEFAULT FALSE,
    
    -- システム
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- グループチャット
CREATE TABLE IF NOT EXISTS group_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID REFERENCES study_groups(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    
    -- メッセージ内容
    content TEXT NOT NULL,
    message_type VARCHAR(20) DEFAULT 'text', -- text, image, file, system
    file_url TEXT,
    file_name VARCHAR(255),
    file_size INTEGER,
    
    -- 返信機能
    reply_to_id UUID REFERENCES group_messages(id) ON DELETE SET NULL,
    
    -- 統計
    read_count INTEGER DEFAULT 0,
    
    -- システム
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- チャット既読状態
CREATE TABLE IF NOT EXISTS message_reads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID REFERENCES group_messages(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    read_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(message_id, user_id)
);

-- ========================================
-- 3. 学習競争・ランキング機能
-- ========================================

-- 学習チャレンジ
CREATE TABLE IF NOT EXISTS study_challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(100) NOT NULL,
    description TEXT,
    challenge_type VARCHAR(20) DEFAULT 'individual', -- individual, group, global
    
    -- チャレンジ条件
    target_type VARCHAR(20) NOT NULL, -- study_time, memo_count, streak, custom
    target_value INTEGER NOT NULL,
    target_unit VARCHAR(20) DEFAULT 'minutes', -- minutes, count, days
    
    -- 期間
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    
    -- 報酬
    reward_points INTEGER DEFAULT 0,
    reward_badge VARCHAR(50),
    
    -- 設定
    is_active BOOLEAN DEFAULT TRUE,
    is_public BOOLEAN DEFAULT TRUE,
    
    -- システム
    created_by UUID REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- チャレンジ参加
CREATE TABLE IF NOT EXISTS challenge_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    challenge_id UUID REFERENCES study_challenges(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    
    -- 進捗
    current_value INTEGER DEFAULT 0,
    is_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMPTZ,
    
    -- 統計
    rank INTEGER,
    
    -- システム
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(challenge_id, user_id)
);

-- 学習記録集計 (日次)
CREATE TABLE IF NOT EXISTS daily_study_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    study_date DATE NOT NULL,
    
    -- 学習統計
    total_minutes INTEGER DEFAULT 0,
    memo_count INTEGER DEFAULT 0,
    review_count INTEGER DEFAULT 0,
    session_count INTEGER DEFAULT 0,
    
    -- 集中度指標
    focus_score FLOAT DEFAULT 0, -- 0-100
    efficiency_score FLOAT DEFAULT 0, -- 0-100
    
    -- 目標達成
    daily_goal_minutes INTEGER DEFAULT 0,
    goal_achieved BOOLEAN DEFAULT FALSE,
    
    -- システム
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, study_date)
);

-- ========================================
-- 4. 通知システム
-- ========================================

-- 通知
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    
    -- 通知内容
    type VARCHAR(50) NOT NULL, -- follow, group_invite, message, challenge, etc.
    title VARCHAR(200) NOT NULL,
    content TEXT,
    
    -- 関連エンティティ
    related_id UUID, -- 関連するエンティティのID
    related_type VARCHAR(50), -- profiles, groups, posts, etc.
    
    -- 送信者
    sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    
    -- 状態
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    
    -- システム
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ========================================
-- 5. インデックス作成
-- ========================================

-- プロフィール関連
CREATE INDEX IF NOT EXISTS idx_profiles_username ON profiles(username);
CREATE INDEX IF NOT EXISTS idx_profiles_study_code ON profiles(study_code);
CREATE INDEX IF NOT EXISTS idx_profiles_is_public ON profiles(is_public);
CREATE INDEX IF NOT EXISTS idx_profiles_last_active ON profiles(last_active_at);

-- フォロー関連
CREATE INDEX IF NOT EXISTS idx_follows_follower ON follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following ON follows(following_id);
CREATE INDEX IF NOT EXISTS idx_follows_created_at ON follows(created_at);

-- 学習セッション関連
CREATE INDEX IF NOT EXISTS idx_study_sessions_user_id ON study_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_study_sessions_start_time ON study_sessions(start_time);
CREATE INDEX IF NOT EXISTS idx_study_sessions_is_active ON study_sessions(is_active);

-- グループ関連
CREATE INDEX IF NOT EXISTS idx_study_groups_owner_id ON study_groups(owner_id);
CREATE INDEX IF NOT EXISTS idx_study_groups_is_public ON study_groups(is_public);
CREATE INDEX IF NOT EXISTS idx_study_groups_group_code ON study_groups(group_code);

CREATE INDEX IF NOT EXISTS idx_group_members_group_id ON group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user_id ON group_members(user_id);

-- 掲示板関連
CREATE INDEX IF NOT EXISTS idx_board_posts_category_id ON board_posts(category_id);
CREATE INDEX IF NOT EXISTS idx_board_posts_author_id ON board_posts(author_id);
CREATE INDEX IF NOT EXISTS idx_board_posts_created_at ON board_posts(created_at);

CREATE INDEX IF NOT EXISTS idx_board_replies_post_id ON board_replies(post_id);
CREATE INDEX IF NOT EXISTS idx_board_replies_author_id ON board_replies(author_id);

-- チャット関連
CREATE INDEX IF NOT EXISTS idx_group_messages_group_id ON group_messages(group_id);
CREATE INDEX IF NOT EXISTS idx_group_messages_sender_id ON group_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_group_messages_created_at ON group_messages(created_at);

-- 学習記録関連
CREATE INDEX IF NOT EXISTS idx_daily_study_records_user_date ON daily_study_records(user_id, study_date);
CREATE INDEX IF NOT EXISTS idx_daily_study_records_study_date ON daily_study_records(study_date);

-- 通知関連
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);

-- ========================================
-- 6. ビュー作成
-- ========================================

-- フォロー統計ビュー
CREATE OR REPLACE VIEW follow_stats AS
SELECT 
    p.id,
    p.username,
    p.full_name,
    COALESCE(followers.count, 0) as follower_count,
    COALESCE(following.count, 0) as following_count
FROM profiles p
LEFT JOIN (
    SELECT following_id, COUNT(*) as count
    FROM follows
    GROUP BY following_id
) followers ON p.id = followers.following_id
LEFT JOIN (
    SELECT follower_id, COUNT(*) as count
    FROM follows
    GROUP BY follower_id
) following ON p.id = following.follower_id;

-- 学習ランキングビュー（週間）
CREATE OR REPLACE VIEW weekly_study_ranking AS
SELECT 
    p.id,
    p.username,
    p.full_name,
    p.nickname,
    p.avatar_url,
    p.current_level,
    COALESCE(SUM(dsr.total_minutes), 0) as weekly_minutes,
    COALESCE(SUM(dsr.memo_count), 0) as weekly_memos,
    COALESCE(AVG(dsr.focus_score), 0) as avg_focus_score,
    ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(dsr.total_minutes), 0) DESC) as rank
FROM profiles p
LEFT JOIN daily_study_records dsr ON p.id = dsr.user_id 
    AND dsr.study_date >= (CURRENT_DATE - INTERVAL '7 days')
WHERE p.is_public = TRUE
GROUP BY p.id, p.username, p.full_name, p.nickname, p.avatar_url, p.current_level
ORDER BY weekly_minutes DESC;

-- グループ統計ビュー
CREATE OR REPLACE VIEW group_stats AS
SELECT 
    sg.id,
    sg.name,
    sg.description,
    sg.current_members,
    sg.max_members,
    sg.is_public,
    sg.owner_id,
    owner.username as owner_username,
    owner.full_name as owner_name,
    COALESCE(AVG(dsr.total_minutes), 0) as avg_daily_minutes,
    COALESCE(SUM(dsr.total_minutes), 0) as total_group_minutes,
    sg.created_at
FROM study_groups sg
LEFT JOIN profiles owner ON sg.owner_id = owner.id
LEFT JOIN group_members gm ON sg.id = gm.group_id
LEFT JOIN daily_study_records dsr ON gm.user_id = dsr.user_id 
    AND dsr.study_date >= (CURRENT_DATE - INTERVAL '7 days')
GROUP BY sg.id, sg.name, sg.description, sg.current_members, sg.max_members, 
         sg.is_public, sg.owner_id, owner.username, owner.full_name, sg.created_at;

-- ========================================
-- 7. 関数作成
-- ========================================

-- 学習コード生成関数
CREATE OR REPLACE FUNCTION generate_study_code()
RETURNS TEXT AS $$
DECLARE
    new_code TEXT;
    exists_check INTEGER;
BEGIN
    LOOP
        new_code := UPPER(
            CHR(65 + (RANDOM() * 25)::INTEGER) ||
            CHR(65 + (RANDOM() * 25)::INTEGER) ||
            (RANDOM() * 9)::INTEGER::TEXT ||
            (RANDOM() * 9)::INTEGER::TEXT ||
            CHR(65 + (RANDOM() * 25)::INTEGER) ||
            (RANDOM() * 9)::INTEGER::TEXT ||
            CHR(65 + (RANDOM() * 25)::INTEGER) ||
            (RANDOM() * 9)::INTEGER::TEXT
        );
        
        SELECT COUNT(*) INTO exists_check
        FROM profiles
        WHERE study_code = new_code;
        
        IF exists_check = 0 THEN
            EXIT;
        END IF;
    END LOOP;
    
    RETURN new_code;
END;
$$ LANGUAGE plpgsql;

-- グループコード生成関数
CREATE OR REPLACE FUNCTION generate_group_code()
RETURNS TEXT AS $$
DECLARE
    new_code TEXT;
    exists_check INTEGER;
BEGIN
    LOOP
        new_code := UPPER(
            CHR(65 + (RANDOM() * 25)::INTEGER) ||
            CHR(65 + (RANDOM() * 25)::INTEGER) ||
            (RANDOM() * 9)::INTEGER::TEXT ||
            (RANDOM() * 9)::INTEGER::TEXT ||
            CHR(65 + (RANDOM() * 25)::INTEGER) ||
            (RANDOM() * 9)::INTEGER::TEXT ||
            CHR(65 + (RANDOM() * 25)::INTEGER) ||
            (RANDOM() * 9)::INTEGER::TEXT
        );
        
        SELECT COUNT(*) INTO exists_check
        FROM study_groups
        WHERE group_code = new_code;
        
        IF exists_check = 0 THEN
            EXIT;
        END IF;
    END LOOP;
    
    RETURN new_code;
END;
$$ LANGUAGE plpgsql;

-- プロフィール作成関数
CREATE OR REPLACE FUNCTION create_profile_on_signup()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO profiles (id, username, full_name, study_code, created_at)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substr(NEW.id::text, 1, 8)),
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'New User'),
        generate_study_code(),
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- フォロー関数
CREATE OR REPLACE FUNCTION follow_user(
    p_follower_id UUID,
    p_following_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
    existing_follow INTEGER;
BEGIN
    -- 自分自身をフォローしようとしている場合
    IF p_follower_id = p_following_id THEN
        RETURN FALSE;
    END IF;
    
    -- 既存のフォロー関係をチェック
    SELECT COUNT(*) INTO existing_follow
    FROM follows
    WHERE follower_id = p_follower_id AND following_id = p_following_id;
    
    IF existing_follow > 0 THEN
        RETURN FALSE;
    END IF;
    
    -- フォロー関係を作成
    INSERT INTO follows (follower_id, following_id)
    VALUES (p_follower_id, p_following_id);
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- 学習セッション更新関数
CREATE OR REPLACE FUNCTION update_study_session(
    p_user_id UUID,
    p_subject TEXT DEFAULT NULL,
    p_is_active BOOLEAN DEFAULT TRUE
) RETURNS VOID AS $$
BEGIN
    IF p_is_active THEN
        -- 既存のアクティブセッションを終了
        UPDATE study_sessions 
        SET is_active = FALSE, 
            end_time = NOW(),
            duration_minutes = EXTRACT(EPOCH FROM (NOW() - start_time)) / 60
        WHERE user_id = p_user_id AND is_active = TRUE;
        
        -- 新しいセッションを開始
        INSERT INTO study_sessions (user_id, subject, start_time, is_active)
        VALUES (p_user_id, p_subject, NOW(), TRUE);
        
        -- プロフィールを更新
        UPDATE profiles 
        SET is_studying = TRUE, 
            study_start_time = NOW(),
            study_subject = p_subject,
            last_active_at = NOW()
        WHERE id = p_user_id;
    ELSE
        -- セッションを終了
        UPDATE study_sessions 
        SET is_active = FALSE, 
            end_time = NOW(),
            duration_minutes = EXTRACT(EPOCH FROM (NOW() - start_time)) / 60
        WHERE user_id = p_user_id AND is_active = TRUE;
        
        -- プロフィールを更新
        UPDATE profiles 
        SET is_studying = FALSE, 
            study_start_time = NULL,
            study_subject = NULL,
            last_active_at = NOW()
        WHERE id = p_user_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 日次学習記録更新関数
CREATE OR REPLACE FUNCTION update_daily_study_record(
    p_user_id UUID,
    p_study_date DATE DEFAULT CURRENT_DATE
) RETURNS VOID AS $$
DECLARE
    session_data RECORD;
BEGIN
    -- その日の学習セッションデータを集計
    SELECT 
        COALESCE(SUM(duration_minutes), 0) as total_minutes,
        COUNT(*) as session_count
    INTO session_data
    FROM study_sessions
    WHERE user_id = p_user_id 
    AND start_time::DATE = p_study_date
    AND is_active = FALSE;
    
    -- 日次記録を更新または作成
    INSERT INTO daily_study_records (
        user_id, study_date, total_minutes, session_count
    ) VALUES (
        p_user_id, p_study_date, session_data.total_minutes, session_data.session_count
    ) ON CONFLICT (user_id, study_date) DO UPDATE SET
        total_minutes = EXCLUDED.total_minutes,
        session_count = EXCLUDED.session_count;
        
    -- プロフィールの統計を更新
    UPDATE profiles 
    SET 
        total_study_minutes = (
            SELECT COALESCE(SUM(total_minutes), 0) 
            FROM daily_study_records 
            WHERE user_id = p_user_id
        ),
        last_active_at = NOW()
    WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- 8. トリガー作成
-- ========================================

-- サインアップ時にプロフィールを作成
CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION create_profile_on_signup();

-- updated_at自動更新
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_study_groups_updated_at
    BEFORE UPDATE ON study_groups
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_board_posts_updated_at
    BEFORE UPDATE ON board_posts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ========================================
-- 9. 初期データ挿入
-- ========================================

-- 掲示板カテゴリー
INSERT INTO board_categories (name, description, icon, color, sort_order) VALUES
('一般', '一般的な議論や質問', 'chat', '#3B82F6', 1),
('学習方法', '効果的な学習方法について', 'book', '#10B981', 2),
('質問・相談', '学習に関する質問や相談', 'question', '#F59E0B', 3),
('グループ募集', '学習グループのメンバー募集', 'users', '#8B5CF6', 4),
('成果報告', '学習成果や達成報告', 'trophy', '#EF4444', 5),
('雑談', '気軽な雑談や交流', 'coffee', '#6B7280', 6)
ON CONFLICT DO NOTHING;

-- 完了メッセージ
DO $$
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'RecallMate ソーシャル学習プラットフォーム';
    RAISE NOTICE 'データベーススキーマ作成完了';
    RAISE NOTICE '================================================';
    RAISE NOTICE '作成されたテーブル:';
    RAISE NOTICE '- profiles (拡張プロフィール)';
    RAISE NOTICE '- follows (フォロー関係)';
    RAISE NOTICE '- study_sessions (学習セッション)';
    RAISE NOTICE '- study_groups (学習グループ)';
    RAISE NOTICE '- group_members (グループメンバー)';
    RAISE NOTICE '- group_invitations (グループ招待)';
    RAISE NOTICE '- board_categories (掲示板カテゴリー)';
    RAISE NOTICE '- board_posts (掲示板投稿)';
    RAISE NOTICE '- board_replies (掲示板返信)';
    RAISE NOTICE '- group_messages (グループチャット)';
    RAISE NOTICE '- message_reads (チャット既読)';
    RAISE NOTICE '- study_challenges (学習チャレンジ)';
    RAISE NOTICE '- challenge_participants (チャレンジ参加)';
    RAISE NOTICE '- daily_study_records (日次学習記録)';
    RAISE NOTICE '- notifications (通知)';
    RAISE NOTICE '';
    RAISE NOTICE '次のステップ:';
    RAISE NOTICE '1. RLSポリシーの実装';
    RAISE NOTICE '2. Realtime設定';
    RAISE NOTICE '3. フロントエンドの実装';
    RAISE NOTICE '================================================';
END $$;