import Foundation

// MARK: - Study Group Models

// Note: StudyGroup is now defined in SocialLearningModels.swift

// Note: GroupMember is now defined in SocialLearningModels.swift

/// グループメンバーの詳細情報（プロフィールと学習状態を含む）
struct GroupMemberDetail: Codable, Identifiable, Equatable {
    let groupId: String
    let userId: String
    let role: GroupRole
    let joinedAt: Date
    let nickname: String?
    let fullName: String?
    let studyCode: String?
    let levelPoints: Int
    let currentLevel: Int
    let isStudying: Bool
    let studyStartTime: Date?
    let currentSessionMinutes: Int
    let studySubject: String?
    
    enum CodingKeys: String, CodingKey {
        case groupId = "group_id"
        case userId = "user_id"
        case role
        case joinedAt = "joined_at"
        case nickname
        case fullName = "full_name"
        case studyCode = "study_code"
        case levelPoints = "level_points"
        case currentLevel = "current_level"
        case isStudying = "is_studying"
        case studyStartTime = "study_start_time"
        case currentSessionMinutes = "current_session_minutes"
        case studySubject = "study_subject"
    }
    
    var id: String { userId }
    
    var displayName: String {
        return nickname ?? fullName ?? "名無しユーザー"
    }
    
    var studyStatusText: String {
        if isStudying {
            let hours = currentSessionMinutes / 60
            let minutes = currentSessionMinutes % 60
            let timeText = hours > 0 ? "\(hours)時間\(minutes)分" : "\(minutes)分"
            
            if let subject = studySubject, !subject.isEmpty {
                return "\(subject) - \(timeText)"
            } else {
                return "学習中 - \(timeText)"
            }
        } else {
            return "オフライン"
        }
    }
}

/// グループ対戦
struct GroupCompetition: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let groupId: String
    let competitionType: CompetitionType
    let startDate: Date
    let endDate: Date
    let isActive: Bool
    let createdBy: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case groupId = "group_id"
        case competitionType = "competition_type"
        case startDate = "start_date"
        case endDate = "end_date"
        case isActive = "is_active"
        case createdBy = "created_by"
        case createdAt = "created_at"
    }
    
    /// 対戦が進行中かどうか
    var isOngoing: Bool {
        let now = Date()
        return isActive && startDate <= now && now <= endDate
    }
    
    /// 対戦まで/終了までの残り時間
    var timeStatus: String {
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        if now < startDate {
            return "開始: \(formatter.string(from: startDate))"
        } else if now <= endDate {
            return "終了: \(formatter.string(from: endDate))"
        } else {
            return "終了済み"
        }
    }
}

/// 対戦参加者
struct CompetitionParticipant: Codable, Identifiable {
    let id: String
    let competitionId: String
    let userId: String
    let studyMinutes: Int
    let memoCount: Int
    let streakDays: Int
    let lastUpdated: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case competitionId = "competition_id"
        case userId = "user_id"
        case studyMinutes = "study_minutes"
        case memoCount = "memo_count"
        case streakDays = "streak_days"
        case lastUpdated = "last_updated"
    }
}

/// 対戦ランキング情報
struct CompetitionRanking: Codable, Identifiable {
    let competitionId: String
    let userId: String
    let nickname: String?
    let fullName: String?
    let studyMinutes: Int
    let memoCount: Int
    let streakDays: Int
    let lastUpdated: Date
    let rank: Int
    
    enum CodingKeys: String, CodingKey {
        case competitionId = "competition_id"
        case userId = "user_id"
        case nickname
        case fullName = "full_name"
        case studyMinutes = "study_minutes"
        case memoCount = "memo_count"
        case streakDays = "streak_days"
        case lastUpdated = "last_updated"
        case rank
    }
    
    var id: String { userId }
    
    var displayName: String {
        return nickname ?? fullName ?? "名無しユーザー"
    }
    
    var formattedStudyTime: String {
        let hours = studyMinutes / 60
        let minutes = studyMinutes % 60
        return hours > 0 ? "\(hours)時間\(minutes)分" : "\(minutes)分"
    }
}

// MARK: - Enhanced Friend Models

/// 拡張フレンド情報（学習状態を含む）
struct EnhancedFriend: Codable, Identifiable {
    let userId: String
    let friendId: String
    let friendNickname: String?
    let friendFullName: String?
    let friendStudyCode: String?
    let friendLevelPoints: Int
    let friendLevel: Int
    let friendIsStudying: Bool
    let friendStudyStartTime: Date?
    let friendSessionMinutes: Int
    let friendStudySubject: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case friendId = "friend_id"
        case friendNickname = "friend_nickname"
        case friendFullName = "friend_full_name"
        case friendStudyCode = "friend_study_code"
        case friendLevelPoints = "friend_level_points"
        case friendLevel = "friend_level"
        case friendIsStudying = "friend_is_studying"
        case friendStudyStartTime = "friend_study_start_time"
        case friendSessionMinutes = "friend_session_minutes"
        case friendStudySubject = "friend_study_subject"
        case createdAt = "created_at"
    }
    
    var id: String { friendId }
    
    var displayName: String {
        return friendNickname ?? friendFullName ?? "名無しユーザー"
    }
    
    var studyStatusText: String {
        if friendIsStudying {
            let hours = friendSessionMinutes / 60
            let minutes = friendSessionMinutes % 60
            let timeText = hours > 0 ? "\(hours)時間\(minutes)分" : "\(minutes)分"
            
            if let subject = friendStudySubject, !subject.isEmpty {
                return "\(subject) - \(timeText)"
            } else {
                return "学習中 - \(timeText)"
            }
        } else {
            return "オフライン"
        }
    }
    
    var studyStatusColor: String {
        return friendIsStudying ? "green" : "gray"
    }
}

/// スタディグループ用フレンドリクエスト
struct StudyGroupFriendRequest: Codable, Identifiable {
    let id: String
    let fromUserId: String
    let toUserId: String
    let status: StudyGroupFriendRequestStatus
    let message: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case fromUserId = "from_user_id"
        case toUserId = "to_user_id"
        case status
        case message
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// ユーザー学習状態
struct UserStudyStatus: Codable {
    let userId: String
    let isStudying: Bool
    let studyStartTime: Date?
    let currentSessionMinutes: Int
    let studySubject: String?
    let lastHeartbeat: Date
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case isStudying = "is_studying"
        case studyStartTime = "study_start_time"
        case currentSessionMinutes = "current_session_minutes"
        case studySubject = "study_subject"
        case lastHeartbeat = "last_heartbeat"
    }
    
    var studyDuration: TimeInterval? {
        guard isStudying, let startTime = studyStartTime else { return nil }
        return Date().timeIntervalSince(startTime)
    }
    
    var formattedStudyTime: String {
        let hours = currentSessionMinutes / 60
        let minutes = currentSessionMinutes % 60
        return hours > 0 ? "\(hours)時間\(minutes)分" : "\(minutes)分"
    }
}

// Note: DailyStudyRecord is now defined in SocialLearningModels.swift

// MARK: - Enums

// Note: GroupRole is now defined in SocialLearningModels.swift

/// 対戦の種類
enum CompetitionType: String, Codable, CaseIterable {
    case studyTime = "study_time"
    case memoCount = "memo_count"
    case streak = "streak"
    
    var displayName: String {
        switch self {
        case .studyTime:
            return "学習時間"
        case .memoCount:
            return "メモ数"
        case .streak:
            return "継続日数"
        }
    }
    
    var description: String {
        switch self {
        case .studyTime:
            return "期間中の総学習時間で競争"
        case .memoCount:
            return "期間中に作成したメモ数で競争"
        case .streak:
            return "継続学習日数で競争"
        }
    }
    
    var unit: String {
        switch self {
        case .studyTime:
            return "分"
        case .memoCount:
            return "個"
        case .streak:
            return "日"
        }
    }
}

/// フレンドリクエストの状態
enum StudyGroupFriendRequestStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case accepted = "accepted"
    case rejected = "rejected"
    
    var displayName: String {
        switch self {
        case .pending:
            return "保留中"
        case .accepted:
            return "承認済み"
        case .rejected:
            return "拒否済み"
        }
    }
}

// MARK: - Request/Response Models

/// グループ作成リクエスト
struct CreateGroupRequest {
    let name: String
    let description: String?
    let maxMembers: Int
    let isPublic: Bool
}

/// グループ作成レスポンス
struct CreateGroupResponse: Codable {
    let success: Bool
    let groupId: String?
    let groupCode: String?
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case groupId = "group_id"
        case groupCode = "group_code"
        case message
    }
}

/// 対戦作成リクエスト
struct CreateCompetitionRequest {
    let name: String
    let description: String?
    let competitionType: CompetitionType
    let durationDays: Int
}

/// フレンド追加レスポンス
struct AddFriendResponse: Codable {
    let success: Bool
    let friendId: String?
    let error: String?
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case friendId = "friend_id"
        case error
        case message
    }
}