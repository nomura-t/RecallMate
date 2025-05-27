// NotificationSettingsManager.swift - 強化された通知管理システム
import Foundation
import UserNotifications
import SwiftUI

class NotificationSettingsManager: ObservableObject {
    static let shared = NotificationSettingsManager()
    
    // 通知設定の状態管理
    @Published var isNotificationEnabled: Bool = false
    @Published var streakReminderEnabled: Bool = true
    @Published var reviewReminderEnabled: Bool = true
    @Published var goalAchievementEnabled: Bool = true
    @Published var reminderFrequency: ReminderFrequency = .daily
    @Published var notificationTime: Date = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var hasSystemPermission: Bool = false
    
    private let userDefaults = UserDefaults.standard
    
    private init() {
        loadSettings()
        checkSystemPermission()
    }
    
    // 設定の読み込み
    private func loadSettings() {
        isNotificationEnabled = userDefaults.bool(forKey: "notificationEnabled")
        streakReminderEnabled = userDefaults.bool(forKey: "streakReminderEnabled")
        reviewReminderEnabled = userDefaults.bool(forKey: "reviewReminderEnabled")
        goalAchievementEnabled = userDefaults.bool(forKey: "goalAchievementEnabled")
        
        if let frequencyRaw = userDefaults.object(forKey: "reminderFrequency") as? String,
           let frequency = ReminderFrequency(rawValue: frequencyRaw) {
            reminderFrequency = frequency
        }
        
        if let timeData = userDefaults.object(forKey: "notificationTime") as? Data,
           let time = try? JSONDecoder().decode(Date.self, from: timeData) {
            notificationTime = time
        }
    }
    
    // 設定の保存
    private func saveSettings() {
        userDefaults.set(isNotificationEnabled, forKey: "notificationEnabled")
        userDefaults.set(streakReminderEnabled, forKey: "streakReminderEnabled")
        userDefaults.set(reviewReminderEnabled, forKey: "reviewReminderEnabled")
        userDefaults.set(goalAchievementEnabled, forKey: "goalAchievementEnabled")
        userDefaults.set(reminderFrequency.rawValue, forKey: "reminderFrequency")
        
        if let timeData = try? JSONEncoder().encode(notificationTime) {
            userDefaults.set(timeData, forKey: "notificationTime")
        }
    }
    
    // 全通知の有効化
    func enableNotifications() {
        requestPermissionIfNeeded { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.isNotificationEnabled = true
                    self?.saveSettings()
                    self?.scheduleAllNotifications()
                } else {
                    self?.isNotificationEnabled = false
                }
            }
        }
    }
    
    // 全通知の無効化
    func disableAllNotifications() {
        isNotificationEnabled = false
        saveSettings()
        
        // 全ての予定された通知をキャンセル
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // 通知時間の更新
    func updateNotificationTime(_ newTime: Date) {
        notificationTime = newTime
        saveSettings()
        
        if isNotificationEnabled {
            scheduleAllNotifications()
        }
    }
    
    // システム許可状態の確認
    func checkSystemPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.hasSystemPermission = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // システム許可状態の文字列表現
    var systemPermissionStatus: String {
        return hasSystemPermission ? "許可済み" : "未許可"
    }
    
    // 通知時間の文字列表現
    var formattedNotificationTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: notificationTime)
    }
    
    // システム設定を開く
    func openSystemSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    // 許可状態の更新
    func refreshPermissionStatus() {
        checkSystemPermission()
    }
    
    // 許可リクエスト（必要に応じて）
    private func requestPermissionIfNeeded(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized:
                completion(true)
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    completion(granted)
                }
            case .denied, .provisional, .ephemeral:
                completion(false)
            @unknown default:
                completion(false)
            }
        }
    }
    
    // 全通知のスケジュール（頻度設定に基づく）
    private func scheduleAllNotifications() {
        // 既存の通知をクリア
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: notificationTime)
        let minute = calendar.component(.minute, from: notificationTime)
        
        // ストリークリマインダー
        if streakReminderEnabled {
            scheduleStreakReminder(hour: hour, minute: minute)
        }
        
        // 復習リマインダー
        if reviewReminderEnabled {
            scheduleReviewReminder(hour: hour, minute: minute)
        }
        
        // 目標達成通知
        if goalAchievementEnabled {
            scheduleGoalAchievementNotification()
        }
    }
    
    // 個別の通知スケジュール機能
    private func scheduleStreakReminder(hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "学習ストリークを維持しましょう！"
        content.body = "今日の学習をして、連続学習記録を伸ばしましょう。"
        content.sound = .default
        
        // 頻度に基づいて通知をスケジュール
        switch reminderFrequency {
        case .daily:
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: "streakReminder", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
            
        case .weekdays:
            for weekday in 2...6 { // 月曜日から金曜日
                var dateComponents = DateComponents()
                dateComponents.hour = hour
                dateComponents.minute = minute
                dateComponents.weekday = weekday
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(identifier: "streakReminder_\(weekday)", content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
            }
            
        case .threeTimesWeek:
            for weekday in [2, 4, 6] { // 月、水、金
                var dateComponents = DateComponents()
                dateComponents.hour = hour
                dateComponents.minute = minute
                dateComponents.weekday = weekday
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(identifier: "streakReminder_\(weekday)", content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
            }
        }
    }
    
    private func scheduleReviewReminder(hour: Int, minute: Int) {
        // 復習リマインダーの実装
        // 復習予定のある記録に基づいた動的な通知
    }
    
    private func scheduleGoalAchievementNotification() {
        // 目標達成通知の実装
        // 学習目標の達成時に送信される通知
    }
}
