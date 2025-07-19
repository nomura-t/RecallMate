-- ========================================
-- RecallMate 集計ビュー・マテリアライズドビュー
-- ランキングと統計機能
-- ========================================

-- 実行前提: 基本スキーマとRLSポリシーが設定済み

-- ========================================
-- 1. マテリアライズドビュー作成
-- ========================================

-- 日次学習統計 (高速検索用)
CREATE MATERIALIZED VIEW IF NOT EXISTS daily_study_stats AS
SELECT 
    dsr.user_id,
    dsr.study_date,
    p.username,
    p.full_name,
    p.nickname,
    p.avatar_url,
    p.current_level,
    dsr.total_minutes,
    dsr.memo_count,
    dsr.review_count,
    dsr.session_count,
    dsr.focus_score,
    dsr.efficiency_score,
    dsr.goal_achieved,
    -- 累積統計
    SUM(dsr.total_minutes) OVER (
        PARTITION BY dsr.user_id 
        ORDER BY dsr.study_date
    ) as cumulative_minutes,
    -- 週間移動平均
    AVG(dsr.total_minutes) OVER (
        PARTITION BY dsr.user_id 
        ORDER BY dsr.study_date 
        ROWS 6 PRECEDING
    ) as weekly_avg_minutes,
    -- 連続学習日数
    ROW_NUMBER() OVER (
        PARTITION BY dsr.user_id, 
        dsr.study_date - INTERVAL '1 day' * ROW_NUMBER() OVER (
            PARTITION BY dsr.user_id 
            ORDER BY dsr.study_date
        )
        ORDER BY dsr.study_date
    ) as current_streak_days
FROM daily_study_records dsr
JOIN profiles p ON dsr.user_id = p.id
WHERE p.is_public = true
ORDER BY dsr.study_date DESC, dsr.total_minutes DESC;

-- インデックス作成
CREATE UNIQUE INDEX IF NOT EXISTS idx_daily_study_stats_user_date 
ON daily_study_stats (user_id, study_date);

CREATE INDEX IF NOT EXISTS idx_daily_study_stats_date 
ON daily_study_stats (study_date);

CREATE INDEX IF NOT EXISTS idx_daily_study_stats_total_minutes 
ON daily_study_stats (total_minutes DESC);

-- 週間学習ランキング (高速検索用)
CREATE MATERIALIZED VIEW IF NOT EXISTS weekly_study_leaderboard AS
SELECT 
    p.id as user_id,
    p.username,
    p.full_name,
    p.nickname,
    p.avatar_url,
    p.current_level,
    p.total_study_minutes,
    p.current_streak,
    p.longest_streak,
    COALESCE(SUM(dsr.total_minutes), 0) as weekly_minutes,
    COALESCE(SUM(dsr.memo_count), 0) as weekly_memos,
    COALESCE(SUM(dsr.review_count), 0) as weekly_reviews,
    COALESCE(SUM(dsr.session_count), 0) as weekly_sessions,
    COALESCE(AVG(dsr.focus_score), 0) as avg_focus_score,
    COALESCE(AVG(dsr.efficiency_score), 0) as avg_efficiency_score,
    COUNT(CASE WHEN dsr.goal_achieved THEN 1 END) as goals_achieved,
    COUNT(dsr.study_date) as study_days,
    -- ランキング計算
    ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(dsr.total_minutes), 0) DESC) as minutes_rank,
    ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(dsr.memo_count), 0) DESC) as memos_rank,
    ROW_NUMBER() OVER (ORDER BY COUNT(dsr.study_date) DESC) as consistency_rank,
    ROW_NUMBER() OVER (ORDER BY COALESCE(AVG(dsr.focus_score), 0) DESC) as focus_rank,
    -- 前週比較
    LAG(COALESCE(SUM(dsr.total_minutes), 0)) OVER (
        PARTITION BY p.id 
        ORDER BY DATE_TRUNC('week', CURRENT_DATE)
    ) as last_week_minutes,
    -- 学習効率指標
    CASE 
        WHEN COALESCE(SUM(dsr.total_minutes), 0) > 0 THEN 
            COALESCE(SUM(dsr.memo_count), 0) * 1.0 / COALESCE(SUM(dsr.total_minutes), 1)
        ELSE 0 
    END as memos_per_minute,
    -- 活動レベル
    CASE 
        WHEN COALESCE(SUM(dsr.total_minutes), 0) >= 1440 THEN 'Very High'  -- 24時間以上
        WHEN COALESCE(SUM(dsr.total_minutes), 0) >= 720 THEN 'High'        -- 12時間以上
        WHEN COALESCE(SUM(dsr.total_minutes), 0) >= 360 THEN 'Medium'      -- 6時間以上
        WHEN COALESCE(SUM(dsr.total_minutes), 0) >= 60 THEN 'Low'          -- 1時間以上
        ELSE 'Very Low'
    END as activity_level,
    -- 更新日時
    NOW() as updated_at
FROM profiles p
LEFT JOIN daily_study_records dsr ON p.id = dsr.user_id 
    AND dsr.study_date >= DATE_TRUNC('week', CURRENT_DATE - INTERVAL '7 days')
    AND dsr.study_date < DATE_TRUNC('week', CURRENT_DATE)
WHERE p.is_public = true
GROUP BY p.id, p.username, p.full_name, p.nickname, p.avatar_url, 
         p.current_level, p.total_study_minutes, p.current_streak, p.longest_streak
ORDER BY weekly_minutes DESC, weekly_memos DESC;

-- インデックス作成
CREATE UNIQUE INDEX IF NOT EXISTS idx_weekly_leaderboard_user 
ON weekly_study_leaderboard (user_id);

CREATE INDEX IF NOT EXISTS idx_weekly_leaderboard_minutes_rank 
ON weekly_study_leaderboard (minutes_rank);

CREATE INDEX IF NOT EXISTS idx_weekly_leaderboard_activity_level 
ON weekly_study_leaderboard (activity_level);

-- 月間学習統計
CREATE MATERIALIZED VIEW IF NOT EXISTS monthly_study_stats AS
SELECT 
    p.id as user_id,
    p.username,
    p.full_name,
    p.nickname,
    p.avatar_url,
    p.current_level,
    DATE_TRUNC('month', dsr.study_date) as study_month,
    COALESCE(SUM(dsr.total_minutes), 0) as monthly_minutes,
    COALESCE(SUM(dsr.memo_count), 0) as monthly_memos,
    COALESCE(SUM(dsr.review_count), 0) as monthly_reviews,
    COALESCE(AVG(dsr.focus_score), 0) as avg_focus_score,
    COALESCE(AVG(dsr.efficiency_score), 0) as avg_efficiency_score,
    COUNT(dsr.study_date) as study_days,
    COUNT(CASE WHEN dsr.goal_achieved THEN 1 END) as goals_achieved,
    -- 月間ランキング
    ROW_NUMBER() OVER (
        PARTITION BY DATE_TRUNC('month', dsr.study_date)
        ORDER BY COALESCE(SUM(dsr.total_minutes), 0) DESC
    ) as monthly_rank,
    -- 前月比較
    LAG(COALESCE(SUM(dsr.total_minutes), 0)) OVER (
        PARTITION BY p.id 
        ORDER BY DATE_TRUNC('month', dsr.study_date)
    ) as last_month_minutes,
    -- パフォーマンス指標
    CASE 
        WHEN COUNT(dsr.study_date) >= 25 THEN 'Excellent'
        WHEN COUNT(dsr.study_date) >= 20 THEN 'Good'
        WHEN COUNT(dsr.study_date) >= 15 THEN 'Average'
        WHEN COUNT(dsr.study_date) >= 10 THEN 'Below Average'
        ELSE 'Poor'
    END as consistency_rating,
    NOW() as updated_at
FROM profiles p
LEFT JOIN daily_study_records dsr ON p.id = dsr.user_id 
    AND dsr.study_date >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '12 months')
WHERE p.is_public = true
GROUP BY p.id, p.username, p.full_name, p.nickname, p.avatar_url, 
         p.current_level, DATE_TRUNC('month', dsr.study_date)
ORDER BY study_month DESC, monthly_minutes DESC;

-- インデックス作成
CREATE INDEX IF NOT EXISTS idx_monthly_stats_user_month 
ON monthly_study_stats (user_id, study_month);

CREATE INDEX IF NOT EXISTS idx_monthly_stats_month_rank 
ON monthly_study_stats (study_month, monthly_rank);

-- グループ統計
CREATE MATERIALIZED VIEW IF NOT EXISTS group_performance_stats AS
SELECT 
    sg.id as group_id,
    sg.name as group_name,
    sg.description,
    sg.owner_id,
    sg.current_members,
    sg.max_members,
    sg.created_at,
    owner.username as owner_username,
    owner.full_name as owner_name,
    -- 直近7日間の統計
    COALESCE(SUM(dsr.total_minutes), 0) as weekly_total_minutes,
    COALESCE(AVG(dsr.total_minutes), 0) as weekly_avg_minutes_per_member,
    COALESCE(SUM(dsr.memo_count), 0) as weekly_total_memos,
    COALESCE(SUM(dsr.review_count), 0) as weekly_total_reviews,
    COALESCE(AVG(dsr.focus_score), 0) as weekly_avg_focus_score,
    COUNT(DISTINCT dsr.user_id) as active_members_count,
    COUNT(DISTINCT dsr.study_date) as total_study_days,
    -- 最も活発なメンバー
    (SELECT p.username FROM profiles p 
     JOIN daily_study_records dsr2 ON p.id = dsr2.user_id 
     JOIN group_members gm2 ON p.id = gm2.user_id 
     WHERE gm2.group_id = sg.id 
     AND dsr2.study_date >= CURRENT_DATE - INTERVAL '7 days'
     GROUP BY p.id, p.username 
     ORDER BY SUM(dsr2.total_minutes) DESC 
     LIMIT 1) as top_contributor,
    -- グループランキング
    ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(dsr.total_minutes), 0) DESC) as group_rank,
    -- 活動レベル
    CASE 
        WHEN COALESCE(SUM(dsr.total_minutes), 0) >= 3600 THEN 'Very Active'  -- 60時間以上
        WHEN COALESCE(SUM(dsr.total_minutes), 0) >= 1800 THEN 'Active'       -- 30時間以上
        WHEN COALESCE(SUM(dsr.total_minutes), 0) >= 900 THEN 'Moderate'      -- 15時間以上
        WHEN COALESCE(SUM(dsr.total_minutes), 0) >= 300 THEN 'Low'           -- 5時間以上
        ELSE 'Very Low'
    END as activity_level,
    -- 成長率
    CASE 
        WHEN sg.created_at >= CURRENT_DATE - INTERVAL '14 days' THEN 'New'
        ELSE 'Established'
    END as group_maturity,
    NOW() as updated_at
FROM study_groups sg
LEFT JOIN profiles owner ON sg.owner_id = owner.id
LEFT JOIN group_members gm ON sg.id = gm.group_id
LEFT JOIN daily_study_records dsr ON gm.user_id = dsr.user_id 
    AND dsr.study_date >= CURRENT_DATE - INTERVAL '7 days'
WHERE sg.is_public = true
GROUP BY sg.id, sg.name, sg.description, sg.owner_id, sg.current_members, 
         sg.max_members, sg.created_at, owner.username, owner.full_name
ORDER BY weekly_total_minutes DESC;

-- インデックス作成
CREATE UNIQUE INDEX IF NOT EXISTS idx_group_performance_stats_group 
ON group_performance_stats (group_id);

CREATE INDEX IF NOT EXISTS idx_group_performance_stats_rank 
ON group_performance_stats (group_rank);

-- チャレンジ統計
CREATE MATERIALIZED VIEW IF NOT EXISTS challenge_leaderboard AS
SELECT 
    sc.id as challenge_id,
    sc.title,
    sc.description,
    sc.target_type,
    sc.target_value,
    sc.target_unit,
    sc.start_date,
    sc.end_date,
    sc.reward_points,
    sc.reward_badge,
    -- 参加者統計
    COUNT(cp.user_id) as total_participants,
    COUNT(CASE WHEN cp.is_completed THEN 1 END) as completed_count,
    COALESCE(AVG(cp.current_value), 0) as avg_progress,
    COALESCE(MAX(cp.current_value), 0) as max_progress,
    -- 完了率
    CASE 
        WHEN COUNT(cp.user_id) > 0 THEN 
            (COUNT(CASE WHEN cp.is_completed THEN 1 END) * 100.0 / COUNT(cp.user_id))
        ELSE 0 
    END as completion_rate,
    -- 上位参加者
    ARRAY_AGG(
        DISTINCT p.username 
        ORDER BY cp.current_value DESC 
    ) FILTER (WHERE cp.rank <= 3) as top_participants,
    -- チャレンジ状態
    CASE 
        WHEN CURRENT_DATE < sc.start_date THEN 'Upcoming'
        WHEN CURRENT_DATE > sc.end_date THEN 'Completed'
        ELSE 'Active'
    END as challenge_status,
    -- 残り時間
    CASE 
        WHEN CURRENT_DATE <= sc.end_date THEN 
            EXTRACT(EPOCH FROM (sc.end_date - CURRENT_DATE)) / 86400
        ELSE 0
    END as days_remaining,
    NOW() as updated_at
FROM study_challenges sc
LEFT JOIN challenge_participants cp ON sc.id = cp.challenge_id
LEFT JOIN profiles p ON cp.user_id = p.id
WHERE sc.is_public = true
GROUP BY sc.id, sc.title, sc.description, sc.target_type, sc.target_value, 
         sc.target_unit, sc.start_date, sc.end_date, sc.reward_points, sc.reward_badge
ORDER BY completion_rate DESC, total_participants DESC;

-- インデックス作成
CREATE UNIQUE INDEX IF NOT EXISTS idx_challenge_leaderboard_challenge 
ON challenge_leaderboard (challenge_id);

CREATE INDEX IF NOT EXISTS idx_challenge_leaderboard_status 
ON challenge_leaderboard (challenge_status);

-- ========================================
-- 2. 通常ビュー (リアルタイム更新)
-- ========================================

-- 現在学習中のユーザー
CREATE OR REPLACE VIEW currently_studying AS
SELECT 
    p.id,
    p.username,
    p.full_name,
    p.nickname,
    p.avatar_url,
    p.current_level,
    p.study_subject,
    p.study_start_time,
    EXTRACT(EPOCH FROM (NOW() - p.study_start_time)) / 60 as study_duration_minutes,
    p.status_message,
    -- フォロワー数
    COALESCE(fs.follower_count, 0) as follower_count,
    -- 今日の学習時間
    COALESCE(today_stats.total_minutes, 0) as today_minutes,
    -- 学習セッション数
    COALESCE(active_sessions.session_count, 0) as active_sessions
FROM profiles p
LEFT JOIN follow_stats fs ON p.id = fs.id
LEFT JOIN (
    SELECT user_id, total_minutes
    FROM daily_study_records
    WHERE study_date = CURRENT_DATE
) today_stats ON p.id = today_stats.user_id
LEFT JOIN (
    SELECT user_id, COUNT(*) as session_count
    FROM study_sessions
    WHERE is_active = true
    GROUP BY user_id
) active_sessions ON p.id = active_sessions.user_id
WHERE p.is_studying = true
  AND p.is_public = true
  AND p.study_start_time IS NOT NULL
ORDER BY p.study_start_time DESC;

-- トレンド分析ビュー
CREATE OR REPLACE VIEW study_trends AS
SELECT 
    p.id as user_id,
    p.username,
    p.full_name,
    p.nickname,
    p.avatar_url,
    p.current_level,
    -- 今週の統計
    COALESCE(this_week.total_minutes, 0) as this_week_minutes,
    COALESCE(this_week.memo_count, 0) as this_week_memos,
    COALESCE(this_week.session_count, 0) as this_week_sessions,
    -- 先週の統計
    COALESCE(last_week.total_minutes, 0) as last_week_minutes,
    COALESCE(last_week.memo_count, 0) as last_week_memos,
    COALESCE(last_week.session_count, 0) as last_week_sessions,
    -- 変化率
    CASE 
        WHEN COALESCE(last_week.total_minutes, 0) > 0 THEN 
            ((COALESCE(this_week.total_minutes, 0) - COALESCE(last_week.total_minutes, 0)) * 100.0 / COALESCE(last_week.total_minutes, 1))
        ELSE 0 
    END as minutes_change_percent,
    -- トレンド方向
    CASE 
        WHEN COALESCE(this_week.total_minutes, 0) > COALESCE(last_week.total_minutes, 0) THEN 'Increasing'
        WHEN COALESCE(this_week.total_minutes, 0) < COALESCE(last_week.total_minutes, 0) THEN 'Decreasing'
        ELSE 'Stable'
    END as trend_direction,
    -- パフォーマンス評価
    CASE 
        WHEN COALESCE(this_week.total_minutes, 0) >= 1200 THEN 'Excellent'  -- 20時間以上
        WHEN COALESCE(this_week.total_minutes, 0) >= 600 THEN 'Good'        -- 10時間以上
        WHEN COALESCE(this_week.total_minutes, 0) >= 300 THEN 'Average'     -- 5時間以上
        WHEN COALESCE(this_week.total_minutes, 0) >= 60 THEN 'Below Average' -- 1時間以上
        ELSE 'Poor'
    END as performance_rating
FROM profiles p
LEFT JOIN (
    SELECT 
        user_id,
        SUM(total_minutes) as total_minutes,
        SUM(memo_count) as memo_count,
        SUM(session_count) as session_count
    FROM daily_study_records
    WHERE study_date >= DATE_TRUNC('week', CURRENT_DATE)
    GROUP BY user_id
) this_week ON p.id = this_week.user_id
LEFT JOIN (
    SELECT 
        user_id,
        SUM(total_minutes) as total_minutes,
        SUM(memo_count) as memo_count,
        SUM(session_count) as session_count
    FROM daily_study_records
    WHERE study_date >= DATE_TRUNC('week', CURRENT_DATE - INTERVAL '7 days')
      AND study_date < DATE_TRUNC('week', CURRENT_DATE)
    GROUP BY user_id
) last_week ON p.id = last_week.user_id
WHERE p.is_public = true
ORDER BY this_week_minutes DESC;

-- ========================================
-- 3. 更新関数
-- ========================================

-- マテリアライズドビュー更新関数
CREATE OR REPLACE FUNCTION refresh_study_statistics()
RETURNS VOID AS $$
BEGIN
    -- 並行更新を実行
    REFRESH MATERIALIZED VIEW CONCURRENTLY daily_study_stats;
    REFRESH MATERIALIZED VIEW CONCURRENTLY weekly_study_leaderboard;
    REFRESH MATERIALIZED VIEW CONCURRENTLY monthly_study_stats;
    REFRESH MATERIALIZED VIEW CONCURRENTLY group_performance_stats;
    REFRESH MATERIALIZED VIEW CONCURRENTLY challenge_leaderboard;
    
    RAISE NOTICE 'マテリアライズドビュー更新完了: %', NOW();
END;
$$ LANGUAGE plpgsql;

-- 日次統計更新関数
CREATE OR REPLACE FUNCTION update_daily_statistics()
RETURNS VOID AS $$
BEGIN
    -- 昨日の学習記録を更新
    INSERT INTO daily_study_records (
        user_id, study_date, total_minutes, memo_count, 
        review_count, session_count, created_at
    )
    SELECT 
        ss.user_id,
        ss.start_time::DATE,
        SUM(COALESCE(ss.duration_minutes, 0)),
        SUM(COALESCE(ss.memo_count, 0)),
        SUM(COALESCE(ss.review_count, 0)),
        COUNT(*),
        NOW()
    FROM study_sessions ss
    WHERE ss.start_time::DATE = CURRENT_DATE - INTERVAL '1 day'
      AND ss.is_active = false
    GROUP BY ss.user_id, ss.start_time::DATE
    ON CONFLICT (user_id, study_date) DO UPDATE SET
        total_minutes = EXCLUDED.total_minutes,
        memo_count = EXCLUDED.memo_count,
        review_count = EXCLUDED.review_count,
        session_count = EXCLUDED.session_count;
    
    -- プロフィール統計を更新
    UPDATE profiles 
    SET 
        total_study_minutes = (
            SELECT COALESCE(SUM(total_minutes), 0) 
            FROM daily_study_records 
            WHERE user_id = profiles.id
        ),
        total_memo_count = (
            SELECT COALESCE(SUM(memo_count), 0) 
            FROM daily_study_records 
            WHERE user_id = profiles.id
        ),
        current_streak = (
            SELECT COUNT(*)
            FROM daily_study_records dsr
            WHERE dsr.user_id = profiles.id
              AND dsr.study_date >= CURRENT_DATE - INTERVAL (
                  SELECT COUNT(*) || ' days'
                  FROM daily_study_records dsr2
                  WHERE dsr2.user_id = profiles.id
                    AND dsr2.study_date >= CURRENT_DATE - INTERVAL '365 days'
                    AND dsr2.total_minutes > 0
              )::INTERVAL
              AND dsr.total_minutes > 0
        ),
        updated_at = NOW()
    WHERE id IN (
        SELECT DISTINCT user_id 
        FROM daily_study_records 
        WHERE study_date = CURRENT_DATE - INTERVAL '1 day'
    );
    
    RAISE NOTICE '日次統計更新完了: %', NOW();
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- 4. スケジュール設定用SQL
-- ========================================

-- 毎日午前2時にマテリアライズドビューを更新
-- 注意: 実際のcronジョブはSupabaseダッシュボードで設定
/*
-- pg_cron拡張を使用する場合の例
SELECT cron.schedule('refresh-study-stats', '0 2 * * *', 'SELECT refresh_study_statistics();');
SELECT cron.schedule('update-daily-stats', '0 1 * * *', 'SELECT update_daily_statistics();');
*/

-- 完了メッセージ
DO $$
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'RecallMate 集計ビュー・統計機能 設定完了';
    RAISE NOTICE '================================================';
    RAISE NOTICE '作成されたマテリアライズドビュー:';
    RAISE NOTICE '- daily_study_stats (日次学習統計)';
    RAISE NOTICE '- weekly_study_leaderboard (週間ランキング)';
    RAISE NOTICE '- monthly_study_stats (月間統計)';
    RAISE NOTICE '- group_performance_stats (グループ統計)';
    RAISE NOTICE '- challenge_leaderboard (チャレンジ統計)';
    RAISE NOTICE '';
    RAISE NOTICE '作成されたビュー:';
    RAISE NOTICE '- currently_studying (現在学習中)';
    RAISE NOTICE '- study_trends (トレンド分析)';
    RAISE NOTICE '';
    RAISE NOTICE '作成された更新関数:';
    RAISE NOTICE '- refresh_study_statistics()';
    RAISE NOTICE '- update_daily_statistics()';
    RAISE NOTICE '';
    RAISE NOTICE '次のステップ:';
    RAISE NOTICE '1. Supabaseダッシュボードでcronジョブを設定';
    RAISE NOTICE '2. 定期的なマテリアライズドビュー更新スケジュール';
    RAISE NOTICE '3. iOSアプリでランキング画面を実装';
    RAISE NOTICE '4. 統計データの可視化';
    RAISE NOTICE '================================================';
END $$;