import SwiftUI

@main
struct RecallMateApp: App {
    // AppDelegateを登録
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    let persistenceController = PersistenceController.shared
    
    // appSettings を宣言
    @StateObject private var appSettings = AppSettings()
    
    // オンボーディング表示状態
    @State private var isShowingOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    //開発環境だけあとで削除
//    @State private var isShowingOnboarding = true // 開発中は常にtrueに設定

    
    init() {
        // アプリ起動時にストリークを確認・更新
        StreakTracker.shared.checkAndUpdateStreak(in: persistenceController.container.viewContext)
        
        // ユーザーの使用時間に基づいて通知時間を更新
        StreakNotificationManager.shared.updatePreferredTime()
        
        // ストリーク維持のための通知をスケジュール
        StreakNotificationManager.shared.scheduleStreakReminder()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(appSettings)
                    .onReceive(NotificationCenter.default.publisher(for: Notification.Name("StartPomodoroFromNotification"))) { _ in
                        // 通知からポモドーロを開始する処理をここに書くこともできます
                        // 例: ポモドーロタブに移動する、など
                    }
                
                // オンボーディング画面をフルスクリーンで表示
                if isShowingOnboarding {
                    OnboardingView(isShowingOnboarding: $isShowingOnboarding)
                        .background(Color(.systemBackground)) // 背景色を追加
                        .edgesIgnoringSafeArea(.all) // 画面全体に広げる
                        .transition(.opacity)
                        .zIndex(1) // 最前面に表示
                }
            }
            .animation(Animation.easeInOut(duration: 0.3), value: isShowingOnboarding)
        }
    }
}
