// SettingsView.swift
import SwiftUI
import Foundation
import UserNotifications

struct SettingsView: View {
    @State private var notificationEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
    @State private var currentNotificationTime = ""
    
    // 設定クラスをEnvironmentObjectとして追加
    @EnvironmentObject private var appSettings: AppSettings
    
    // シェア関連の状態変数
    @State private var isShareSheetPresented = false
    @State private var showMissingAppAlert = false
    @State private var missingAppName = ""
    @State private var shareText = "RecallMateアプリを使って科学的に記憶力を強化しています。長期記憶の定着に最適なアプリです！ https://apps.apple.com/app/recallmate/id6744206597" // 実際のApp StoreリンクIDに変更する
    @State private var showNotificationPermission = false
    @State private var showSocialShareView = false // ソーシャルシェアビュー表示用状態変数を追加
    @StateObject private var notificationObserver = NotificationSettingsObserver()
    @State private var showAppInfoView = false

    var body: some View {
        NavigationStack {
            Form {
                // 「このアプリについて」セクションを追加
                Section(header: Text("アプリ情報")) {
                    NavigationLink(destination: AppInfoView()) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.blue)
                                .font(.system(size: 22))
                                .frame(width: 30)
                            
                            Text("このアプリについて")
                                .font(.headline)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // 開発者のTwitterリンクを追加
                    Button(action: {
                        openTwitterProfile()
                    }) {
                        HStack {
                            Image(systemName: "person.crop.circle")
                                .foregroundColor(.blue)
                                .font(.system(size: 22))
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("開発者に言いたいことを言おう！")
                                    .font(.headline)
                                
                                Text("@ttttttt12345654")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.blue)
                                .font(.system(size: 16))
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // アプリを共有セクション
                Section {
                    HStack(alignment: .center) {
                        // テキスト部分
                        VStack(alignment: .leading, spacing: 4) {
                            Text("RecallMateを友達に紹介する")
                                .font(.headline)
                            
                            Text("効率的な学習方法を友達にも教えてあげましょう")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // シェアボタン - 修正部分
                        Button(action: {
                            showSocialShareView = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 30))
                                .foregroundColor(.blue)
                                .frame(width: 40, height: 40)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("アプリを共有")
                }
                
                Section(header: Text("一般設定")) {
                    // SettingsView.swift の修正版（Toggle部分のみ）
                    Toggle("通知を有効にする", isOn: Binding<Bool>(
                        get: {
                            self.notificationEnabled
                        },
                        set: { newValue in
                            if newValue {
                                // 通知を有効化しようとしている場合
                                // トグルの値はまだ変更せず、モーダルを表示
                                showNotificationPermission = true
                            } else {
                                // 通知を無効化する場合
                                self.notificationEnabled = false
                                UserDefaults.standard.set(false, forKey: "notificationsEnabled")
                                self.cancelAllNotifications()
                                StreakNotificationManager.shared.disableNotifications()
                                
                                // iOS設定アプリの通知設定画面に遷移
                                openAppNotificationSettings()
                            }
                        }
                    ))
                }
                
                Section(header: Text("通知設定")) {
                    HStack {
                        Text("現在の通知時間:")
                        Spacer()
                        Text(StreakNotificationManager.shared.getPreferredTimeString())
                            .foregroundColor(.gray)
                    }
                    
                    Button("現在時刻を通知時間に設定") {
                        StreakNotificationManager.shared.updatePreferredTime()
                        // ビューを更新するために現在の通知時間を取得
                        currentNotificationTime = StreakNotificationManager.shared.getPreferredTimeString()
                    }
                }
                .disabled(!notificationEnabled)
            }
            .navigationTitle("")
            .sheet(isPresented: $isShareSheetPresented) {
                if #available(iOS 16.0, *) {
                    ShareSheet(text: shareText)
                } else {
                    LegacyShareSheet(text: shareText)
                }
            }
            .alert(isPresented: $showMissingAppAlert) {
                Alert(
                    title: Text("\(missingAppName)がインストールされていません"),
                    message: Text("共有するには\(missingAppName)アプリをインストールしてください。"),
                    dismissButton: .default(Text("OK"))
                )
            }
            // ソーシャルシェアビューをオーバーレイとして表示
            .overlay(
                Group {
                    if showSocialShareView {
                        SocialShareView(
                            isPresented: $showSocialShareView,
                            shareText: shareText
                        )
                        .transition(.opacity)
                        .animation(.easeInOut, value: showSocialShareView)
                    }
                }
            )
            .onAppear {
                // 最初にUserDefaultsから設定を取得
                self.notificationEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
                
                // 次に、現在の通知許可状態を確認して表示を更新
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    DispatchQueue.main.async {
                        // システムの通知設定とUserDefaultsの設定を同期させる
                        let isEnabled = settings.authorizationStatus == .authorized
                        self.notificationEnabled = isEnabled
                        UserDefaults.standard.set(isEnabled, forKey: "notificationsEnabled")
                    }
                }
                
                // ビューが表示されるたびに現在の通知時間を更新
                currentNotificationTime = StreakNotificationManager.shared.getPreferredTimeString()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // フォアグラウンドに戻ってきたときに通知設定を確認
            checkNotificationSettings()
        }
        .onAppear {
            // 画面表示時も通知設定を確認
            checkNotificationSettings()
        }

        // モーダル表示を追加
        .overlay(
            Group {
                if showNotificationPermission {
                    NotificationPermissionView(
                        isPresented: $showNotificationPermission,
                        onPermissionGranted: {
                            // 許可された場合の処理
                            self.notificationEnabled = true
                            UserDefaults.standard.set(true, forKey: "notificationsEnabled")
                        },
                        onPermissionDenied: {
                            // キャンセルされた場合の処理
                            self.notificationEnabled = false
                            UserDefaults.standard.set(false, forKey: "notificationsEnabled")
                        }
                    )
                    .transition(.opacity)
                    .animation(.easeInOut, value: showNotificationPermission)
                }
            }
        )
    }
    
    // Twitterプロフィールを開くメソッドを追加
    private func openTwitterProfile() {
        // Twitterアプリを優先的に開き、なければWebブラウザで開く
        let twitterAppURL = URL(string: "twitter://user?screen_name=ttttttt12345654")!
        let twitterWebURL = URL(string: "https://x.com/ttttttt12345654")!
        
        if UIApplication.shared.canOpenURL(twitterAppURL) {
            UIApplication.shared.open(twitterAppURL)
        } else {
            UIApplication.shared.open(twitterWebURL)
        }
    }
    
    // 通知設定を確認して画面を更新する関数
    private func checkNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                // システムの通知許可状態をトグルに反映
                self.notificationEnabled = settings.authorizationStatus == .authorized
                // UserDefaultsも同期して保存
                UserDefaults.standard.set(self.notificationEnabled, forKey: "notificationsEnabled")
                // 通知が許可された場合は必要な通知をスケジュール
                if self.notificationEnabled {
                    StreakNotificationManager.shared.scheduleStreakReminder()
                }
            }
        }
    }
    // LINEで共有
    func shareAppViaLINE() {
        let encodedText = shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let lineURL = URL(string: "https://line.me/R/msg/text/?\(encodedText)")!
        
        if UIApplication.shared.canOpenURL(lineURL) {
            UIApplication.shared.open(lineURL)
        } else {
            // LINEアプリがインストールされていない場合
            showAlertForMissingApp(name: "LINE")
        }
    }
    
    // システム共有シート
    func showShareSheet() {
        isShareSheetPresented = true
    }
    
    // アプリがインストールされていない場合のアラート
    func showAlertForMissingApp(name: String) {
        missingAppName = name
        showMissingAppAlert = true
    }
    
    // 全ての通知をキャンセル
    private func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    // 通知許可をリクエスト
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                // 許可されなかった場合はトグルを戻す
                if !granted {
                    self.notificationEnabled = false
                    UserDefaults.standard.set(false, forKey: "notificationsEnabled")
                } else {
                    self.notificationEnabled = true
                    UserDefaults.standard.set(true, forKey: "notificationsEnabled")
                    
                    // 通知が許可されたので、通知をスケジュール
                    StreakNotificationManager.shared.scheduleStreakReminder()
                }
            }
        }
    }
    public func openAppNotificationSettings() {
        // iOS 16以降の場合は通知設定画面に直接遷移
        if #available(iOS 16.0, *) {
            if let bundleId = Bundle.main.bundleIdentifier,
               let url = URL(string: UIApplication.openNotificationSettingsURLString + "?bundleIdentifier=\(bundleId)") {
                UIApplication.shared.open(url)
            }
        } else {
            // iOS 16未満の場合は設定アプリを開く
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        }
    }
}

// TextShareSheet構造体
struct TextShareSheet: UIViewControllerRepresentable {
    var text: String
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityItems: [Any] = [text]
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
// 通知設定監視用のクラス - アプリ全体で利用可能にする場合
class NotificationSettingsObserver: ObservableObject {
    @Published var isNotificationAuthorized = false
    
    init() {
        checkAuthorizationStatus()
        
        // アプリがフォアグラウンドに戻るときに通知設定をチェック
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkAuthorizationStatus),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isNotificationAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// iOS 16未満用の互換性シェアシート
struct LegacyShareSheet: UIViewControllerRepresentable {
    let text: String
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityItems: [Any] = [text]
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
