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
                    .tabItem { Label("記憶する", systemImage: "house.fill") }
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
            
            // 脳アイコンエフェクト
            GeometryReader { geometry in
                let isPad = UIDevice.current.userInterfaceIdiom == .pad
                let effectYPosition: CGFloat = isPad ? geometry.size.height - 1260 : geometry.size.height - 670

                if viewState.showFloatingGuide {
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .scaleEffect(1.2)
                        .position(x: geometry.size.width - 60,
                                  y: geometry.size.height - effectYPosition)
                }
            }

            // 各オーバーレイの表示
            // オンボーディング
            if viewState.isShowingOnboarding {
                OnboardingView(isShowingOnboarding: $viewState.isShowingOnboarding)
                    .background(Color(.systemBackground))
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
                    .zIndex(1)
                    .onDisappear {
                        print("🔍 オンボーディング非表示")
                        // オンボーディング非表示時に通知チェック
                        if !viewState.hasCheckedNotifications {
                            viewState.hasCheckedNotifications = true
                            viewState.checkNotificationPermission()
                        }
                    }
            }
            
            // ガイド
            if viewState.showFloatingGuide {
                FloatingGuideView(isPresented: $viewState.showFloatingGuide)
                    .zIndex(10)
                    .onAppear {
                        print("🔍 ガイド表示")
                        // 10秒後に非表示
                        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                            withAnimation {
                                viewState.showFloatingGuide = false
                                UserDefaults.standard.set(true, forKey: "hasSeenFloatingGuide")
                            }
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
                    .onDisappear {
                        print("🔍 通知許可モーダル非表示")
                        // 通知後にガイド表示
                        viewState.showGuideAfterNotification()
                    }
            }
        }
        .onAppear {
            print("🔍 MainView表示")
            if !viewState.isShowingOnboarding && !viewState.hasCheckedNotifications {
                viewState.hasCheckedNotifications = true
                viewState.checkNotificationPermission()
            }
        }
        .animation(Animation.easeInOut(duration: 0.3), value: viewState.isShowingOnboarding)
        .animation(Animation.easeInOut(duration: 0.3), value: viewState.showFloatingGuide)
    }
}

// 状態管理クラスを分離（UIの再構築でも状態を維持）
class MainViewState: ObservableObject {
    // 状態変数
    @Published var isShowingOnboarding: Bool
    @Published var showFloatingGuide = false
    @Published var showNotificationPermission = false
    @Published var hasCheckedNotifications = false
    
    init() {
        // 初期化時に1回だけUserDefaultsを読み込む
        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        print("🔍 ViewState初期化 - hasSeenOnboarding: \(hasSeenOnboarding)")
        isShowingOnboarding = !hasSeenOnboarding
    }
    
    // 通知許可をチェック
    func checkNotificationPermission() {
        print("🔍 通知許可チェック実行")
        
        // 通知が表示済みかチェック
        if !UserDefaults.standard.bool(forKey: "hasPromptedForNotifications") {
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                DispatchQueue.main.async {
                    print("🔍 通知設定: \(settings.authorizationStatus.rawValue)")
                    
                    if settings.authorizationStatus == .notDetermined {
                        print("🔍 通知未決定 -> 通知許可ダイアログを表示")
                        self.showNotificationPermission = true
                        UserDefaults.standard.set(true, forKey: "hasPromptedForNotifications")
                    } else {
                        print("🔍 通知既決定 -> ガイドへ")
                        self.showGuideAfterNotification()
                    }
                }
            }
        } else {
            print("🔍 通知プロンプト表示済み -> ガイドへ")
            self.showGuideAfterNotification()
        }
    }
    
    // 通知許可後にガイドを表示
    func showGuideAfterNotification() {
        if !UserDefaults.standard.bool(forKey: "hasSeenFloatingGuide") {
            print("🔍 ガイド表示条件OK")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    print("🔍 ガイド表示実行")
                    self.showFloatingGuide = true
                }
            }
        } else {
            print("🔍 ガイド表示済み")
        }
    }
}
