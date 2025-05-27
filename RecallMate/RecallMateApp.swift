// RecallMateApp.swift - サンプル記録作成機能を削除
import SwiftUI
import CoreData

@main
struct RecallMateApp: App {
    // AppDelegateを登録
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    let persistenceController = PersistenceController.shared
    
    // appSettings を宣言
    @StateObject private var appSettings = AppSettings()
    
    // オンボーディング表示状態
    @State private var isShowingOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    
    init() {
        // アプリ起動時にストリークを確認・更新
        // これは学習習慣の継続性を追跡するために重要な機能です
        StreakTracker.shared.checkAndUpdateStreak(in: persistenceController.container.viewContext)
        
        // ユーザーの使用時間に基づいて通知時間を更新
        // 実際の使用パターンに合わせて通知タイミングを最適化します
        StreakNotificationManager.shared.updatePreferredTime()
        
        // ストリーク維持のための通知をスケジュール
        // 学習習慣の継続をサポートする重要な機能です
        StreakNotificationManager.shared.scheduleStreakReminder()
        
        // サンプル記録作成機能を完全に削除
        // ユーザーは真っ新な状態からアプリを使い始めることができます
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(appSettings)
            }
        }
    }
}
