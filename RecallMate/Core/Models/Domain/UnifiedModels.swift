import Foundation

// MARK: - Unified User Profile Model
/// 統一されたユーザープロフィールモデル
/// AuthenticationStateManager, SocialLearningModels, SupabaseClientの重複を解消
public struct UnifiedUserProfile: Codable, Identifiable, Equatable {
    public let id: String
    public let email: String?
    public let fullName: String?
    public let nickname: String?
    public let avatarURL: String?
    public let avatarIconId: String?
    public let bio: String?
    public let statusMessage: String?
    public let isOnline: Bool
    public let lastActiveAt: Date?
    public let createdAt: Date
    public let updatedAt: Date
    
    public init(
        id: String,
        email: String? = nil,
        fullName: String? = nil,
        nickname: String? = nil,
        avatarURL: String? = nil,
        avatarIconId: String? = nil,
        bio: String? = nil,
        statusMessage: String? = nil,
        isOnline: Bool = false,
        lastActiveAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.nickname = nickname
        self.avatarURL = avatarURL
        self.avatarIconId = avatarIconId
        self.bio = bio
        self.statusMessage = statusMessage
        self.isOnline = isOnline
        self.lastActiveAt = lastActiveAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Unified Error Model
/// 統一されたエラーモデル
/// AppError と ErrorHandling の重複を解消
public enum UnifiedError: Error, LocalizedError, Equatable {
    case authentication(AuthenticationError)
    case network(NetworkError)
    case data(DataError)
    case validation(ValidationError)
    case system(SystemError)
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .authentication(let error):
            return error.localizedDescription
        case .network(let error):
            return error.localizedDescription
        case .data(let error):
            return error.localizedDescription
        case .validation(let error):
            return error.localizedDescription
        case .system(let error):
            return error.localizedDescription
        case .unknown(let message):
            return message
        }
    }
}

public enum AuthenticationError: Error, LocalizedError, Equatable {
    case notAuthenticated
    case invalidCredentials
    case sessionExpired
    case accountDisabled
    case emailNotVerified
    
    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "認証が必要です"
        case .invalidCredentials:
            return "認証情報が無効です"
        case .sessionExpired:
            return "セッションの期限が切れました"
        case .accountDisabled:
            return "アカウントが無効化されています"
        case .emailNotVerified:
            return "メールアドレスが確認されていません"
        }
    }
}

public enum NetworkError: Error, LocalizedError, Equatable {
    case noConnection
    case timeout
    case serverError(Int)
    case invalidResponse
    case requestFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .noConnection:
            return "インターネット接続がありません"
        case .timeout:
            return "リクエストがタイムアウトしました"
        case .serverError(let code):
            return "サーバーエラー (コード: \(code))"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .requestFailed(let message):
            return "リクエストが失敗しました: \(message)"
        }
    }
}

public enum DataError: Error, LocalizedError, Equatable {
    case notFound
    case invalidFormat
    case corruptedData
    case storageFailure
    case syncFailure
    
    public var errorDescription: String? {
        switch self {
        case .notFound:
            return "データが見つかりません"
        case .invalidFormat:
            return "データ形式が無効です"
        case .corruptedData:
            return "データが破損しています"
        case .storageFailure:
            return "ストレージの操作に失敗しました"
        case .syncFailure:
            return "データの同期に失敗しました"
        }
    }
}

public enum ValidationError: Error, LocalizedError, Equatable {
    case empty(String)
    case tooShort(String, Int)
    case tooLong(String, Int)
    case invalidFormat(String)
    case custom(String)
    
    public var errorDescription: String? {
        switch self {
        case .empty(let field):
            return "\(field)は必須です"
        case .tooShort(let field, let minLength):
            return "\(field)は\(minLength)文字以上である必要があります"
        case .tooLong(let field, let maxLength):
            return "\(field)は\(maxLength)文字以下である必要があります"
        case .invalidFormat(let field):
            return "\(field)の形式が無効です"
        case .custom(let message):
            return message
        }
    }
}

public enum SystemError: Error, LocalizedError, Equatable {
    case memoryWarning
    case diskSpaceLow
    case permissionDenied
    case fileSystemError
    case backgroundProcessingError
    
    public var errorDescription: String? {
        switch self {
        case .memoryWarning:
            return "メモリ不足です"
        case .diskSpaceLow:
            return "ディスク容量が不足しています"
        case .permissionDenied:
            return "権限が拒否されました"
        case .fileSystemError:
            return "ファイルシステムエラーが発生しました"
        case .backgroundProcessingError:
            return "バックグラウンド処理でエラーが発生しました"
        }
    }
}

// MARK: - Study Statistics
/// 統一された学習統計モデル
public struct UnifiedStudyStats: Codable, Equatable {
    public let totalMinutes: Int
    public let thisWeekMinutes: Int
    public let streakDays: Int
    public let averageSessionLength: Double
    public let completedSessions: Int
    public let perfectRecallCount: Int
    public let lastStudyDate: Date?
    
    public init(
        totalMinutes: Int = 0,
        thisWeekMinutes: Int = 0,
        streakDays: Int = 0,
        averageSessionLength: Double = 0,
        completedSessions: Int = 0,
        perfectRecallCount: Int = 0,
        lastStudyDate: Date? = nil
    ) {
        self.totalMinutes = totalMinutes
        self.thisWeekMinutes = thisWeekMinutes
        self.streakDays = streakDays
        self.averageSessionLength = averageSessionLength
        self.completedSessions = completedSessions
        self.perfectRecallCount = perfectRecallCount
        self.lastStudyDate = lastStudyDate
    }
}

// MARK: - Date Formatting Utilities
/// 統一された日付フォーマットユーティリティ
public struct DateFormatUtils {
    public static func formattedStudyTime(minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)時間\(remainingMinutes)分"
        } else {
            return "\(remainingMinutes)分"
        }
    }
    
    public static func relativeTimeString(from date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 60 {
            return "たった今"
        } else if interval < 3600 {
            return "\(Int(interval / 60))分前"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))時間前"
        } else {
            return "\(Int(interval / 86400))日前"
        }
    }
    
    public static func formatJapaneseDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Constants
/// アプリ全体で使用される定数
public struct AppConstants {
    public struct Validation {
        public static let minPasswordLength = 8
        public static let maxNameLength = 50
        public static let maxBioLength = 200
        public static let maxMemoContentLength = 10000
    }
    
    public struct Review {
        public static let defaultIntervals = [1, 3, 7, 14, 30] // days
        public static let maxRecallScore = 100
        public static let minRecallScore = 0
        public static let goodRecallThreshold = 70
    }
    
    public struct Social {
        public static let maxGroupMembers = 50
        public static let maxMessageLength = 500
        public static let onlineStatusTimeout: TimeInterval = 300 // 5 minutes
    }
}