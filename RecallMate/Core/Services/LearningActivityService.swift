import Foundation
import Combine
import CoreData

// MARK: - Learning Activity Service
/// 学習活動サービスの実装
@MainActor
public class LearningActivityService: ObservableObject, LearningActivityServiceProtocol {
    
    @Published public var currentStats: UnifiedStudyStats = UnifiedStudyStats()
    
    private let persistenceController: PersistenceController
    private var context: NSManagedObjectContext {
        return persistenceController.container.viewContext
    }
    
    private var activeSessions: [String: Date] = [:]
    
    public init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        loadCurrentStats()
    }
    
    // MARK: - LearningActivityServiceProtocol
    
    public func startLearningSession(activityType: ActivityType) async -> Result<String, UnifiedError> {
        let sessionId = UUID().uuidString
        activeSessions[sessionId] = Date()
        
        // Track session start event
        if let eventPublisher = DIContainer.shared.resolve((any EventPublisherProtocol).self) {
            await eventPublisher.publish(SessionStartedEvent(sessionId: sessionId, activityType: activityType))
        }
        
        return .success(sessionId)
    }
    
    public func endLearningSession(sessionId: String, duration: TimeInterval) async -> Result<Void, UnifiedError> {
        guard let startTime = activeSessions[sessionId] else {
            return .failure(.validation(.custom("セッションが見つかりません")))
        }
        
        // Remove from active sessions
        activeSessions.removeValue(forKey: sessionId)
        
        // Create learning activity record
        let activity = LearningActivity(context: context)
        activity.id = UUID()
        activity.date = startTime
        activity.durationInSeconds = Int32(duration)
        activity.type = ActivityType.other.rawValue // Default type
        
        do {
            try context.save()
            
            // Update stats
            await updateCurrentStats()
            
            // Track session end event
            if let eventPublisher = DIContainer.shared.resolve((any EventPublisherProtocol).self) {
                await eventPublisher.publish(SessionEndedEvent(sessionId: sessionId, duration: duration))
            }
            
            return .success(())
        } catch {
            return .failure(.data(.storageFailure))
        }
    }
    
    public func recordReview(memoId: String, recallScore: Int, timeSpent: TimeInterval) async -> Result<Void, UnifiedError> {
        // Find the memo
        let request = Memo.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", memoId)
        request.fetchLimit = 1
        
        do {
            let memos = try context.fetch(request)
            guard let memo = memos.first else {
                return .failure(.data(.notFound))
            }
            
            // Create review activity
            let activity = LearningActivity(context: context)
            activity.id = UUID()
            activity.date = Date()
            activity.durationInSeconds = Int32(timeSpent)
            activity.type = ActivityType.review.rawValue
            activity.memo = memo
            
            // Update memo's recall score
            memo.recallScore = Int16(recallScore)
            memo.lastReviewedDate = Date()
            
            try context.save()
            
            // Update stats
            await updateCurrentStats()
            
            // Publish review completed event
            if let eventPublisher = DIContainer.shared.resolve((any EventPublisherProtocol).self) {
                await eventPublisher.publish(ReviewCompletedEvent(memoId: memoId, score: recallScore, timeSpent: timeSpent))
            }
            
            return .success(())
        } catch {
            return .failure(.data(.storageFailure))
        }
    }
    
    public func getStats(for period: StatsPeriod) async -> Result<UnifiedStudyStats, UnifiedError> {
        let (startDate, endDate) = getDateRange(for: period)
        
        let activities = LearningActivity.fetchActivities(from: startDate, to: endDate, in: context)
        
        let totalMinutes = activities.reduce(0) { $0 + Int($1.durationMinutes) }
        let completedSessions = activities.count
        let averageSessionLength = completedSessions > 0 ? Double(totalMinutes) / Double(completedSessions) : 0
        
        // Calculate perfect recalls
        let perfectRecallCount = activities.filter { activity in
            if let memo = activity.memo {
                return memo.recallScore >= AppConstants.Review.goodRecallThreshold
            }
            return false
        }.count
        
        // Calculate streak
        let streakDays = await calculateCurrentStreak()
        
        let stats = UnifiedStudyStats(
            totalMinutes: totalMinutes,
            thisWeekMinutes: period == .thisWeek ? totalMinutes : 0,
            streakDays: streakDays,
            averageSessionLength: averageSessionLength,
            completedSessions: completedSessions,
            perfectRecallCount: perfectRecallCount,
            lastStudyDate: activities.first?.date
        )
        
        return .success(stats)
    }
    
    public func updateStreak() async -> Result<Int, UnifiedError> {
        let streakDays = await calculateCurrentStreak()
        
        // Update current stats
        currentStats = UnifiedStudyStats(
            totalMinutes: currentStats.totalMinutes,
            thisWeekMinutes: currentStats.thisWeekMinutes,
            streakDays: streakDays,
            averageSessionLength: currentStats.averageSessionLength,
            completedSessions: currentStats.completedSessions,
            perfectRecallCount: currentStats.perfectRecallCount,
            lastStudyDate: currentStats.lastStudyDate
        )
        
        // Publish streak update event
        if let eventPublisher = DIContainer.shared.resolve((any EventPublisherProtocol).self) {
            await eventPublisher.publish(StreakUpdatedEvent(newStreakCount: streakDays))
        }
        
        return .success(streakDays)
    }
    
    // MARK: - Private Methods
    
    private func loadCurrentStats() {
        Task {
            let result = await getStats(for: .allTime)
            if case .success(let stats) = result {
                currentStats = stats
            }
        }
    }
    
    private func updateCurrentStats() async {
        let result = await getStats(for: .allTime)
        if case .success(let stats) = result {
            currentStats = stats
        }
    }
    
    private func getDateRange(for period: StatsPeriod) -> (Date, Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch period {
        case .today:
            let startOfDay = calendar.startOfDay(for: now)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? now
            return (startOfDay, endOfDay)
        case .thisWeek:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let endOfWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: startOfWeek) ?? now
            return (startOfWeek, endOfWeek)
        case .thisMonth:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) ?? now
            return (startOfMonth, endOfMonth)
        case .allTime:
            return (Date.distantPast, Date.distantFuture)
        }
    }
    
    private func calculateCurrentStreak() async -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var currentDate = today
        var streak = 0
        
        // Check each day going backwards
        for _ in 0..<365 { // Limit to 1 year
            let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            let activities = LearningActivity.fetchActivities(from: currentDate, to: nextDate, in: context)
            
            if activities.isEmpty {
                break
            }
            
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        return streak
    }
}

// MARK: - Additional Events
public struct SessionStartedEvent: AppEvent {
    public let eventId = UUID().uuidString
    public let timestamp = Date()
    public let sessionId: String
    public let activityType: ActivityType
    
    public init(sessionId: String, activityType: ActivityType) {
        self.sessionId = sessionId
        self.activityType = activityType
    }
}

public struct SessionEndedEvent: AppEvent {
    public let eventId = UUID().uuidString
    public let timestamp = Date()
    public let sessionId: String
    public let duration: TimeInterval
    
    public init(sessionId: String, duration: TimeInterval) {
        self.sessionId = sessionId
        self.duration = duration
    }
}