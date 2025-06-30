// AppDelegate.swift - ポモドーロタイマー関連のコードを削除
import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    // アプリ起動時の処理
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 通知デリゲートを設定
        UNUserNotificationCenter.current().delegate = self
        
        // ポモドーロタイマー関連の通知カテゴリ設定を削除
        // 代わりに基本的な通知設定のみ保持
        
        return true
    }
    
    // 通知アクションのハンドリング - ポモドーロ関連を削除
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // ポモドーロ関連のアクションハンドリングを削除
        // 他の通知処理があれば、ここに追加
        
        completionHandler()
    }
    
    // フォアグラウンドでの通知表示
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // フォアグラウンドでも通知を表示
        completionHandler([.banner, .sound])
    }
}
