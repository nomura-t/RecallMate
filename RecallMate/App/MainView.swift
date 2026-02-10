// MainView.swift - シングルビュー（タブなし）
import SwiftUI
import CoreData
import UserNotifications

struct MainView: View {
    @EnvironmentObject var appSettings: AppSettings

    @StateObject private var viewState = MainViewState()
    @StateObject private var reviewManager = ReviewManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var showingReviewRequest = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            HomeView()
                .handleAuthCallback()

            if showingReviewRequest {
                ReviewRequestView(isPresented: $showingReviewRequest)
                    .zIndex(2)
            }

            if viewState.showNotificationPermission {
                NotificationPermissionView(isPresented: $viewState.showNotificationPermission)
                    .zIndex(3)
            }
        }
        .onAppear {
            if !viewState.isShowingOnboarding && !viewState.hasCheckedNotifications {
                viewState.hasCheckedNotifications = true
                viewState.checkNotificationPermission()
            }

            Task {
                await authManager.checkCurrentSession()
            }
        }
        .animation(Animation.easeInOut(duration: 0.3), value: viewState.isShowingOnboarding)
    }
}

// 状態管理クラス（変更なし）
// アプリケーション全体の状態を管理する中央ハブ
// オンボーディング状態と通知許可状態を追跡
class MainViewState: ObservableObject {
    @Published var isShowingOnboarding: Bool
    @Published var showNotificationPermission = false
    @Published var hasCheckedNotifications = false
    
    init() {
        // UserDefaultsからオンボーディング完了状態を取得
        // 初回起動時はfalse、以降はtrueになる
        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        isShowingOnboarding = !hasSeenOnboarding
    }
    
    /// 通知許可状態を確認し、必要に応じて許可ダイアログを表示
    /// 学習習慣の継続に重要な通知機能の有効化を促進します
    func checkNotificationPermission() {
        // 過去に通知許可を求めたことがあるかチェック
        if !UserDefaults.standard.bool(forKey: "hasPromptedForNotifications") {
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                DispatchQueue.main.async {
                    // システムレベルで通知許可が「未決定」の場合のみダイアログ表示
                    if settings.authorizationStatus == .notDetermined {
                        self.showNotificationPermission = true
                        UserDefaults.standard.set(true, forKey: "hasPromptedForNotifications")
                    }
                }
            }
        }
    }
}
