import Foundation
import Supabase

// MARK: - Enhanced Profile Model

struct EnhancedProfile: Codable, Identifiable {
    let id: String
    let username: String?
    let fullName: String?
    let nickname: String?
    let bio: String?
    let avatarUrl: String?
    let studyCode: String?
    
    // 学習統計
    let totalStudyMinutes: Int
    let totalMemoCount: Int
    let levelPoints: Int
    let currentLevel: Int
    let longestStreak: Int
    let currentStreak: Int
    
    // 状態管理
    let isStudying: Bool
    let studyStartTime: Date?
    let studySubject: String?
    let statusMessage: String?
    
    // 設定
    let isPublic: Bool
    let allowFriendRequests: Bool
    let allowGroupInvites: Bool
    let emailNotifications: Bool
    
    // システム
    let createdAt: Date
    let updatedAt: Date
    let lastActiveAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case fullName = "full_name"
        case nickname
        case bio
        case avatarUrl = "avatar_url"
        case studyCode = "study_code"
        case totalStudyMinutes = "total_study_minutes"
        case totalMemoCount = "total_memo_count"
        case levelPoints = "level_points"
        case currentLevel = "current_level"
        case longestStreak = "longest_streak"
        case currentStreak = "current_streak"
        case isStudying = "is_studying"
        case studyStartTime = "study_start_time"
        case studySubject = "study_subject"
        case statusMessage = "status_message"
        case isPublic = "is_public"
        case allowFriendRequests = "allow_friend_requests"
        case allowGroupInvites = "allow_group_invites"
        case emailNotifications = "email_notifications"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastActiveAt = "last_active_at"
    }
    
    // 学習時間を人間が読める形式にフォーマット
    var formattedStudyTime: String {
        let hours = totalStudyMinutes / 60
        let minutes = totalStudyMinutes % 60
        
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }
    
    // 現在の学習時間を計算
    var currentStudyDuration: Int {
        guard isStudying, let startTime = studyStartTime else { return 0 }
        return Int(Date().timeIntervalSince(startTime) / 60)
    }
    
    // 現在の学習時間を人間が読める形式で取得
    var currentStudyTimeFormatted: String {
        let duration = currentStudyDuration
        let hours = duration / 60
        let minutes = duration % 60
        
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }
}

// MARK: - Follow Relationship

struct Follow: Codable, Identifiable {
    let id: String
    let followerId: String
    let followingId: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case followerId = "follower_id"
        case followingId = "following_id"
        case createdAt = "created_at"
    }
}

// MARK: - Study Session

struct StudySession: Codable, Identifiable {
    let id: String
    let userId: String
    let subject: String?
    let startTime: Date
    let endTime: Date?
    let durationMinutes: Int?
    let memoCount: Int
    let reviewCount: Int
    let isActive: Bool
    let notes: String?
    let tags: [String]?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case subject
        case startTime = "start_time"
        case endTime = "end_time"
        case durationMinutes = "duration_minutes"
        case memoCount = "memo_count"
        case reviewCount = "review_count"
        case isActive = "is_active"
        case notes
        case tags
        case createdAt = "created_at"
    }
}

// MARK: - Study Group

struct StudyGroup: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let groupCode: String
    let coverImageUrl: String?
    let ownerId: String
    let maxMembers: Int
    let currentMembers: Int
    let isPublic: Bool
    let allowJoinRequests: Bool
    let requireApproval: Bool
    let studyGoals: [String]?
    let studySchedule: [String: String]?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case groupCode = "group_code"
        case coverImageUrl = "cover_image_url"
        case ownerId = "owner_id"
        case maxMembers = "max_members"
        case currentMembers = "current_members"
        case isPublic = "is_public"
        case allowJoinRequests = "allow_join_requests"
        case requireApproval = "require_approval"
        case studyGoals = "study_goals"
        case studySchedule = "study_schedule"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Group Member

struct GroupMember: Codable, Identifiable {
    let id: String
    let groupId: String
    let userId: String
    let role: GroupRole
    let joinedAt: Date
    let contributionScore: Int
    
    // 拡張プロパティ（JOIN結果で取得）
    var profile: EnhancedProfile?
    
    enum CodingKeys: String, CodingKey {
        case id
        case groupId = "group_id"
        case userId = "user_id"
        case role
        case joinedAt = "joined_at"
        case contributionScore = "contribution_score"
        case profile
    }
}

// MARK: - Group Member Detail
// Note: GroupMemberDetail is now defined in StudyGroupModels.swift

enum GroupRole: String, Codable, CaseIterable {
    case owner = "owner"
    case admin = "admin"
    case moderator = "moderator"
    case member = "member"
    
    var displayName: String {
        switch self {
        case .owner: return "オーナー"
        case .admin: return "管理者"
        case .moderator: return "モデレーター"
        case .member: return "メンバー"
        }
    }
    
    var canManageMembers: Bool {
        return self == .owner || self == .admin
    }
    
    var canModerateContent: Bool {
        return self == .owner || self == .admin || self == .moderator
    }
    
    var canManageGroup: Bool {
        return self == .owner || self == .admin
    }
    
    var canKickMembers: Bool {
        return self == .owner || self == .admin
    }
}

// MARK: - Group Invitation

struct GroupInvitation: Codable, Identifiable {
    let id: String
    let groupId: String
    let inviterId: String
    let inviteeId: String
    let type: InvitationType
    let status: InvitationStatus
    let message: String?
    let createdAt: Date
    let expiresAt: Date
    
    // 拡張プロパティ（JOIN結果で取得）
    var group: StudyGroup?
    var inviter: EnhancedProfile?
    var invitee: EnhancedProfile?
    
    enum CodingKeys: String, CodingKey {
        case id
        case groupId = "group_id"
        case inviterId = "inviter_id"
        case inviteeId = "invitee_id"
        case type
        case status
        case message
        case createdAt = "created_at"
        case expiresAt = "expires_at"
        case group
        case inviter
        case invitee
    }
}

enum InvitationType: String, Codable {
    case invitation = "invitation"
    case request = "request"
    
    var displayName: String {
        switch self {
        case .invitation: return "招待"
        case .request: return "参加申請"
        }
    }
}

enum InvitationStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case rejected = "rejected"
    case expired = "expired"
    
    var displayName: String {
        switch self {
        case .pending: return "保留中"
        case .accepted: return "承認済み"
        case .rejected: return "拒否済み"
        case .expired: return "期限切れ"
        }
    }
}

// MARK: - Board Category

struct BoardCategory: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String?
    let icon: String?
    let color: String?
    let isActive: Bool
    let sortOrder: Int
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case icon
        case color
        case isActive = "is_active"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
    }
}

// MARK: - Board Post

struct BoardPost: Codable, Identifiable {
    let id: String
    let categoryId: String
    let authorId: String
    let title: String
    let content: String
    let images: [String]?
    let tags: [String]?
    let viewCount: Int
    let likeCount: Int
    let replyCount: Int
    let isPinned: Bool
    let isLocked: Bool
    let isAnonymous: Bool
    let createdAt: Date
    let updatedAt: Date
    
    // 拡張プロパティ（JOIN結果で取得）
    var category: BoardCategory?
    var author: EnhancedProfile?
    
    enum CodingKeys: String, CodingKey {
        case id
        case categoryId = "category_id"
        case authorId = "author_id"
        case title
        case content
        case images
        case tags
        case viewCount = "view_count"
        case likeCount = "like_count"
        case replyCount = "reply_count"
        case isPinned = "is_pinned"
        case isLocked = "is_locked"
        case isAnonymous = "is_anonymous"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case category
        case author
    }
}

// MARK: - Board Reply

struct BoardReply: Codable, Identifiable {
    let id: String
    let postId: String
    let authorId: String
    let parentReplyId: String?
    let content: String
    let images: [String]?
    let likeCount: Int
    let isAnonymous: Bool
    let createdAt: Date
    let updatedAt: Date
    
    // 拡張プロパティ（JOIN結果で取得）
    var author: EnhancedProfile?
    // Note: parentReply causes recursive type issue, use parentReplyId instead
    
    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case authorId = "author_id"
        case parentReplyId = "parent_reply_id"
        case content
        case images
        case likeCount = "like_count"
        case isAnonymous = "is_anonymous"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case author
    }
}

// MARK: - Group Message

struct GroupMessage: Codable, Identifiable {
    let id: String
    let groupId: String
    let senderId: String
    let content: String
    let messageType: MessageType
    let fileUrl: String?
    let fileName: String?
    let fileSize: Int?
    let replyToId: String?
    let readCount: Int
    let createdAt: Date
    let updatedAt: Date
    
    // 拡張プロパティ（JOIN結果で取得）
    var sender: EnhancedProfile?
    // Note: replyTo causes recursive type issue, use replyToId instead
    var isRead: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case groupId = "group_id"
        case senderId = "sender_id"
        case content
        case messageType = "message_type"
        case fileUrl = "file_url"
        case fileName = "file_name"
        case fileSize = "file_size"
        case replyToId = "reply_to_id"
        case readCount = "read_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case sender
        case isRead
    }
}

enum MessageType: String, Codable {
    case text = "text"
    case image = "image"
    case file = "file"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .text: return "テキスト"
        case .image: return "画像"
        case .file: return "ファイル"
        case .system: return "システム"
        }
    }
}

// MARK: - Message Read

struct MessageRead: Codable, Identifiable {
    let id: String
    let messageId: String
    let userId: String
    let readAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case messageId = "message_id"
        case userId = "user_id"
        case readAt = "read_at"
    }
}

// MARK: - Study Challenge

struct StudyChallenge: Codable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let challengeType: ChallengeType
    let targetType: TargetType
    let targetValue: Int
    let targetUnit: String
    let startDate: Date
    let endDate: Date
    let rewardPoints: Int
    let rewardBadge: String?
    let isActive: Bool
    let isPublic: Bool
    let createdBy: String
    let createdAt: Date
    
    // 拡張プロパティ（JOIN結果で取得）
    var creator: EnhancedProfile?
    var participation: ChallengeParticipant?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case challengeType = "challenge_type"
        case targetType = "target_type"
        case targetValue = "target_value"
        case targetUnit = "target_unit"
        case startDate = "start_date"
        case endDate = "end_date"
        case rewardPoints = "reward_points"
        case rewardBadge = "reward_badge"
        case isActive = "is_active"
        case isPublic = "is_public"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case creator
        case participation
    }
}

enum ChallengeType: String, Codable {
    case individual = "individual"
    case group = "group"
    case global = "global"
    
    var displayName: String {
        switch self {
        case .individual: return "個人"
        case .group: return "グループ"
        case .global: return "全体"
        }
    }
}

enum TargetType: String, Codable {
    case studyTime = "study_time"
    case memoCount = "memo_count"
    case streak = "streak"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .studyTime: return "学習時間"
        case .memoCount: return "メモ数"
        case .streak: return "連続日数"
        case .custom: return "カスタム"
        }
    }
}

// MARK: - Challenge Participant

struct ChallengeParticipant: Codable, Identifiable {
    let id: String
    let challengeId: String
    let userId: String
    let currentValue: Int
    let isCompleted: Bool
    let completedAt: Date?
    let rank: Int?
    let joinedAt: Date
    
    // 拡張プロパティ（JOIN結果で取得）
    var user: EnhancedProfile?
    
    enum CodingKeys: String, CodingKey {
        case id
        case challengeId = "challenge_id"
        case userId = "user_id"
        case currentValue = "current_value"
        case isCompleted = "is_completed"
        case completedAt = "completed_at"
        case rank
        case joinedAt = "joined_at"
        case user
    }
}

// MARK: - Group Competition
// Note: GroupCompetition, CompetitionType, and CompetitionRanking are now defined in StudyGroupModels.swift

// MARK: - Daily Study Record

struct DailyStudyRecord: Codable, Identifiable {
    let id: String
    let userId: String
    let studyDate: Date
    let totalMinutes: Int
    let memoCount: Int
    let reviewCount: Int
    let sessionCount: Int
    let focusScore: Double
    let efficiencyScore: Double
    let dailyGoalMinutes: Int
    let goalAchieved: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case studyDate = "study_date"
        case totalMinutes = "total_minutes"
        case memoCount = "memo_count"
        case reviewCount = "review_count"
        case sessionCount = "session_count"
        case focusScore = "focus_score"
        case efficiencyScore = "efficiency_score"
        case dailyGoalMinutes = "daily_goal_minutes"
        case goalAchieved = "goal_achieved"
        case createdAt = "created_at"
    }
}

// MARK: - Notification

struct AppNotification: Codable, Identifiable {
    let id: String
    let userId: String
    let type: NotificationType
    let title: String
    let content: String?
    let relatedId: String?
    let relatedType: String?
    let senderId: String?
    let isRead: Bool
    let readAt: Date?
    let createdAt: Date
    
    // 拡張プロパティ（JOIN結果で取得）
    var sender: EnhancedProfile?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type
        case title
        case content
        case relatedId = "related_id"
        case relatedType = "related_type"
        case senderId = "sender_id"
        case isRead = "is_read"
        case readAt = "read_at"
        case createdAt = "created_at"
        case sender
    }
}

// MARK: - Notification Types

enum NotificationType: String, CaseIterable, Codable {
    case friendRequest = "friend_request"
    case friendAccepted = "friend_accepted"
    case groupInvite = "group_invite"
    case groupMessage = "group_message"
    case studyReminder = "study_reminder"
    case achievementUnlocked = "achievement_unlocked"
    case postReply = "post_reply"
    case postLike = "post_like"
    case newChallenge = "new_challenge"
    case challengeCompleted = "challenge_completed"
    case follow = "follow"
    case newFollow = "new_follow"
    case newMessage = "new_message"
    case boardReply = "board_reply"
    case groupInvitation = "group_invitation"
    case message = "message"
    case studyStatusChange = "study_status_change"
    
    var displayName: String {
        switch self {
        case .friendRequest: return "友達申請"
        case .friendAccepted: return "友達承認"
        case .groupInvite: return "グループ招待"
        case .groupMessage: return "グループメッセージ"
        case .studyReminder: return "学習リマインダー"
        case .achievementUnlocked: return "実績解除"
        case .postReply: return "投稿返信"
        case .postLike: return "投稿いいね"
        case .newChallenge: return "新しいチャレンジ"
        case .challengeCompleted: return "チャレンジ完了"
        case .follow: return "フォロー"
        case .newFollow: return "新しいフォロー"
        case .newMessage: return "新しいメッセージ"
        case .boardReply: return "掲示板返信"
        case .groupInvitation: return "グループ招待"
        case .message: return "メッセージ"
        case .studyStatusChange: return "学習状況変更"
        }
    }
}

// MARK: - View Models and Helper Extensions

extension EnhancedProfile {
    var displayName: String {
        return nickname ?? fullName ?? username ?? "Unknown User"
    }
    
    var isCurrentlyStudying: Bool {
        return isStudying && studyStartTime != nil
    }
}

extension StudyGroup {
    var canJoin: Bool {
        return currentMembers < maxMembers && (isPublic || allowJoinRequests)
    }
    
    var isFull: Bool {
        return currentMembers >= maxMembers
    }
}

extension GroupMessage {
    var isFromCurrentUser: Bool {
        // 現在のユーザーIDと比較する必要がある
        // AuthenticationManagerから取得
        // TODO: Fix this when AuthenticationManager is properly implemented
        return false // Placeholder until AuthenticationManager is available
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: createdAt)
    }
}

extension AppNotification {
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

// MARK: - Study Statistics

struct SocialStudyStats: Codable, Identifiable {
    let id: String
    let userId: String
    let dailyStudyTime: Int // in minutes
    let weeklyStudyTime: Int // in minutes
    let totalStudyTime: Int // in minutes
    let currentStreak: Int
    let isCurrentlyStudying: Bool
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case dailyStudyTime = "daily_study_time"
        case weeklyStudyTime = "weekly_study_time"
        case totalStudyTime = "total_study_time"
        case currentStreak = "current_streak"
        case isCurrentlyStudying = "is_currently_studying"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // フォーマット済みの時間文字列
    var formattedDailyTime: String {
        formatTime(dailyStudyTime)
    }
    
    var formattedWeeklyTime: String {
        formatTime(weeklyStudyTime)
    }
    
    var formattedTotalTime: String {
        formatTime(totalStudyTime)
    }
    
    private func formatTime(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)時間\(remainingMinutes)分"
        } else {
            return "\(remainingMinutes)分"
        }
    }
}

// MARK: - Friend Study Information

struct FriendStudyInfo: Codable, Identifiable {
    let id: String
    let userId: String
    let displayName: String
    let weeklyStudyTime: Int // in minutes
    let totalStudyTime: Int // in minutes
    let currentStreak: Int
    let isCurrentlyStudying: Bool
    let lastActiveAt: Date
    let createdAt: Date
    let updatedAt: Date
    let rank: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case displayName = "display_name"
        case weeklyStudyTime = "weekly_study_time"
        case totalStudyTime = "total_study_time"
        case currentStreak = "current_streak"
        case isCurrentlyStudying = "is_currently_studying"
        case lastActiveAt = "last_active_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case rank
    }
    
    // フォーマット済みの時間文字列
    var formattedWeeklyTime: String {
        formatTime(weeklyStudyTime)
    }
    
    var formattedTotalTime: String {
        formatTime(totalStudyTime)
    }
    
    private func formatTime(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)時間\(remainingMinutes)分"
        } else {
            return "\(remainingMinutes)分"
        }
    }
}