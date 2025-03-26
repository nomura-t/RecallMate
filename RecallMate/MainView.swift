import SwiftUI
import CoreData
import UserNotifications

struct MainView: View {
    @State private var isAddingMemo = false
    @State private var isRecordingActivity = false
    @State private var selectedTab = 0  // 現在選択中のタブを追跡
    @EnvironmentObject var appSettings: AppSettings
    
    // ReviewManager追加
    @StateObject private var reviewManager = ReviewManager.shared
    
    // 習慣化チャレンジマネージャー
    @StateObject private var habitChallengeManager = HabitChallengeManager.shared
    @State private var showingReviewRequest = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                /// ホーム（復習リスト）
                HomeView(isAddingMemo: $isAddingMemo)
                    .tabItem {
                        Label("ホーム", systemImage: "house.fill")
                    }
                    .tag(0)
                
                /// 学習進捗
                ActivityProgressView()
                    .tabItem {
                        Label("学習進捗", systemImage: "list.bullet.rectangle")
                    }
                    .tag(1)
                
                /// 記憶定着度
                RetentionView()
                    .tabItem {
                        Label("記憶定着度", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .tag(3)
                /// ポモドーロタイマー（新規追加）
                PomodoroView()
                    .tabItem {
                        Label("ポモドーロ", systemImage: "timer")
                    }
                    .tag(2)
                
                /// 設定
                SettingsView()
                    .environmentObject(appSettings)
                    .tabItem {
                        Label("設定", systemImage: "gearshape.fill")
                    }
                    .tag(4)
            }
            // フルスクリーンカバーを明示的に追加
            .fullScreenCover(isPresented: $isAddingMemo) {
                ContentView(memo: nil)
            }
            
            // レビュー誘導モーダル
            if showingReviewRequest {
                ReviewRequestView(isPresented: $showingReviewRequest)
                    .zIndex(2) // 他のモーダルより前面に表示
            }
        }
        .onChange(of: isAddingMemo) { oldValue, newValue in
            // デバッグ用
            print("🔄 isAddingMemo: \(oldValue) → \(newValue)")
        }
        .onChange(of: reviewManager.shouldShowReview) { oldValue, newValue in
            if newValue {
                showingReviewRequest = true
                reviewManager.shouldShowReview = false // リセット
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("StartPomodoroFromNotification"))) { _ in
            // 通知からポモドーロを開始する処理
            selectedTab = 2 // ポモドーロタブに切り替え
            // 必要に応じてPomodoroTimerを操作するコードを追加
        }
    }
    // アプリがフォアグラウンドに戻ってきたときに習慣化チャレンジをチェック
    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
        // 習慣化チャレンジの進捗をチェック
        DispatchQueue.main.async {
            habitChallengeManager.checkDailyProgress()
        }
    }
}
