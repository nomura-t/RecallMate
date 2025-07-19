-- ========================================
-- RecallMate RLS (Row Level Security) ポリシー
-- セキュリティとプライバシー保護
-- ========================================

-- 実行前提: 基本スキーマが作成済みであること

-- ========================================
-- 1. RLS有効化
-- ========================================

-- 全テーブルでRLSを有効化
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE board_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE board_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE board_replies ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_reads ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenge_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_study_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- ========================================
-- 2. プロフィールポリシー
-- ========================================

-- 自分のプロフィールは全操作可能
CREATE POLICY "Users can manage their own profile"
    ON profiles
    FOR ALL
    USING (auth.uid() = id);

-- 公開プロフィールは誰でも閲覧可能
CREATE POLICY "Public profiles are viewable by everyone"
    ON profiles
    FOR SELECT
    USING (is_public = true);

-- 認証済みユーザーは全プロフィールを閲覧可能（検索機能のため）
CREATE POLICY "Authenticated users can view all profiles"
    ON profiles
    FOR SELECT
    USING (auth.role() = 'authenticated');

-- ========================================
-- 3. フォロー関係ポリシー
-- ========================================

-- 自分のフォロー関係は管理可能
CREATE POLICY "Users can manage their own follows"
    ON follows
    FOR ALL
    USING (auth.uid() = follower_id);

-- フォロー情報は認証済みユーザーが閲覧可能
CREATE POLICY "Authenticated users can view follows"
    ON follows
    FOR SELECT
    USING (auth.role() = 'authenticated');

-- ========================================
-- 4. 学習セッションポリシー
-- ========================================

-- 自分の学習セッションは管理可能
CREATE POLICY "Users can manage their own study sessions"
    ON study_sessions
    FOR ALL
    USING (auth.uid() = user_id);

-- フォロワーは学習セッションを閲覧可能
CREATE POLICY "Followers can view study sessions"
    ON study_sessions
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM follows f
            JOIN profiles p ON f.following_id = p.id
            WHERE f.follower_id = auth.uid()
            AND p.id = user_id
            AND p.is_public = true
        )
    );

-- ========================================
-- 5. 学習グループポリシー
-- ========================================

-- 公開グループは誰でも閲覧可能
CREATE POLICY "Public groups are viewable by everyone"
    ON study_groups
    FOR SELECT
    USING (is_public = true);

-- 自分が所属するグループは閲覧可能
CREATE POLICY "Group members can view their groups"
    ON study_groups
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM group_members gm
            WHERE gm.group_id = id
            AND gm.user_id = auth.uid()
        )
    );

-- グループオーナーは自分のグループを管理可能
CREATE POLICY "Group owners can manage their groups"
    ON study_groups
    FOR ALL
    USING (auth.uid() = owner_id);

-- グループ管理者は更新可能
CREATE POLICY "Group admins can update groups"
    ON study_groups
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM group_members gm
            WHERE gm.group_id = id
            AND gm.user_id = auth.uid()
            AND gm.role IN ('owner', 'admin')
        )
    );

-- 認証済みユーザーは新しいグループを作成可能
CREATE POLICY "Authenticated users can create groups"
    ON study_groups
    FOR INSERT
    WITH CHECK (auth.uid() = owner_id);

-- ========================================
-- 6. グループメンバーポリシー
-- ========================================

-- グループメンバーはメンバー情報を閲覧可能
CREATE POLICY "Group members can view member list"
    ON group_members
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM group_members gm
            WHERE gm.group_id = group_id
            AND gm.user_id = auth.uid()
        )
    );

-- 自分のメンバーシップは管理可能
CREATE POLICY "Users can manage their own membership"
    ON group_members
    FOR ALL
    USING (auth.uid() = user_id);

-- グループオーナー・管理者はメンバーを管理可能
CREATE POLICY "Group admins can manage members"
    ON group_members
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM group_members gm
            WHERE gm.group_id = group_id
            AND gm.user_id = auth.uid()
            AND gm.role IN ('owner', 'admin')
        )
    );

-- ========================================
-- 7. グループ招待ポリシー
-- ========================================

-- 招待者は自分の招待を管理可能
CREATE POLICY "Inviters can manage their invitations"
    ON group_invitations
    FOR ALL
    USING (auth.uid() = inviter_id);

-- 被招待者は自分への招待を閲覧・応答可能
CREATE POLICY "Invitees can view and respond to invitations"
    ON group_invitations
    FOR ALL
    USING (auth.uid() = invitee_id);

-- ========================================
-- 8. 掲示板ポリシー
-- ========================================

-- 掲示板カテゴリーは誰でも閲覧可能
CREATE POLICY "Board categories are viewable by everyone"
    ON board_categories
    FOR SELECT
    USING (is_active = true);

-- 認証済みユーザーは投稿を作成可能
CREATE POLICY "Authenticated users can create posts"
    ON board_posts
    FOR INSERT
    WITH CHECK (auth.uid() = author_id);

-- 投稿は誰でも閲覧可能
CREATE POLICY "Posts are viewable by everyone"
    ON board_posts
    FOR SELECT
    USING (true);

-- 作成者は自分の投稿を管理可能
CREATE POLICY "Authors can manage their own posts"
    ON board_posts
    FOR ALL
    USING (auth.uid() = author_id);

-- 返信は誰でも閲覧可能
CREATE POLICY "Replies are viewable by everyone"
    ON board_replies
    FOR SELECT
    USING (true);

-- 認証済みユーザーは返信を作成可能
CREATE POLICY "Authenticated users can create replies"
    ON board_replies
    FOR INSERT
    WITH CHECK (auth.uid() = author_id);

-- 作成者は自分の返信を管理可能
CREATE POLICY "Authors can manage their own replies"
    ON board_replies
    FOR ALL
    USING (auth.uid() = author_id);

-- ========================================
-- 9. グループチャットポリシー
-- ========================================

-- グループメンバーはチャットを閲覧可能
CREATE POLICY "Group members can view messages"
    ON group_messages
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM group_members gm
            WHERE gm.group_id = group_id
            AND gm.user_id = auth.uid()
        )
    );

-- グループメンバーはメッセージを投稿可能
CREATE POLICY "Group members can send messages"
    ON group_messages
    FOR INSERT
    WITH CHECK (
        auth.uid() = sender_id
        AND EXISTS (
            SELECT 1 FROM group_members gm
            WHERE gm.group_id = group_id
            AND gm.user_id = auth.uid()
        )
    );

-- 送信者は自分のメッセージを管理可能
CREATE POLICY "Senders can manage their own messages"
    ON group_messages
    FOR ALL
    USING (auth.uid() = sender_id);

-- 既読状態は該当ユーザーのみ管理可能
CREATE POLICY "Users can manage their own message reads"
    ON message_reads
    FOR ALL
    USING (auth.uid() = user_id);

-- ========================================
-- 10. 学習チャレンジポリシー
-- ========================================

-- アクティブなチャレンジは誰でも閲覧可能
CREATE POLICY "Active challenges are viewable by everyone"
    ON study_challenges
    FOR SELECT
    USING (is_active = true AND is_public = true);

-- 認証済みユーザーはチャレンジを作成可能
CREATE POLICY "Authenticated users can create challenges"
    ON study_challenges
    FOR INSERT
    WITH CHECK (auth.uid() = created_by);

-- 作成者は自分のチャレンジを管理可能
CREATE POLICY "Creators can manage their own challenges"
    ON study_challenges
    FOR ALL
    USING (auth.uid() = created_by);

-- チャレンジ参加者は参加情報を閲覧可能
CREATE POLICY "Participants can view challenge participation"
    ON challenge_participants
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM study_challenges sc
            WHERE sc.id = challenge_id
            AND sc.is_public = true
        )
    );

-- 自分の参加情報は管理可能
CREATE POLICY "Users can manage their own participation"
    ON challenge_participants
    FOR ALL
    USING (auth.uid() = user_id);

-- ========================================
-- 11. 学習記録ポリシー
-- ========================================

-- 自分の学習記録は管理可能
CREATE POLICY "Users can manage their own study records"
    ON daily_study_records
    FOR ALL
    USING (auth.uid() = user_id);

-- 公開プロフィールの学習記録は閲覧可能
CREATE POLICY "Public study records are viewable"
    ON daily_study_records
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = user_id
            AND p.is_public = true
        )
    );

-- フォロワーは学習記録を閲覧可能
CREATE POLICY "Followers can view study records"
    ON daily_study_records
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM follows f
            JOIN profiles p ON f.following_id = p.id
            WHERE f.follower_id = auth.uid()
            AND p.id = user_id
        )
    );

-- ========================================
-- 12. 通知ポリシー
-- ========================================

-- 自分の通知は管理可能
CREATE POLICY "Users can manage their own notifications"
    ON notifications
    FOR ALL
    USING (auth.uid() = user_id);

-- ========================================
-- 13. セキュリティ関数
-- ========================================

-- グループメンバーシップ確認関数
CREATE OR REPLACE FUNCTION is_group_member(
    p_group_id UUID,
    p_user_id UUID DEFAULT auth.uid()
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM group_members
        WHERE group_id = p_group_id
        AND user_id = p_user_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- グループ管理者確認関数
CREATE OR REPLACE FUNCTION is_group_admin(
    p_group_id UUID,
    p_user_id UUID DEFAULT auth.uid()
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM group_members
        WHERE group_id = p_group_id
        AND user_id = p_user_id
        AND role IN ('owner', 'admin')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- フォロー関係確認関数
CREATE OR REPLACE FUNCTION is_following(
    p_follower_id UUID,
    p_following_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM follows
        WHERE follower_id = p_follower_id
        AND following_id = p_following_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- 14. ビュー更新（セキュリティ考慮）
-- ========================================

-- セキュアなユーザー検索ビュー
CREATE OR REPLACE VIEW secure_user_search AS
SELECT 
    p.id,
    p.username,
    p.full_name,
    p.nickname,
    p.avatar_url,
    p.bio,
    p.current_level,
    p.study_code,
    p.is_studying,
    p.study_subject,
    p.created_at,
    fs.follower_count,
    fs.following_count,
    CASE 
        WHEN auth.uid() = p.id THEN true
        ELSE is_following(auth.uid(), p.id)
    END as is_following
FROM profiles p
LEFT JOIN follow_stats fs ON p.id = fs.id
WHERE p.is_public = true
   OR auth.uid() = p.id
   OR is_following(auth.uid(), p.id);

-- 完了メッセージ
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'RLS ポリシー設定完了';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'セキュリティ機能:';
    RAISE NOTICE '- 全テーブルでRLS有効化';
    RAISE NOTICE '- ユーザー別アクセス制御';
    RAISE NOTICE '- グループ権限管理';
    RAISE NOTICE '- プライバシー保護';
    RAISE NOTICE '- セキュリティ関数作成';
    RAISE NOTICE '';
    RAISE NOTICE '次のステップ:';
    RAISE NOTICE '1. Realtime設定';
    RAISE NOTICE '2. データモデル作成';
    RAISE NOTICE '3. UI実装';
    RAISE NOTICE '========================================';
END $$;