import Foundation
import Combine

// MARK: - Authentication Service Protocol
/// 認証サービスのプロトコル
@MainActor
public protocol AuthenticationServiceProtocol: ObservableObject {
    var currentUser: UnifiedUserProfile? { get }
    var isAuthenticated: Bool { get }
    var authState: AuthenticationState { get }
    
    func signIn(email: String, password: String) async -> Result<UnifiedUserProfile, UnifiedError>
    func signUp(email: String, password: String, name: String) async -> Result<UnifiedUserProfile, UnifiedError>
    func signOut() async -> Result<Void, UnifiedError>
    func refreshToken() async -> Result<Void, UnifiedError>
    func updateProfile(_ profile: UnifiedUserProfile) async -> Result<UnifiedUserProfile, UnifiedError>
}

public enum AuthenticationState: Equatable {
    case unknown
    case authenticated(UnifiedUserProfile)
    case unauthenticated
    case loading
}

// MARK: - Data Repository Protocol
/// データリポジトリの基底プロトコル
@MainActor
public protocol DataRepositoryProtocol {
    associatedtype Entity: Identifiable
    associatedtype ID where ID == Entity.ID
    
    func create(_ entity: Entity) async -> Result<Entity, UnifiedError>
    func read(id: ID) async -> Result<Entity?, UnifiedError>
    func update(_ entity: Entity) async -> Result<Entity, UnifiedError>
    func delete(id: ID) async -> Result<Void, UnifiedError>
    func list() async -> Result<[Entity], UnifiedError>
}

// MARK: - Memo Repository Protocol
/// メモリポジトリのプロトコル
@MainActor
public protocol MemoRepositoryProtocol: DataRepositoryProtocol where Entity == Memo {
    func searchMemos(query: String) async -> Result<[Memo], UnifiedError>
    func getMemosDueForReview() async -> Result<[Memo], UnifiedError>
    func updateReviewDate(memoId: String, nextReviewDate: Date) async -> Result<Void, UnifiedError>
    func updateRecallScore(memoId: String, score: Int) async -> Result<Void, UnifiedError>
}

// MARK: - Sync Service Protocol
/// 同期サービスのプロトコル
@MainActor
public protocol SyncServiceProtocol: ObservableObject {
    var syncState: SyncState { get }
    var lastSyncDate: Date? { get }
    
    func sync() async -> Result<Void, UnifiedError>
    func forcefulSync() async -> Result<Void, UnifiedError>
    func enableAutoSync(_ enabled: Bool)
}

public enum SyncState: Equatable {
    case idle
    case syncing
    case success(Date)
    case failed(UnifiedError)
}

// MARK: - Notification Service Protocol
/// 通知サービスのプロトコル
public protocol NotificationServiceProtocol {
    func requestPermission() async -> Result<Bool, UnifiedError>
    func scheduleReviewNotification(for memo: Memo, at date: Date) async -> Result<Void, UnifiedError>
    func scheduleStreakReminder(at date: Date) async -> Result<Void, UnifiedError>
    func cancelNotification(id: String) async -> Result<Void, UnifiedError>
    func cancelAllNotifications() async -> Result<Void, UnifiedError>
}

// MARK: - Analytics Service Protocol
/// 分析サービスのプロトコル
public protocol AnalyticsServiceProtocol {
    func trackEvent(_ event: AnalyticsEvent) async
    func trackScreenView(_ screenName: String) async
    func trackUserProperty(key: String, value: String) async
    func setUserId(_ userId: String) async
}

public struct AnalyticsEvent {
    public let name: String
    public let parameters: [String: Any]
    public let timestamp: Date
    
    public init(name: String, parameters: [String: Any] = [:], timestamp: Date = Date()) {
        self.name = name
        self.parameters = parameters
        self.timestamp = timestamp
    }
}

// MARK: - Learning Activity Service Protocol
/// 学習活動サービスのプロトコル
@MainActor
public protocol LearningActivityServiceProtocol: ObservableObject {
    var currentStats: UnifiedStudyStats { get }
    
    func startLearningSession(activityType: ActivityType) async -> Result<String, UnifiedError>
    func endLearningSession(sessionId: String, duration: TimeInterval) async -> Result<Void, UnifiedError>
    func recordReview(memoId: String, recallScore: Int, timeSpent: TimeInterval) async -> Result<Void, UnifiedError>
    func getStats(for period: StatsPeriod) async -> Result<UnifiedStudyStats, UnifiedError>
    func updateStreak() async -> Result<Int, UnifiedError>
}

public enum StatsPeriod {
    case today
    case thisWeek
    case thisMonth
    case allTime
}

// MARK: - Event System Protocol
/// イベントシステムのプロトコル
public protocol EventPublisherProtocol {
    func publish<T: AppEvent>(_ event: T) async
    func subscribe<T: AppEvent>(to eventType: T.Type, handler: @escaping (T) async -> Void) -> AnyCancellable
}

public protocol AppEvent {
    var eventId: String { get }
    var timestamp: Date { get }
}

// MARK: - Specific Events
public struct UserAuthenticatedEvent: AppEvent {
    public let eventId = UUID().uuidString
    public let timestamp = Date()
    public let user: UnifiedUserProfile
    
    public init(user: UnifiedUserProfile) {
        self.user = user
    }
}

public struct MemoCreatedEvent: AppEvent {
    public let eventId = UUID().uuidString
    public let timestamp = Date()
    public let memo: Memo
    
    public init(memo: Memo) {
        self.memo = memo
    }
}

public struct ReviewCompletedEvent: AppEvent {
    public let eventId = UUID().uuidString
    public let timestamp = Date()
    public let memoId: String
    public let score: Int
    public let timeSpent: TimeInterval
    
    public init(memoId: String, score: Int, timeSpent: TimeInterval) {
        self.memoId = memoId
        self.score = score
        self.timeSpent = timeSpent
    }
}

public struct StreakUpdatedEvent: AppEvent {
    public let eventId = UUID().uuidString
    public let timestamp = Date()
    public let newStreakCount: Int
    
    public init(newStreakCount: Int) {
        self.newStreakCount = newStreakCount
    }
}

// MARK: - Configuration Protocol
/// 設定サービスのプロトコル
public protocol ConfigurationServiceProtocol {
    func getValue<T>(for key: ConfigurationKey, type: T.Type) -> T?
    func setValue<T>(_ value: T, for key: ConfigurationKey)
    func removeValue(for key: ConfigurationKey)
    func reset()
}

public enum ConfigurationKey: String, CaseIterable {
    case reviewNotificationsEnabled = "review_notifications_enabled"
    case streakNotificationsEnabled = "streak_notifications_enabled"
    case autoSyncEnabled = "auto_sync_enabled"
    case defaultReviewInterval = "default_review_interval"
    case studyGoalMinutes = "study_goal_minutes"
    case darkModeEnabled = "dark_mode_enabled"
    case soundsEnabled = "sounds_enabled"
    case hapticFeedbackEnabled = "haptic_feedback_enabled"
}