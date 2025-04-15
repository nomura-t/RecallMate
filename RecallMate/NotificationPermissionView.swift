// NotificationPermissionView.swift として新規ファイルを作成
import SwiftUI
import UserNotifications

struct NotificationPermissionView: View {
    @Binding var isPresented: Bool
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    
    var onPermissionGranted: (() -> Void)? = nil
    var onPermissionDenied: (() -> Void)? = nil

    
    var body: some View {
        ZStack {
            // 背景オーバーレイ
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // 背景タップでモーダルを閉じる
                    withAnimation {
                        isPresented = false
                    }
                }
            
            // モーダルコンテンツ
            VStack(spacing: 20) {
                // タイトル
                Text("通知を有効にしませんか？")
                    .font(.headline)
                    .padding(.top)
                
                // 通知の利点を説明
                VStack(alignment: .leading, spacing: 12) {
                    PermissionBenefitRow(
                        icon: "calendar.badge.clock",
                        title: "習慣化をサポート",
                        description: "継続学習のリマインダーで習慣化をサポートします"
                    )
                    
                    PermissionBenefitRow(
                        icon: "timer",
                        title: "ポモドーロタイマー通知",
                        description: "集中時間と休憩時間の切り替えを通知します"
                    )
                    
                    PermissionBenefitRow(
                        icon: "brain.head.profile",
                        title: "復習リマインダー",
                        description: "最適なタイミングで復習通知を受け取れます"
                    )
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // ボタン
                HStack(spacing: 20) {
                    Button(action: {
                        requestNotifications()
                    }) {
                        Text("設定を開く")
                            .bold()
                            .foregroundColor(.white)
                            .padding()
                            .frame(minWidth: 140)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    
                    // キャンセルボタンのアクションを修正
                    Button("後で") {
                        isPresented = false
                        onPermissionDenied?()
                    }
                    .foregroundColor(.gray)
                    .padding()
                }
                .padding(.bottom)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding(.horizontal, 40)
        }
        .onAppear {
            checkNotificationStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // アプリがフォアグラウンドに戻ってきたときに状態を確認
            checkNotificationStatus()
        }

    }
    // 通知許可をリクエスト
    private func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                }
                
                if granted {
                    self.onPermissionGranted?()
                    self.isPresented = false
                    
                    StreakNotificationManager.shared.scheduleStreakReminder()
                } else {
                    self.onPermissionDenied?()
                    self.isPresented = false
                }
            }
        }
    }
    
    // 通知ステータスの確認
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationStatus = settings.authorizationStatus
                
                if settings.authorizationStatus == .authorized {
                    isPresented = false
                }
            }
        }
    }}

// 通知の利点を表す行コンポーネント
struct PermissionBenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
