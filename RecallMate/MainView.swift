// MainView.swift（修正版） - FloatingAddButtonの削除
import SwiftUI
import CoreData
import UserNotifications

struct MainView: View {
    @State private var isAddingMemo = false // この変数は残しますが、新規学習フローで使用しません
    @State private var isRecordingActivity = false
    @State private var selectedTab = 0
    @EnvironmentObject var appSettings: AppSettings

    @StateObject private var viewState = MainViewState()
    @StateObject private var reviewManager = ReviewManager.shared
    @State private var showingReviewRequest = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                // HomeViewからisAddingMemoバインディングを削除し、ダミー値を渡します
                HomeView(isAddingMemo: $isAddingMemo) // バインディングは残しますが使用しません
                    .tabItem { Label("記録する", systemImage: "brain.head.profile") }
                    .tag(0)
                ActivityProgressView()
                    .tabItem { Label("振り返り", systemImage: "list.bullet.rectangle") }
                    .tag(1)
                PomodoroView()
                    .tabItem { Label("集中タイマー", systemImage: "timer") }
                    .tag(2)
                SettingsView()
                    .environmentObject(appSettings)
                    .tabItem { Label("設定", systemImage: "gearshape.fill") }
                    .tag(4)
            }
            // .fullScreenCover(isPresented: $isAddingMemo) の削除
            // FloatingAddButtonも削除されています

            // レビューモーダル
            if showingReviewRequest {
                ReviewRequestView(isPresented: $showingReviewRequest)
                    .zIndex(2)
            }
            
            // 通知許可モーダル
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
        }
        .animation(Animation.easeInOut(duration: 0.3), value: viewState.isShowingOnboarding)
    }
}


// 状態管理クラス（変更なし）
class MainViewState: ObservableObject {
    @Published var isShowingOnboarding: Bool
    @Published var showNotificationPermission = false
    @Published var hasCheckedNotifications = false
    
    init() {
        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        isShowingOnboarding = !hasSeenOnboarding
    }
    
    func checkNotificationPermission() {
        if !UserDefaults.standard.bool(forKey: "hasPromptedForNotifications") {
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                DispatchQueue.main.async {
                    if settings.authorizationStatus == .notDetermined {
                        self.showNotificationPermission = true
                        UserDefaults.standard.set(true, forKey: "hasPromptedForNotifications")
                    }
                }
            }
        }
    }
}
