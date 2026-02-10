// SettingsView.swift - リデザイン版
import SwiftUI
import Foundation
import UserNotifications

struct SettingsView: View {
    @State private var notificationEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
    @State private var currentNotificationTime = ""
    @EnvironmentObject private var appSettings: AppSettings
    @StateObject private var authManager = AuthenticationManager.shared

    @State private var isShareSheetPresented = false
    @State private var showMissingAppAlert = false
    @State private var missingAppName = ""
    @State private var shareText = "RecallMateアプリを使って科学的に記憶力を強化しています。長期記憶の定着に最適なアプリです！ https://apps.apple.com/app/recallmate/id6744206597".localized
    @State private var showNotificationPermission = false
    @State private var showSocialShareView = false
    @StateObject private var notificationObserver = NotificationSettingsObserver()
    @State private var showAppInfoView = false
    @State private var showLoginView = false
    @State private var showMigrationView = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.md) {
                    // アカウントセクション
                    accountSection

                    // 通知設定セクション（統合版）
                    notificationSection

                    // アプリを共有セクション
                    shareSection

                    // アプリ情報セクション
                    appInfoSection

                    // ライセンス情報セクション
                    licenseSection
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.md)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("設定".localized)
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $isShareSheetPresented) {
                if #available(iOS 16.0, *) {
                    ShareSheet(text: shareText)
                } else {
                    LegacyShareSheet(text: shareText)
                }
            }
            .alert(isPresented: $showMissingAppAlert) {
                Alert(
                    title: Text("%@がインストールされていません".localizedFormat(missingAppName)),
                    message: Text("共有するには%@アプリをインストールしてください。".localizedFormat(missingAppName)),
                    dismissButton: .default(Text("OK".localized))
                )
            }
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
                self.notificationEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
                checkNotificationSettings()
                currentNotificationTime = StreakNotificationManager.shared.getPreferredTimeString()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            checkNotificationSettings()
        }
        .overlay(
            Group {
                if showNotificationPermission {
                    NotificationPermissionView(
                        isPresented: $showNotificationPermission,
                        onPermissionGranted: {
                            self.notificationEnabled = true
                            UserDefaults.standard.set(true, forKey: "notificationsEnabled")
                        },
                        onPermissionDenied: {
                            self.notificationEnabled = false
                            UserDefaults.standard.set(false, forKey: "notificationsEnabled")
                        }
                    )
                    .transition(.opacity)
                    .animation(.easeInOut, value: showNotificationPermission)
                }
            }
        )
        .sheet(isPresented: $showLoginView) {
            LoginView()
        }
        .sheet(isPresented: $showMigrationView) {
            AccountMigrationView()
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            settingsSectionHeader(icon: "person.crop.circle.fill", title: "アカウント".localized, color: .blue)

            VStack(spacing: 0) {
                if authManager.isAuthenticated {
                    // プロフィールカード
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.blue, .blue.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 44, height: 44)

                            Text(String((authManager.userProfile?.displayName ?? "U").prefix(1)).uppercased())
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(authManager.userProfile?.displayName ?? "ユーザー")
                                    .font(.headline)

                                Text("Pro")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        LinearGradient(
                                            colors: [.orange, .orange.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(4)
                            }

                            Text("認証方法: \(authManager.authProviderName)")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            if let studyCode = authManager.userProfile?.studyCode {
                                Text("学習コード: \(studyCode)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, AppTheme.Spacing.md)

                    Divider().padding(.leading, AppTheme.Spacing.md)

                    // 匿名ユーザーの場合はアップグレード提案
                    if authManager.isAnonymousUser {
                        settingsRow(icon: "arrow.up.circle", title: "アカウントをアップグレード", color: .orange) {
                            showMigrationView = true
                        }
                        Divider().padding(.leading, AppTheme.Spacing.md)
                    }

                    // サインアウト
                    settingsRow(icon: "arrow.right.square", title: "サインアウト", color: .red) {
                        Task { await authManager.signOut() }
                    }
                } else {
                    settingsRow(icon: "person.crop.circle", title: "ログイン", color: .blue, showChevron: true) {
                        showLoginView = true
                    }

                    Text("ログインしてデータを安全に保存しましょう")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.bottom, 12)
                }
            }
            .background(cardBackgroundColor)
            .cornerRadius(AppTheme.Radius.md)
        }
    }

    // MARK: - Notification Section (統合版)

    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            settingsSectionHeader(icon: "bell.fill", title: "通知設定".localized, color: .orange)

            VStack(spacing: 0) {
                NavigationLink(destination: NotificationSettingsView()) {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.orange)
                            .frame(width: 28)
                        Text("通知設定".localized)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, AppTheme.Spacing.md)
                }
                .buttonStyle(PlainButtonStyle())

                Divider().padding(.leading, AppTheme.Spacing.md)

                // 通知時間表示
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                        .frame(width: 28)
                    Text("現在の通知時間:".localized)
                    Spacer()
                    Text(currentNotificationTime.isEmpty
                         ? StreakNotificationManager.shared.getPreferredTimeString()
                         : currentNotificationTime)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, AppTheme.Spacing.md)

                Divider().padding(.leading, AppTheme.Spacing.md)

                // 通知時間更新ボタン
                Button(action: {
                    StreakNotificationManager.shared.updatePreferredTime()
                    currentNotificationTime = StreakNotificationManager.shared.getPreferredTimeString()
                    let feedback = UIImpactFeedbackGenerator(style: .light)
                    feedback.impactOccurred()
                }) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 16))
                            .foregroundColor(.green)
                            .frame(width: 28)
                        Text("現在時刻を通知時間に設定".localized)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, AppTheme.Spacing.md)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!notificationEnabled)
                .opacity(notificationEnabled ? 1.0 : 0.5)
            }
            .background(cardBackgroundColor)
            .cornerRadius(AppTheme.Radius.md)
        }
    }

    // MARK: - Share Section

    private var shareSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            settingsSectionHeader(icon: "square.and.arrow.up.fill", title: "アプリを共有".localized, color: .green)

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("RecallMateを友達に紹介する".localized)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("効率的な学習方法を友達にも教えてあげましょう".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: { showSocialShareView = true }) {
                    Image(systemName: "square.and.arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(AppTheme.Spacing.md)
            .background(cardBackgroundColor)
            .cornerRadius(AppTheme.Radius.md)
        }
    }

    // MARK: - App Info Section

    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            settingsSectionHeader(icon: "info.circle.fill", title: "アプリ情報".localized, color: .purple)

            VStack(spacing: 0) {
                Button(action: { openTwitterProfile() }) {
                    HStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("開発者に言いたいことを言おう！".localized)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            Text("@ttttttt12345654")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, AppTheme.Spacing.md)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(cardBackgroundColor)
            .cornerRadius(AppTheme.Radius.md)
        }
    }

    // MARK: - License Section

    private var licenseSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            settingsSectionHeader(icon: "doc.text.fill", title: "ライセンス情報", color: .gray)

            VStack(alignment: .leading, spacing: 8) {
                Text("サードパーティライセンス")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    Image("google-logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                    Text("Googleのロゴ")
                        .font(.caption)
                }

                Link(destination: URL(string: "https://icons8.com/icon/17949/google")!) {
                    Text("Googleのロゴ アイコン by Icons8")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(cardBackgroundColor)
            .cornerRadius(AppTheme.Radius.md)
        }
    }

    // MARK: - Helper Components

    @Environment(\.colorScheme) private var colorScheme

    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)
    }

    private func settingsSectionHeader(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 8)
        .padding(.top, 4)
    }

    private func settingsRow(icon: String, title: String, color: Color, showChevron: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                    .frame(width: 28)
                Text(title)
                    .foregroundColor(color == .red ? .red : .primary)
                Spacer()
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, AppTheme.Spacing.md)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(authManager.isLoading)
    }

    // MARK: - Functions

    private func openTwitterProfile() {
        let twitterAppURL = URL(string: "twitter://user?screen_name=ttttttt12345654")!
        let twitterWebURL = URL(string: "https://x.com/ttttttt12345654")!

        if UIApplication.shared.canOpenURL(twitterAppURL) {
            UIApplication.shared.open(twitterAppURL)
        } else {
            UIApplication.shared.open(twitterWebURL)
        }
    }

    private func checkNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationEnabled = settings.authorizationStatus == .authorized
                UserDefaults.standard.set(self.notificationEnabled, forKey: "notificationsEnabled")
                if self.notificationEnabled {
                    StreakNotificationManager.shared.scheduleStreakReminder()
                }
            }
        }
    }

    func shareAppViaLINE() {
        let encodedText = shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let lineURL = URL(string: "https://line.me/R/msg/text/?\(encodedText)")!

        if UIApplication.shared.canOpenURL(lineURL) {
            UIApplication.shared.open(lineURL)
        } else {
            showAlertForMissingApp(name: "LINE")
        }
    }

    func showShareSheet() {
        isShareSheetPresented = true
    }

    func showAlertForMissingApp(name: String) {
        missingAppName = name
        showMissingAppAlert = true
    }

    private func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if !granted {
                    self.notificationEnabled = false
                    UserDefaults.standard.set(false, forKey: "notificationsEnabled")
                } else {
                    self.notificationEnabled = true
                    UserDefaults.standard.set(true, forKey: "notificationsEnabled")
                    StreakNotificationManager.shared.scheduleStreakReminder()
                }
            }
        }
    }

    public func openAppNotificationSettings() {
        if #available(iOS 16.0, *) {
            if let bundleId = Bundle.main.bundleIdentifier,
               let url = URL(string: UIApplication.openNotificationSettingsURLString + "?bundleIdentifier=\(bundleId)") {
                UIApplication.shared.open(url)
            }
        } else {
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

class NotificationSettingsObserver: ObservableObject {
    @Published var isNotificationAuthorized = false

    init() {
        checkAuthorizationStatus()
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

struct LegacyShareSheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityItems: [Any] = [text]
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
