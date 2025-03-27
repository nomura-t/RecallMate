// SettingsView.swift の修正版
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
    @State private var shareText = "RecallMateアプリを使って科学的に記憶力を強化しています。長期記憶の定着に最適なアプリです！ https://apps.apple.com/app/recallmate/id000000000" // 実際のApp StoreリンクIDに変更する
    @State private var showNotificationPermission = false
    @StateObject private var notificationObserver = NotificationSettingsObserver()


    
    var body: some View {
        NavigationStack {
            Form {
                // アプリを共有セクション
                Section {
                    HStack(alignment: .center) {
                        // テキスト部分 - タップ不可
                        VStack(alignment: .leading, spacing: 4) {
                            Text("RecallMateを友達に紹介する")
                                .font(.headline)
                            
                            Text("効率的な学習方法を友達にも教えてあげましょう")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // LINEアイコン部分のみタップ可能
                        Button(action: {
                            shareAppViaLINE()
                        }) {
                            VStack(spacing: 2) {
                                Image(systemName: "arrow.up.square")
                                    .font(.system(size: 30))
                                    .foregroundColor(.green)
                                    .frame(width: 40, height: 40)
                                Text("LINE")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
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
                
                // テキストフォントサイズ設定セクション
                Section(header: Text("テキスト設定")) {
                    VStack(alignment: .leading, spacing: 16) {
                        // 回答テキストのフォントサイズの選択
                        VStack(alignment: .leading, spacing: 4) {
                            Picker("回答フォントサイズ", selection: $appSettings.answerFontSize) {
                                ForEach(appSettings.availableFontSizes, id: \.self) { size in
                                    Text("\(Int(size))pt").tag(size)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            
                            // 回答テキストのプレビュー
                            Text("回答テキストのプレビュー")
                                .font(.system(size: CGFloat(appSettings.answerFontSize)))
                                .padding(.vertical, 4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        Divider()
                        
                        // メモ入力欄のフォントサイズの選択
                        VStack(alignment: .leading, spacing: 4) {
                            Picker("メモフォントサイズ", selection: $appSettings.memoFontSize) {
                                ForEach(appSettings.availableFontSizes, id: \.self) { size in
                                    Text("\(Int(size))pt").tag(size)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            
                            // メモテキストのプレビュー
                            Text("メモテキストのプレビュー")
                                .font(.system(size: CGFloat(appSettings.memoFontSize)))
                                .padding(.vertical, 4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
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
                TextShareSheet(text: shareText)
            }
            .alert(isPresented: $showMissingAppAlert) {
                Alert(
                    title: Text("\(missingAppName)がインストールされていません"),
                    message: Text("共有するには\(missingAppName)アプリをインストールしてください。"),
                    dismissButton: .default(Text("OK"))
                )
            }
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
                        
                        print("🔔 通知設定をチェック - システム: \(isEnabled), アプリ内: \(self.notificationEnabled)")
                    }
                }
                
                // ビューが表示されるたびに現在の通知時間を更新
                currentNotificationTime = StreakNotificationManager.shared.getPreferredTimeString()
                
                // 現在のフォントサイズが選択肢になければ、近い値に調整
                if !appSettings.availableFontSizes.contains(appSettings.answerFontSize) {
                    let closest = appSettings.availableFontSizes.min(by: {
                        abs($0 - appSettings.answerFontSize) < abs($1 - appSettings.answerFontSize)
                    }) ?? 16
                    appSettings.answerFontSize = closest
                }
                
                // メモフォントサイズも同様に調整
                if !appSettings.availableFontSizes.contains(appSettings.memoFontSize) {
                    let closest = appSettings.availableFontSizes.min(by: {
                        abs($0 - appSettings.memoFontSize) < abs($1 - appSettings.memoFontSize)
                    }) ?? 16
                    appSettings.memoFontSize = closest
                }
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
    
    // 通知設定を確認して画面を更新する関数
    private func checkNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                // システムの通知許可状態をトグルに反映
                self.notificationEnabled = settings.authorizationStatus == .authorized
                // UserDefaultsも同期して保存
                UserDefaults.standard.set(self.notificationEnabled, forKey: "notificationsEnabled")
                
                print("🔄 通知設定を更新: \(self.notificationEnabled ? "有効" : "無効")")
                
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
        print("🔕 通知を無効化します")
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    // 通知許可をリクエスト
    private func requestNotificationPermission() {
        print("🔔 通知許可をリクエストします")
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                // 許可されなかった場合はトグルを戻す
                if !granted {
                    print("❌ 通知許可が拒否されました")
                    self.notificationEnabled = false
                    UserDefaults.standard.set(false, forKey: "notificationsEnabled")
                } else {
                    print("✅ 通知許可が承認されました")
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
