-- RecallMate フレンド・グループ機能 データベーススキーマ v3
-- 実行順序: この順番で実行してください

-- 1. 基本テーブル (既存のものを拡張)

-- profiles テーブルの拡張
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_studying BOOLEAN DEFAULT FALSE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS study_start_time TIMESTAMPTZ;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS total_study_minutes INTEGER DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS level_points INTEGER DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS current_level INTEGER DEFAULT 1;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS status_message TEXT;

-- 2. 学習グループ機能テーブル

-- 学習グループテーブル
CREATE TABLE IF NOT EXISTS study_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    group_code VARCHAR(8) UNIQUE NOT NULL,
    owner_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    max_members INTEGER DEFAULT 10,
    current_members INTEGER DEFAULT 1,
    is_public BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- グループメンバーテーブル
CREATE TABLE IF NOT EXISTS group_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID REFERENCES study_groups(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    role VARCHAR(20) DEFAULT 'member', -- 'owner', 'admin', 'member'
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(group_id, user_id)
);

-- グループ対戦テーブル
CREATE TABLE IF NOT EXISTS group_competitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    group_id UUID REFERENCES study_groups(id) ON DELETE CASCADE,
    competition_type VARCHAR(20) DEFAULT 'study_time', -- 'study_time', 'memo_count', 'streak'
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 対戦参加者テーブル
CREATE TABLE IF NOT EXISTS competition_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    competition_id UUID REFERENCES group_competitions(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    study_minutes INTEGER DEFAULT 0,
    memo_count INTEGER DEFAULT 0,
    streak_days INTEGER DEFAULT 0,
    last_updated TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(competition_id, user_id)
);

-- 3. フレンド機能の拡張

-- フレンドリクエストテーブル
CREATE TABLE IF NOT EXISTS friend_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    to_user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'accepted', 'rejected'
    message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(from_user_id, to_user_id)
);

-- 4. 学習セッション管理の拡張

-- リアルタイム学習状態テーブル
CREATE TABLE IF NOT EXISTS user_study_status (
    user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    is_studying BOOLEAN DEFAULT FALSE,
    study_start_time TIMESTAMPTZ,
    current_session_minutes INTEGER DEFAULT 0,
    study_subject VARCHAR(100),
    last_heartbeat TIMESTAMPTZ DEFAULT NOW()
);

-- 学習統計の日別記録
CREATE TABLE IF NOT EXISTS daily_study_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    study_date DATE NOT NULL,
    total_minutes INTEGER DEFAULT 0,
    memo_reviews INTEGER DEFAULT 0,
    memo_created INTEGER DEFAULT 0,
    streak_maintained BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, study_date)
);

-- 5. インデックスの作成
CREATE INDEX IF NOT EXISTS idx_group_members_group_id ON group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user_id ON group_members(user_id);
CREATE INDEX IF NOT EXISTS idx_friend_requests_from_user ON friend_requests(from_user_id);
CREATE INDEX IF NOT EXISTS idx_friend_requests_to_user ON friend_requests(to_user_id);
CREATE INDEX IF NOT EXISTS idx_competition_participants_competition ON competition_participants(competition_id);
CREATE INDEX IF NOT EXISTS idx_daily_study_records_user_date ON daily_study_records(user_id, study_date);
CREATE INDEX IF NOT EXISTS idx_user_study_status_studying ON user_study_status(is_studying);

-- 6. ビュー作成

-- フレンド一覧ビュー（双方向フレンド関係）
CREATE OR REPLACE VIEW user_friends_enhanced AS
SELECT DISTINCT
    f1.user_id,
    f1.friend_id,
    p.nickname AS friend_nickname,
    p.full_name AS friend_full_name,
    p.study_code AS friend_study_code,
    p.level_points AS friend_level_points,
    p.current_level AS friend_level,
    uss.is_studying AS friend_is_studying,
    uss.study_start_time AS friend_study_start_time,
    uss.current_session_minutes AS friend_session_minutes,
    uss.study_subject AS friend_study_subject,
    f1.created_at
FROM friendships f1
JOIN profiles p ON f1.friend_id = p.id
LEFT JOIN user_study_status uss ON p.id = uss.user_id
WHERE f1.status = 'accepted'
AND EXISTS (
    SELECT 1 FROM friendships f2 
    WHERE f2.user_id = f1.friend_id 
    AND f2.friend_id = f1.user_id 
    AND f2.status = 'accepted'
);

-- グループメンバー詳細ビュー
CREATE OR REPLACE VIEW group_members_detailed AS
SELECT 
    gm.group_id,
    gm.user_id,
    gm.role,
    gm.joined_at,
    p.nickname,
    p.full_name,
    p.study_code,
    p.level_points,
    p.current_level,
    uss.is_studying,
    uss.study_start_time,
    uss.current_session_minutes,
    uss.study_subject
FROM group_members gm
JOIN profiles p ON gm.user_id = p.id
LEFT JOIN user_study_status uss ON p.id = uss.user_id;

-- 対戦ランキングビュー
CREATE OR REPLACE VIEW competition_rankings AS
SELECT 
    cp.competition_id,
    cp.user_id,
    p.nickname,
    p.full_name,
    cp.study_minutes,
    cp.memo_count,
    cp.streak_days,
    cp.last_updated,
    RANK() OVER (
        PARTITION BY cp.competition_id 
        ORDER BY 
            CASE gc.competition_type
                WHEN 'study_time' THEN cp.study_minutes
                WHEN 'memo_count' THEN cp.memo_count
                WHEN 'streak' THEN cp.streak_days
                ELSE cp.study_minutes
            END DESC
    ) as rank
FROM competition_participants cp
JOIN profiles p ON cp.user_id = p.id
JOIN group_competitions gc ON cp.competition_id = gc.id
WHERE gc.is_active = TRUE;

-- 7. 関数作成

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

-- フレンド追加関数
CREATE OR REPLACE FUNCTION add_friend_by_code(
    requesting_user_id UUID,
    target_study_code TEXT
) RETURNS JSON AS $$
DECLARE
    target_user_id UUID;
    existing_friendship INTEGER;
    result JSON;
BEGIN
    -- 学習コードからユーザーを検索
    SELECT id INTO target_user_id
    FROM profiles
    WHERE study_code = UPPER(target_study_code);
    
    IF target_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', '学習コードが見つかりません');
    END IF;
    
    IF target_user_id = requesting_user_id THEN
        RETURN json_build_object('success', false, 'error', '自分自身をフレンドに追加することはできません');
    END IF;
    
    -- 既存のフレンド関係をチェック
    SELECT COUNT(*) INTO existing_friendship
    FROM friendships
    WHERE (user_id = requesting_user_id AND friend_id = target_user_id)
    OR (user_id = target_user_id AND friend_id = requesting_user_id);
    
    IF existing_friendship > 0 THEN
        RETURN json_build_object('success', false, 'error', '既にフレンド関係にあります');
    END IF;
    
    -- フレンド関係を作成（双方向）
    INSERT INTO friendships (user_id, friend_id, status)
    VALUES 
        (requesting_user_id, target_user_id, 'accepted'),
        (target_user_id, requesting_user_id, 'accepted');
    
    RETURN json_build_object(
        'success', true, 
        'friend_id', target_user_id,
        'message', 'フレンドを追加しました'
    );
END;
$$ LANGUAGE plpgsql;

-- 学習状態更新関数
CREATE OR REPLACE FUNCTION update_study_status(
    p_user_id UUID,
    p_is_studying BOOLEAN,
    p_study_subject TEXT DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
    INSERT INTO user_study_status (
        user_id, 
        is_studying, 
        study_start_time, 
        current_session_minutes,
        study_subject,
        last_heartbeat
    )
    VALUES (
        p_user_id, 
        p_is_studying,
        CASE WHEN p_is_studying THEN NOW() ELSE NULL END,
        0,
        p_study_subject,
        NOW()
    )
    ON CONFLICT (user_id) DO UPDATE SET
        is_studying = p_is_studying,
        study_start_time = CASE 
            WHEN p_is_studying AND NOT user_study_status.is_studying THEN NOW()
            WHEN NOT p_is_studying THEN NULL
            ELSE user_study_status.study_start_time
        END,
        current_session_minutes = CASE
            WHEN NOT p_is_studying THEN 0
            WHEN p_is_studying AND user_study_status.study_start_time IS NOT NULL THEN
                EXTRACT(EPOCH FROM (NOW() - user_study_status.study_start_time)) / 60
            ELSE user_study_status.current_session_minutes
        END,
        study_subject = COALESCE(p_study_subject, user_study_status.study_subject),
        last_heartbeat = NOW();
        
    -- プロフィールの学習状態も更新
    UPDATE profiles SET
        is_studying = p_is_studying,
        study_start_time = CASE 
            WHEN p_is_studying THEN NOW() 
            ELSE NULL 
        END
    WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- 学習グループ作成関数
CREATE OR REPLACE FUNCTION create_study_group(
    p_owner_id UUID,
    p_name TEXT,
    p_description TEXT DEFAULT NULL,
    p_max_members INTEGER DEFAULT 10
) RETURNS JSON AS $$
DECLARE
    new_group_id UUID;
    new_group_code TEXT;
    result JSON;
BEGIN
    -- グループコード生成
    new_group_code := generate_group_code();
    
    -- グループ作成
    INSERT INTO study_groups (name, description, group_code, owner_id, max_members)
    VALUES (p_name, p_description, new_group_code, p_owner_id, p_max_members)
    RETURNING id INTO new_group_id;
    
    -- オーナーをメンバーとして追加
    INSERT INTO group_members (group_id, user_id, role)
    VALUES (new_group_id, p_owner_id, 'owner');
    
    RETURN json_build_object(
        'success', true,
        'group_id', new_group_id,
        'group_code', new_group_code,
        'message', 'グループを作成しました'
    );
END;
$$ LANGUAGE plpgsql;

-- 8. RLS (Row Level Security) 設定
ALTER TABLE study_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_competitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE competition_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE friend_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_study_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_study_records ENABLE ROW LEVEL SECURITY;

-- 基本的なRLSポリシー
CREATE POLICY "Users can view public groups" ON study_groups FOR SELECT USING (is_public = true);
CREATE POLICY "Users can view their group memberships" ON group_members FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can view their friend requests" ON friend_requests FOR SELECT USING (auth.uid() = from_user_id OR auth.uid() = to_user_id);
CREATE POLICY "Users can view their study status" ON user_study_status FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can view their study records" ON daily_study_records FOR ALL USING (auth.uid() = user_id);

-- 9. トリガー作成

-- updated_at自動更新トリガー
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_study_groups_updated_at
    BEFORE UPDATE ON study_groups
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_friend_requests_updated_at
    BEFORE UPDATE ON friend_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 10. 初期データ
-- テスト用のサンプルデータ（必要に応じて）

-- 完了メッセージ
DO $$
BEGIN
    RAISE NOTICE '====================================';
    RAISE NOTICE 'RecallMate v3 データベースセットアップ完了';
    RAISE NOTICE '====================================';
    RAISE NOTICE '追加されたテーブル:';
    RAISE NOTICE '- study_groups (学習グループ)';
    RAISE NOTICE '- group_members (グループメンバー)';
    RAISE NOTICE '- group_competitions (グループ対戦)';
    RAISE NOTICE '- competition_participants (対戦参加者)';
    RAISE NOTICE '- friend_requests (フレンドリクエスト)';
    RAISE NOTICE '- user_study_status (リアルタイム学習状態)';
    RAISE NOTICE '- daily_study_records (日別学習記録)';
    RAISE NOTICE '';
    RAISE NOTICE '追加されたビュー:';
    RAISE NOTICE '- user_friends_enhanced (拡張フレンド一覧)';
    RAISE NOTICE '- group_members_detailed (グループメンバー詳細)';
    RAISE NOTICE '- competition_rankings (対戦ランキング)';
    RAISE NOTICE '';
    RAISE NOTICE '追加された関数:';
    RAISE NOTICE '- generate_group_code() (グループコード生成)';
    RAISE NOTICE '- add_friend_by_code() (フレンド追加)';
    RAISE NOTICE '- update_study_status() (学習状態更新)';
    RAISE NOTICE '- create_study_group() (グループ作成)';
    RAISE NOTICE '====================================';
END $$;