// MainView.swift（修正版） - 作業記録タブを追加
import SwiftUI
import CoreData
import UserNotifications

struct MainView: View {
    @State private var isAddingMemo = false // この変数は残しますが、新規学習フローで使用しません
    @State private var isRecordingActivity = false
    @State private var selectedTab = 0 // デフォルトは復習管理タブ
    @EnvironmentObject var appSettings: AppSettings

    @StateObject private var viewState = MainViewState()
    @StateObject private var reviewManager = ReviewManager.shared
    @State private var showingReviewRequest = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                // タブ1: 復習管理 - 既存の学習記録の復習を管理
                // ユーザーが既に作成した記録を効率的に復習できる機能
                HomeView(isAddingMemo: $isAddingMemo)
                    .tabItem {
                        Label("復習管理".localized, systemImage: "brain.head.profile")
                    }
                    .tag(0)
                
                // タブ2: 作業記録 - 新しく追加する機能
                // リアルタイムでの作業時間記録とタイマー管理を提供
                // 既存の復習管理とは独立した、新しい学習サイクルの開始点
                WorkTimerView()
                    .tabItem {
                        Label("作業記録".localized, systemImage: "timer")
                    }
                    .tag(1)
                
                // タブ3: 振り返り - 統計情報とアクティビティ分析
                // 復習記録と作業記録の両方を統合した包括的な分析を提供
                // タグ番号を1から2に変更（作業記録タブの挿入による）
                ActivityProgressView()
                    .tabItem {
                        Label("振り返り".localized, systemImage: "list.bullet.rectangle")
                    }
                    .tag(2)
                
                // タブ4: 設定 - アプリケーションの個人設定
                // 通知設定、表示設定、データ管理などの機能
                // タグ番号を2から3に変更
                SettingsView()
                    .environmentObject(appSettings)
                    .tabItem {
                        Label("設定".localized, systemImage: "gearshape.fill")
                    }
                    .tag(3)
            }
            // TabViewの外観カスタマイズ
            // iOS 15以降のタブバーの透明化に対応し、一貫した見た目を提供
            .onAppear {
                setupTabBarAppearance()
            }

            // レビューモーダル - アプリ評価依頼のポップアップ
            // ユーザーの学習進捗に基づいて適切なタイミングで表示
            if showingReviewRequest {
                ReviewRequestView(isPresented: $showingReviewRequest)
                    .zIndex(2)
            }
            
            // 通知許可モーダル - 初回起動時の通知許可依頼
            // 学習習慣の継続をサポートするための重要な機能
            if viewState.showNotificationPermission {
                NotificationPermissionView(isPresented: $viewState.showNotificationPermission)
                    .zIndex(3)
            }
        }
        .onAppear {
            // アプリ初回起動時の初期化処理
            // 通知許可の確認と基本設定の準備
            if !viewState.isShowingOnboarding && !viewState.hasCheckedNotifications {
                viewState.hasCheckedNotifications = true
                viewState.checkNotificationPermission()
            }
        }
        .animation(Animation.easeInOut(duration: 0.3), value: viewState.isShowingOnboarding)
    }
    
    /// タブバーの外観を設定する関数
    /// iOS 15以降で変更されたタブバーの透明化挙動に対応し、
    /// 一貫したユーザー体験を提供するための重要な設定です
    private func setupTabBarAppearance() {
        if #available(iOS 15.0, *) {
            // iOS 15以降の新しいTabBar外観API使用
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            
            // 背景色の設定 - システムの背景色を使用
            tabBarAppearance.backgroundColor = UIColor.systemBackground
            
            // 選択状態と非選択状態のアイテム色を設定
            tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
            tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor.systemBlue
            ]
            
            // すべてのタブバーに統一された外観を適用
            UITabBar.appearance().standardAppearance = tabBarAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
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
