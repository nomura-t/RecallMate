import Foundation

// MARK: - Firebase Analytics Service
/// Firebase Analyticsを使用した分析サービスの実装
public class FirebaseAnalyticsService: AnalyticsServiceProtocol {
    
    private let maxParameterLength = 100
    private let maxEventNameLength = 40
    
    public init() {}
    
    // MARK: - AnalyticsServiceProtocol
    
    public func trackEvent(_ event: AnalyticsEvent) async {
        // Validate event name length
        let eventName = String(event.name.prefix(maxEventNameLength))
        
        // Sanitize and validate parameters
        var sanitizedParameters: [String: Any] = [:]
        for (key, value) in event.parameters {
            let sanitizedKey = sanitizeParameterKey(key)
            let sanitizedValue = sanitizeParameterValue(value)
            sanitizedParameters[sanitizedKey] = sanitizedValue
        }
        
        // Add timestamp
        sanitizedParameters["timestamp"] = event.timestamp.timeIntervalSince1970
        
        // TODO: Implement actual Firebase Analytics tracking
        // For now, just log to console
        print("📊 Analytics Event: \(eventName)")
        print("📊 Parameters: \(sanitizedParameters)")
        
        // In production, this would be:
        // Analytics.logEvent(eventName, parameters: sanitizedParameters)
    }
    
    public func trackScreenView(_ screenName: String) async {
        let sanitizedScreenName = String(screenName.prefix(maxParameterLength))
        
        await trackEvent(AnalyticsEvent(
            name: "screen_view",
            parameters: [
                "screen_name": sanitizedScreenName,
                "screen_class": sanitizedScreenName
            ]
        ))
    }
    
    public func trackUserProperty(key: String, value: String) async {
        let sanitizedKey = sanitizeParameterKey(key)
        let sanitizedValue = String(value.prefix(maxParameterLength))
        
        // TODO: Implement actual Firebase Analytics user property
        // For now, just log to console
        print("📊 User Property: \(sanitizedKey) = \(sanitizedValue)")
        
        // In production, this would be:
        // Analytics.setUserProperty(sanitizedValue, forName: sanitizedKey)
    }
    
    public func setUserId(_ userId: String) async {
        let sanitizedUserId = String(userId.prefix(maxParameterLength))
        
        // TODO: Implement actual Firebase Analytics user ID
        // For now, just log to console
        print("📊 User ID: \(sanitizedUserId)")
        
        // In production, this would be:
        // Analytics.setUserID(sanitizedUserId)
    }
    
    // MARK: - Private Methods
    
    private func sanitizeParameterKey(_ key: String) -> String {
        // Remove invalid characters and limit length
        let sanitized = key
            .replacingOccurrences(of: " ", with: "_")
            .lowercased()
            .filter { $0.isLetter || $0.isNumber || $0 == "_" }
        
        return String(sanitized.prefix(maxParameterLength))
    }
    
    private func sanitizeParameterValue(_ value: Any) -> Any {
        switch value {
        case let stringValue as String:
            return String(stringValue.prefix(maxParameterLength))
        case let numberValue as NSNumber:
            return numberValue
        case let boolValue as Bool:
            return boolValue
        default:
            return String(describing: value).prefix(maxParameterLength)
        }
    }
}

// MARK: - Predefined Analytics Events
public extension AnalyticsEvent {
    
    // App Events
    static func appLaunch() -> AnalyticsEvent {
        return AnalyticsEvent(name: "app_launch")
    }
    
    static func appBackground() -> AnalyticsEvent {
        return AnalyticsEvent(name: "app_background")
    }
    
    // Authentication Events
    static func userSignIn(method: String) -> AnalyticsEvent {
        return AnalyticsEvent(name: "user_sign_in", parameters: ["method": method])
    }
    
    static func userSignUp(method: String) -> AnalyticsEvent {
        return AnalyticsEvent(name: "user_sign_up", parameters: ["method": method])
    }
    
    static func userSignOut() -> AnalyticsEvent {
        return AnalyticsEvent(name: "user_sign_out")
    }
    
    // Memo Events
    static func memoCreated(category: String? = nil) -> AnalyticsEvent {
        var parameters: [String: Any] = [:]
        if let category = category {
            parameters["category"] = category
        }
        return AnalyticsEvent(name: "memo_created", parameters: parameters)
    }
    
    static func memoUpdated(category: String? = nil) -> AnalyticsEvent {
        var parameters: [String: Any] = [:]
        if let category = category {
            parameters["category"] = category
        }
        return AnalyticsEvent(name: "memo_updated", parameters: parameters)
    }
    
    static func memoDeleted() -> AnalyticsEvent {
        return AnalyticsEvent(name: "memo_deleted")
    }
    
    // Review Events
    static func reviewStarted(memoCount: Int) -> AnalyticsEvent {
        return AnalyticsEvent(name: "review_started", parameters: ["memo_count": memoCount])
    }
    
    static func reviewCompleted(score: Int, timeSpent: TimeInterval) -> AnalyticsEvent {
        return AnalyticsEvent(name: "review_completed", parameters: [
            "score": score,
            "time_spent": Int(timeSpent)
        ])
    }
    
    static func reviewSkipped() -> AnalyticsEvent {
        return AnalyticsEvent(name: "review_skipped")
    }
    
    // Learning Activity Events
    static func learningSessionStarted(activityType: ActivityType) -> AnalyticsEvent {
        return AnalyticsEvent(name: "learning_session_started", parameters: [
            "activity_type": activityType.rawValue
        ])
    }
    
    static func learningSessionEnded(activityType: ActivityType, duration: TimeInterval) -> AnalyticsEvent {
        return AnalyticsEvent(name: "learning_session_ended", parameters: [
            "activity_type": activityType.rawValue,
            "duration_minutes": Int(duration / 60)
        ])
    }
    
    // Social Events
    static func friendRequestSent() -> AnalyticsEvent {
        return AnalyticsEvent(name: "friend_request_sent")
    }
    
    static func friendRequestAccepted() -> AnalyticsEvent {
        return AnalyticsEvent(name: "friend_request_accepted")
    }
    
    static func groupJoined(groupSize: Int) -> AnalyticsEvent {
        return AnalyticsEvent(name: "group_joined", parameters: ["group_size": groupSize])
    }
    
    static func groupLeft() -> AnalyticsEvent {
        return AnalyticsEvent(name: "group_left")
    }
    
    // Settings Events
    static func settingsChanged(setting: String, value: String) -> AnalyticsEvent {
        return AnalyticsEvent(name: "settings_changed", parameters: [
            "setting": setting,
            "value": value
        ])
    }
    
    // Performance Events
    static func syncStarted() -> AnalyticsEvent {
        return AnalyticsEvent(name: "sync_started")
    }
    
    static func syncCompleted(duration: TimeInterval, success: Bool) -> AnalyticsEvent {
        return AnalyticsEvent(name: "sync_completed", parameters: [
            "duration": Int(duration),
            "success": success
        ])
    }
    
    // Error Events
    static func errorOccurred(error: String, context: String) -> AnalyticsEvent {
        return AnalyticsEvent(name: "error_occurred", parameters: [
            "error": error,
            "context": context
        ])
    }
}