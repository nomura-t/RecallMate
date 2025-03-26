// NotificationPermissionView.swift として新規ファイルを作成
import SwiftUI
import UserNotifications

struct NotificationPermissionView: View {
    @Binding var isPresented: Bool
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    
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
                    Button("後で") {
                        isPresented = false
                    }
                    .foregroundColor(.gray)
                    .padding()
                    
                    Button(action: requestNotifications) {
                        Text("通知を許可")
                            .bold()
                            .foregroundColor(.white)
                            .padding()
                            .frame(minWidth: 140)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
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
    }
    
    // 通知ステータスの確認
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationStatus = settings.authorizationStatus
                
                // すでに許可されている場合はモーダルを閉じる
                if notificationStatus == .authorized {
                    isPresented = false
                }
            }
        }
    }
    
    // 通知許可をリクエスト
    private func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    // 許可された場合
                    // 習慣化リマインダーと通知のセットアップ
                    StreakNotificationManager.shared.scheduleStreakReminder()
                    
                    // 習慣化チャレンジの通知もセットアップ
                    // (必要に応じて呼び出し)
                }
                
                // 処理完了後にモーダルを閉じる
                isPresented = false
            }
        }
    }
}

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
