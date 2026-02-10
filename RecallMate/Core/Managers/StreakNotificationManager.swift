// StreakNotificationManager.swift
import Foundation
import UserNotifications
import CoreData

class StreakNotificationManager {
    static let shared = StreakNotificationManager()

    private let defaults = UserDefaults.standard
    private let preferredTimeKey = "preferredNotificationTime"

    private init() {
        requestNotificationPermission()
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func disableNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            "streakReminder",
            "streakMorningMotivation",
            "streakNightWarning"
        ])
    }

    // MARK: - Time Management

    func updatePreferredTime() {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)

        var timeComponents = DateComponents()
        timeComponents.hour = hour
        timeComponents.minute = minute

        if let timeData = try? JSONEncoder().encode(timeComponents) {
            defaults.set(timeData, forKey: preferredTimeKey)
            rescheduleNotification()
        }
    }

    func getPreferredTimeString() -> String {
        guard let timeData = defaults.data(forKey: preferredTimeKey),
              let timeComponents = try? JSONDecoder().decode(DateComponents.self, from: timeData) else {
            return "未設定"
        }

        let hourStr = String(format: "%02d", timeComponents.hour ?? 0)
        let minuteStr = String(format: "%02d", timeComponents.minute ?? 0)
        return "\(hourStr):\(minuteStr)"
    }

    // MARK: - Schedule All Notifications

    func scheduleStreakReminder() {
        scheduleUserPreferredReminder()
        scheduleMorningMotivation()
        scheduleNightWarning()
    }

    private func rescheduleNotification() {
        disableNotifications()
        scheduleStreakReminder()
    }

    // MARK: - User Preferred Time Reminder

    private func scheduleUserPreferredReminder() {
        guard let timeData = defaults.data(forKey: preferredTimeKey),
              let timeComponents = try? JSONDecoder().decode(DateComponents.self, from: timeData) else {
            updatePreferredTime()
            return
        }

        let streakCount = getCurrentStreakCount()

        let content = UNMutableNotificationContent()
        content.title = "ストリークを維持しましょう！".localized
        if streakCount > 0 {
            content.body = String(format: "%d日連続学習中！今日の復習をして記録を伸ばしましょう。".localized, streakCount)
        } else {
            content.body = "今日の復習をして、連続学習記録を始めましょう。".localized
        }
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "streakReminder", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { _ in }
    }

    // MARK: - Morning Motivation (8:00)

    private func scheduleMorningMotivation() {
        let streakCount = getCurrentStreakCount()
        guard streakCount > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = String(format: "%d日連続学習中！".localized, streakCount)
        content.body = "今日も記録を伸ばしましょう".localized
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "streakMorningMotivation", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { _ in }
    }

    // MARK: - Night Warning (22:00)

    private func scheduleNightWarning() {
        let streakCount = getCurrentStreakCount()
        guard streakCount > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "ストリークが途切れそうです！".localized
        content.body = String(format: "%d日連続の記録が今日で途切れます。あと2時間です！".localized, streakCount)
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 22
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "streakNightWarning", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { _ in }
    }

    // MARK: - Streak Broken Notification

    func notifyStreakBroken() {
        let content = UNMutableNotificationContent()
        content.title = "ストリークが途切れました".localized
        content.body = "今日から新しいストリークを始めましょう！".localized
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "streakBroken", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { _ in }
    }

    // MARK: - Cancel Tonight's Warning (When User Has Studied)

    func cancelNightWarningIfStudied() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["streakNightWarning"])
    }

    // MARK: - Helper

    private func getCurrentStreakCount() -> Int {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest = NSFetchRequest<StreakData>(entityName: "StreakData")

        do {
            let results = try context.fetch(fetchRequest)
            return Int(results.first?.currentStreak ?? 0)
        } catch {
            return 0
        }
    }
}
