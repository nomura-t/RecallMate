// MainView.swift（修正版）
import SwiftUI
import CoreData
import UserNotifications

struct MainView: View {
    @State private var isAddingMemo = false
    @State private var isRecordingActivity = false
    @State private var selectedTab = 0
    @EnvironmentObject var appSettings: AppSettings

    // StateObjectに変更して永続化（再初期化防止）
    @StateObject private var viewState = MainViewState()
    
    // ReviewManagerなど
    @StateObject private var reviewManager = ReviewManager.shared
    @StateObject private var habitChallengeManager = HabitChallengeManager.shared
    @State private var showingReviewRequest = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                // 各タブの定義（変更なし）
                HomeView(isAddingMemo: $isAddingMemo)
                    .tabItem { Label("記憶する", systemImage: "brain.head.profile") }
                    .tag(0)
                ActivityProgressView()
                    .tabItem { Label("振り返り", systemImage: "list.bullet.rectangle") }
                    .tag(1)
                RetentionView()
                    .tabItem { Label("記憶定着度", systemImage: "chart.line.uptrend.xyaxis") }
                    .tag(3)
                PomodoroView()
                    .tabItem { Label("集中タイマー", systemImage: "timer") }
                    .tag(2)
                SettingsView()
                    .environmentObject(appSettings)
                    .tabItem { Label("設定", systemImage: "gearshape.fill") }
                    .tag(4)
            }
            .fullScreenCover(isPresented: $isAddingMemo) {
                ContentView(memo: nil)
            }
            

            // オンボーディング
            if viewState.isShowingOnboarding {
                OnboardingView(isShowingOnboarding: $viewState.isShowingOnboarding)
                    .background(Color(.systemBackground))
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
                    .zIndex(1)
                    .onDisappear {
                        // オンボーディング非表示時に通知チェック
                        if !viewState.hasCheckedNotifications {
                            viewState.hasCheckedNotifications = true
                            viewState.checkNotificationPermission()
                        }
                    }
            }


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

// 状態管理クラスを分離（UIの再構築でも状態を維持）
class MainViewState: ObservableObject {
    // 状態変数
    @Published var isShowingOnboarding: Bool
    @Published var showNotificationPermission = false
    @Published var hasCheckedNotifications = false
    
    init() {
        // 初期化時に1回だけUserDefaultsを読み込む
        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        isShowingOnboarding = !hasSeenOnboarding
    }
    
    // 通知許可をチェック
    func checkNotificationPermission() {
        
        // 通知が表示済みかチェック
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
