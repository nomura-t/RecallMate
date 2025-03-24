// StreakNotificationManager.swift
import Foundation
import UserNotifications

class StreakNotificationManager {
    static let shared = StreakNotificationManager()
    
    private let defaults = UserDefaults.standard
    private let preferredTimeKey = "preferredNotificationTime"
    
    private init() {
        requestNotificationPermission()
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ 通知許可を取得しました")
            } else if let error = error {
                print("❌ 通知許可エラー: \(error.localizedDescription)")
            }
        }
    }
    
    // 現在時刻をベースに通知時間を設定・保存する
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
            print("✅ 通知時間を更新: \(hour):\(minute)")
            
            // 既存の通知をキャンセルして再スケジュール
            rescheduleNotification()
        }
    }
    
    // 保存された時間に基づいて通知をスケジュール
    func scheduleStreakReminder() {
        guard let timeData = defaults.data(forKey: preferredTimeKey),
              let timeComponents = try? JSONDecoder().decode(DateComponents.self, from: timeData) else {
            // 保存された時間がない場合は現在時刻を使用
            updatePreferredTime()
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "ストリークを維持しましょう！"
        content.body = "今日の復習をして、連続学習記録を伸ばしましょう。"
        content.sound = .default
        
        // 保存された時間で通知を設定
        var dateComponents = DateComponents()
        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "streakReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 通知スケジュールエラー: \(error.localizedDescription)")
            } else {
                let hourStr = String(format: "%02d", timeComponents.hour ?? 0)
                let minuteStr = String(format: "%02d", timeComponents.minute ?? 0)
                print("✅ 通知をスケジュール: \(hourStr):\(minuteStr)")
            }
        }
    }
    
    // 既存の通知をキャンセルして再スケジュール
    private func rescheduleNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["streakReminder"])
        scheduleStreakReminder()
    }
    
    // 現在設定されている通知時間を文字列で取得
    func getPreferredTimeString() -> String {
        guard let timeData = defaults.data(forKey: preferredTimeKey),
              let timeComponents = try? JSONDecoder().decode(DateComponents.self, from: timeData) else {
            return "未設定"
        }
        
        let hourStr = String(format: "%02d", timeComponents.hour ?? 0)
        let minuteStr = String(format: "%02d", timeComponents.minute ?? 0)
        return "\(hourStr):\(minuteStr)"
    }
}
