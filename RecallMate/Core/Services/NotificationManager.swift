import Foundation
import Supabase
import UIKit

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var notifications: [SocialNotification] = []
    @Published var unreadCount: Int = 0
    
    private init() {}
    
    // MARK: - Public Methods
    
    func loadNotifications() async {
        // 一時的な実装 - 実際のSupabaseクエリは後で実装
        notifications = []
        unreadCount = 0
    }
    
    func markAsRead(_ notificationId: String) async {
        // 一時的な実装
        if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
            notifications[index].isRead = true
            calculateUnreadCount()
        }
    }
    
    func markAllAsRead() async {
        // 一時的な実装
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        calculateUnreadCount()
    }
    
    func deleteNotification(_ notificationId: String) async {
        // 一時的な実装
        notifications.removeAll { $0.id == notificationId }
        calculateUnreadCount()
    }
    
    func sendNotification(to userId: String, type: NotificationType, data: [String: String]) async {
        // 一時的な実装 - 実際のSupabaseクエリは後で実装
    }
    
    func startListening() async {
        // 一時的な実装 - Realtimeリスナーは後で実装
    }
    
    func stopListening() {
        // 一時的な実装
    }
    
    func refreshNotifications() async {
        await loadNotifications()
    }
    
    func getNotifications() -> [SocialNotification] {
        return notifications
    }
    
    func getUnreadNotifications() -> [SocialNotification] {
        return notifications.filter { !$0.isRead }
    }
    
    func getNotifications(ofType type: NotificationType) -> [SocialNotification] {
        return notifications.filter { $0.type == type }
    }
    
    // MARK: - Private Methods
    
    private func calculateUnreadCount() {
        unreadCount = notifications.filter { !$0.isRead }.count
    }
}

// MARK: - Supporting Types

struct SocialNotification: Identifiable, Codable {
    let id: String
    let type: NotificationType
    let title: String
    let message: String
    let userId: String
    let createdAt: Date
    var isRead: Bool
    let data: [String: String]
}

