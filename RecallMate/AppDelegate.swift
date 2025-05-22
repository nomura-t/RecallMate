// AppDelegate.swift
import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    // アプリ起動時の処理
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // iOS 13.0以降では、setMinimumBackgroundFetchIntervalは非推奨
        // 代わりにBackgroundTasksフレームワークを使用することが推奨されますが、
        // シンプルなアプリではこの設定は削除して問題ありません
        
        // 通知デリゲートを設定
        UNUserNotificationCenter.current().delegate = self
        
        // ローカル通知のカテゴリを設定
        let startAction = UNNotificationAction(identifier: "START_ACTION", title: "次のセッションを開始", options: .foreground)
        let category = UNNotificationCategory(identifier: "pomodoroTimer", actions: [startAction], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
        
        return true
    }
    
    // 非推奨のバックグラウンドフェッチメソッドを削除
    // func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    
    // 通知アクションのハンドリング
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == "START_ACTION" {
            // 次のセッションを開始する処理
            NotificationCenter.default.post(name: Notification.Name("StartPomodoroFromNotification"), object: nil)
        }
        
        completionHandler()
    }
    
    // フォアグラウンドでの通知表示
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // フォアグラウンドでも通知を表示
        completionHandler([.banner, .sound])
    }
}
