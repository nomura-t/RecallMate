-- ========================================
-- RecallMate Realtime 設定
-- チャット・リアルタイム機能
-- ========================================

-- 実行前提: 
-- 1. 基本スキーマが作成済み
-- 2. RLSポリシーが設定済み
-- 3. Supabase Dashboard でRealtime機能が有効化済み

-- ========================================
-- 1. Realtime Publication 設定
-- ========================================

-- 既存のpublicationを削除（存在する場合）
DROP PUBLICATION IF EXISTS supabase_realtime;

-- 新しいpublicationを作成
CREATE PUBLICATION supabase_realtime FOR TABLE 
    profiles,
    follows,
    study_sessions,
    study_groups,
    group_members,
    group_invitations,
    board_posts,
    board_replies,
    group_messages,
    message_reads,
    study_challenges,
    challenge_participants,
    daily_study_records,
    notifications;

-- ========================================
-- 2. Realtime 関数とトリガー
-- ========================================

-- メッセージ送信時の通知関数
CREATE OR REPLACE FUNCTION notify_new_message()
RETURNS TRIGGER AS $$
BEGIN
    -- グループメンバーに通知を送信
    INSERT INTO notifications (user_id, type, title, content, related_id, related_type, sender_id)
    SELECT 
        gm.user_id,
        'new_message',
        sg.name || ' に新しいメッセージ',
        LEFT(NEW.content, 100) || CASE WHEN LENGTH(NEW.content) > 100 THEN '...' ELSE '' END,
        NEW.id,
        'group_messages',
        NEW.sender_id
    FROM group_members gm
    JOIN study_groups sg ON gm.group_id = sg.id
    WHERE gm.group_id = NEW.group_id
    AND gm.user_id != NEW.sender_id; -- 送信者以外
    
    -- Realtime チャンネルにブロードキャスト
    PERFORM pg_notify('group_message', json_build_object(
        'group_id', NEW.group_id,
        'message_id', NEW.id,
        'sender_id', NEW.sender_id,
        'content', NEW.content,
        'message_type', NEW.message_type,
        'created_at', NEW.created_at
    )::text);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- グループメッセージ挿入時のトリガー
CREATE OR REPLACE TRIGGER on_group_message_insert
    AFTER INSERT ON group_messages
    FOR EACH ROW EXECUTE FUNCTION notify_new_message();

-- 学習状態変更通知関数
CREATE OR REPLACE FUNCTION notify_study_status_change()
RETURNS TRIGGER AS $$
BEGIN
    -- 学習状態が変更された場合のみ通知
    IF OLD.is_studying != NEW.is_studying THEN
        -- フォロワーに通知
        INSERT INTO notifications (user_id, type, title, content, related_id, related_type, sender_id)
        SELECT 
            f.follower_id,
            'study_status_change',
            CASE 
                WHEN NEW.is_studying THEN NEW.username || ' が学習を開始しました'
                ELSE NEW.username || ' が学習を終了しました'
            END,
            CASE 
                WHEN NEW.is_studying THEN NEW.study_subject
                ELSE NULL
            END,
            NEW.id,
            'profiles',
            NEW.id
        FROM follows f
        WHERE f.following_id = NEW.id;
        
        -- Realtime チャンネルにブロードキャスト
        PERFORM pg_notify('study_status_change', json_build_object(
            'user_id', NEW.id,
            'username', NEW.username,
            'is_studying', NEW.is_studying,
            'study_subject', NEW.study_subject,
            'study_start_time', NEW.study_start_time
        )::text);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- プロフィール更新時のトリガー
CREATE OR REPLACE TRIGGER on_profile_study_status_change
    AFTER UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION notify_study_status_change();

-- 掲示板投稿通知関数
CREATE OR REPLACE FUNCTION notify_new_board_post()
RETURNS TRIGGER AS $$
BEGIN
    -- Realtime チャンネルにブロードキャスト
    PERFORM pg_notify('board_post', json_build_object(
        'post_id', NEW.id,
        'category_id', NEW.category_id,
        'author_id', NEW.author_id,
        'title', NEW.title,
        'content', LEFT(NEW.content, 200),
        'created_at', NEW.created_at
    )::text);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 掲示板投稿挿入時のトリガー
CREATE OR REPLACE TRIGGER on_board_post_insert
    AFTER INSERT ON board_posts
    FOR EACH ROW EXECUTE FUNCTION notify_new_board_post();

-- 掲示板返信通知関数
CREATE OR REPLACE FUNCTION notify_new_board_reply()
RETURNS TRIGGER AS $$
BEGIN
    -- 投稿作成者に通知
    INSERT INTO notifications (user_id, type, title, content, related_id, related_type, sender_id)
    SELECT 
        bp.author_id,
        'board_reply',
        '投稿に返信がありました',
        LEFT(NEW.content, 100) || CASE WHEN LENGTH(NEW.content) > 100 THEN '...' ELSE '' END,
        NEW.id,
        'board_replies',
        NEW.author_id
    FROM board_posts bp
    WHERE bp.id = NEW.post_id
    AND bp.author_id != NEW.author_id; -- 自分以外
    
    -- Realtime チャンネルにブロードキャスト
    PERFORM pg_notify('board_reply', json_build_object(
        'reply_id', NEW.id,
        'post_id', NEW.post_id,
        'author_id', NEW.author_id,
        'content', NEW.content,
        'created_at', NEW.created_at
    )::text);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 掲示板返信挿入時のトリガー
CREATE OR REPLACE TRIGGER on_board_reply_insert
    AFTER INSERT ON board_replies
    FOR EACH ROW EXECUTE FUNCTION notify_new_board_reply();

-- フォロー通知関数
CREATE OR REPLACE FUNCTION notify_new_follow()
RETURNS TRIGGER AS $$
BEGIN
    -- フォローされた人に通知
    INSERT INTO notifications (user_id, type, title, content, related_id, related_type, sender_id)
    SELECT 
        NEW.following_id,
        'new_follow',
        p.username || ' があなたをフォローしました',
        NULL,
        NEW.id,
        'follows',
        NEW.follower_id
    FROM profiles p
    WHERE p.id = NEW.follower_id;
    
    -- Realtime チャンネルにブロードキャスト
    PERFORM pg_notify('new_follow', json_build_object(
        'follow_id', NEW.id,
        'follower_id', NEW.follower_id,
        'following_id', NEW.following_id,
        'created_at', NEW.created_at
    )::text);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- フォロー挿入時のトリガー
CREATE OR REPLACE TRIGGER on_follow_insert
    AFTER INSERT ON follows
    FOR EACH ROW EXECUTE FUNCTION notify_new_follow();

-- グループ招待通知関数
CREATE OR REPLACE FUNCTION notify_group_invitation()
RETURNS TRIGGER AS $$
BEGIN
    -- 招待された人に通知
    INSERT INTO notifications (user_id, type, title, content, related_id, related_type, sender_id)
    SELECT 
        NEW.invitee_id,
        'group_invitation',
        sg.name || ' への招待',
        'グループに招待されました',
        NEW.id,
        'group_invitations',
        NEW.inviter_id
    FROM study_groups sg
    WHERE sg.id = NEW.group_id;
    
    -- Realtime チャンネルにブロードキャスト
    PERFORM pg_notify('group_invitation', json_build_object(
        'invitation_id', NEW.id,
        'group_id', NEW.group_id,
        'inviter_id', NEW.inviter_id,
        'invitee_id', NEW.invitee_id,
        'type', NEW.type,
        'created_at', NEW.created_at
    )::text);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- グループ招待挿入時のトリガー
CREATE OR REPLACE TRIGGER on_group_invitation_insert
    AFTER INSERT ON group_invitations
    FOR EACH ROW EXECUTE FUNCTION notify_group_invitation();

-- ========================================
-- 3. リアルタイム機能用のビュー
-- ========================================

-- アクティブなチャットルーム一覧
CREATE OR REPLACE VIEW active_chat_rooms AS
SELECT 
    sg.id,
    sg.name,
    sg.description,
    sg.current_members,
    sg.owner_id,
    owner.username as owner_username,
    recent_message.content as last_message,
    recent_message.created_at as last_message_at,
    recent_message.sender_id as last_sender_id,
    recent_sender.username as last_sender_username
FROM study_groups sg
LEFT JOIN profiles owner ON sg.owner_id = owner.id
LEFT JOIN LATERAL (
    SELECT gm.content, gm.created_at, gm.sender_id
    FROM group_messages gm
    WHERE gm.group_id = sg.id
    ORDER BY gm.created_at DESC
    LIMIT 1
) recent_message ON true
LEFT JOIN profiles recent_sender ON recent_message.sender_id = recent_sender.id
WHERE sg.current_members > 0
ORDER BY recent_message.created_at DESC NULLS LAST;

-- 現在学習中のフレンド一覧
CREATE OR REPLACE VIEW friends_studying_now AS
SELECT 
    f.follower_id,
    f.following_id,
    p.username,
    p.full_name,
    p.nickname,
    p.avatar_url,
    p.study_subject,
    p.study_start_time,
    EXTRACT(EPOCH FROM (NOW() - p.study_start_time)) / 60 as study_duration_minutes
FROM follows f
JOIN profiles p ON f.following_id = p.id
WHERE p.is_studying = true
ORDER BY p.study_start_time DESC;

-- 未読メッセージ数
CREATE OR REPLACE VIEW unread_message_counts AS
SELECT 
    gm.user_id,
    sg.id as group_id,
    sg.name as group_name,
    COUNT(CASE WHEN mr.id IS NULL THEN 1 END) as unread_count
FROM group_members gm
JOIN study_groups sg ON gm.group_id = sg.id
LEFT JOIN group_messages msg ON msg.group_id = sg.id
LEFT JOIN message_reads mr ON msg.id = mr.message_id AND mr.user_id = gm.user_id
GROUP BY gm.user_id, sg.id, sg.name
HAVING COUNT(CASE WHEN mr.id IS NULL THEN 1 END) > 0;

-- ========================================
-- 4. WebSocket チャンネル設定関数
-- ========================================

-- チャンネル参加許可チェック関数
CREATE OR REPLACE FUNCTION authorize_realtime_channel(
    channel_name TEXT,
    user_id UUID
) RETURNS BOOLEAN AS $$
BEGIN
    -- グループチャットチャンネル
    IF channel_name LIKE 'group_%' THEN
        RETURN EXISTS (
            SELECT 1 FROM group_members gm
            JOIN study_groups sg ON gm.group_id = sg.id
            WHERE gm.user_id = user_id
            AND sg.id = SUBSTRING(channel_name FROM 7)::UUID
        );
    END IF;
    
    -- 掲示板チャンネル（認証済みユーザー全員）
    IF channel_name = 'board' THEN
        RETURN user_id IS NOT NULL;
    END IF;
    
    -- フォロー関係チャンネル
    IF channel_name LIKE 'user_%' THEN
        RETURN user_id = SUBSTRING(channel_name FROM 6)::UUID;
    END IF;
    
    -- 学習状態チャンネル（認証済みユーザー全員）
    IF channel_name = 'study_status' THEN
        RETURN user_id IS NOT NULL;
    END IF;
    
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- 5. Presence 機能用関数
-- ========================================

-- ユーザーのオンライン状態を更新
CREATE OR REPLACE FUNCTION update_user_presence(
    p_user_id UUID,
    p_status TEXT DEFAULT 'online'
) RETURNS VOID AS $$
BEGIN
    UPDATE profiles 
    SET last_active_at = NOW()
    WHERE id = p_user_id;
    
    -- Presence チャンネルにブロードキャスト
    PERFORM pg_notify('user_presence', json_build_object(
        'user_id', p_user_id,
        'status', p_status,
        'last_active_at', NOW()
    )::text);
END;
$$ LANGUAGE plpgsql;

-- 学習セッションのハートビート
CREATE OR REPLACE FUNCTION study_session_heartbeat(
    p_user_id UUID
) RETURNS VOID AS $$
BEGIN
    -- プロフィールの最終アクティブ時刻を更新
    UPDATE profiles 
    SET last_active_at = NOW()
    WHERE id = p_user_id;
    
    -- アクティブな学習セッションのハートビート
    UPDATE study_sessions 
    SET updated_at = NOW()
    WHERE user_id = p_user_id 
    AND is_active = true;
    
    -- 学習状態をブロードキャスト
    PERFORM pg_notify('study_heartbeat', json_build_object(
        'user_id', p_user_id,
        'timestamp', NOW()
    )::text);
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- 6. メッセージ既読機能
-- ========================================

-- メッセージを既読にする関数
CREATE OR REPLACE FUNCTION mark_messages_as_read(
    p_user_id UUID,
    p_group_id UUID,
    p_last_read_message_id UUID DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
    -- 指定されたメッセージまで、または全てのメッセージを既読にする
    INSERT INTO message_reads (message_id, user_id, read_at)
    SELECT 
        gm.id,
        p_user_id,
        NOW()
    FROM group_messages gm
    WHERE gm.group_id = p_group_id
    AND gm.sender_id != p_user_id -- 自分のメッセージは除外
    AND (p_last_read_message_id IS NULL OR gm.created_at <= (
        SELECT created_at FROM group_messages WHERE id = p_last_read_message_id
    ))
    ON CONFLICT (message_id, user_id) DO UPDATE 
    SET read_at = NOW();
    
    -- 既読状態をブロードキャスト
    PERFORM pg_notify('message_read', json_build_object(
        'group_id', p_group_id,
        'user_id', p_user_id,
        'last_read_message_id', p_last_read_message_id,
        'read_at', NOW()
    )::text);
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- 7. 定期クリーンアップ関数
-- ========================================

-- 古い通知を削除
CREATE OR REPLACE FUNCTION cleanup_old_notifications()
RETURNS VOID AS $$
BEGIN
    DELETE FROM notifications
    WHERE created_at < NOW() - INTERVAL '30 days';
    
    RAISE NOTICE 'クリーンアップ完了: 30日以上前の通知を削除';
END;
$$ LANGUAGE plpgsql;

-- 期限切れのグループ招待を削除
CREATE OR REPLACE FUNCTION cleanup_expired_invitations()
RETURNS VOID AS $$
BEGIN
    DELETE FROM group_invitations
    WHERE expires_at < NOW()
    AND status = 'pending';
    
    RAISE NOTICE 'クリーンアップ完了: 期限切れのグループ招待を削除';
END;
$$ LANGUAGE plpgsql;

-- 非アクティブな学習セッションを終了
CREATE OR REPLACE FUNCTION cleanup_stale_study_sessions()
RETURNS VOID AS $$
BEGIN
    -- 24時間以上更新されていないアクティブセッションを終了
    UPDATE study_sessions
    SET is_active = false,
        end_time = updated_at,
        duration_minutes = EXTRACT(EPOCH FROM (updated_at - start_time)) / 60
    WHERE is_active = true
    AND updated_at < NOW() - INTERVAL '24 hours';
    
    -- 対応するプロフィールも更新
    UPDATE profiles
    SET is_studying = false,
        study_start_time = NULL,
        study_subject = NULL
    WHERE is_studying = true
    AND last_active_at < NOW() - INTERVAL '24 hours';
    
    RAISE NOTICE 'クリーンアップ完了: 古い学習セッションを終了';
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- 8. 初期設定と確認
-- ========================================

-- Realtime機能の有効化確認
DO $$
BEGIN
    -- 基本的なテーブルがRealtime有効になっているか確認
    IF EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND tablename = 'group_messages'
    ) THEN
        RAISE NOTICE 'Realtime publication設定済み';
    ELSE
        RAISE NOTICE '警告: Realtime publicationが正しく設定されていません';
    END IF;
END $$;

-- 完了メッセージ
DO $$
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'RecallMate Realtime設定完了';
    RAISE NOTICE '================================================';
    RAISE NOTICE '設定された機能:';
    RAISE NOTICE '- WebSocket Publication設定';
    RAISE NOTICE '- チャットメッセージのリアルタイム配信';
    RAISE NOTICE '- 学習状態変更の通知';
    RAISE NOTICE '- 掲示板投稿・返信の通知';
    RAISE NOTICE '- フォロー・グループ招待の通知';
    RAISE NOTICE '- メッセージ既読機能';
    RAISE NOTICE '- Presence機能（学習中状態）';
    RAISE NOTICE '- 定期クリーンアップ機能';
    RAISE NOTICE '';
    RAISE NOTICE '次のステップ:';
    RAISE NOTICE '1. Supabase Dashboard でRealtime機能を有効化';
    RAISE NOTICE '2. iOS アプリでWebSocket接続を実装';
    RAISE NOTICE '3. チャット UI の作成';
    RAISE NOTICE '4. 定期クリーンアップのcron設定';
    RAISE NOTICE '';
    RAISE NOTICE 'チャンネル名例:';
    RAISE NOTICE '- group_[UUID] (グループチャット)';
    RAISE NOTICE '- board (掲示板)';
    RAISE NOTICE '- user_[UUID] (個人通知)';
    RAISE NOTICE '- study_status (学習状態)';
    RAISE NOTICE '================================================';
END $$;