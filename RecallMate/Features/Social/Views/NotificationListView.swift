import SwiftUI

struct NotificationListView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var selectedFilter = 0 // 0: 全て, 1: 未読, 2: フォロー, 3: グループ, 4: メッセージ
    @State private var showUserProfile: EnhancedProfile?
    @State private var showGroupDetail: StudyGroup?
    @State private var showBoardPost: BoardPost?
    
    var body: some View {
        if authManager.isAuthenticated {
            VStack {
                // フィルター選択
                filterSelector
                
                // 通知リスト
                notificationsList
            }
            .refreshable {
                await notificationManager.refreshNotifications()
            }
            .onAppear {
                Task {
                    await notificationManager.loadNotifications()
                }
            }
            .sheet(item: $showUserProfile) { profile in
                SocialUserProfileView(profile: profile)
            }
            .sheet(item: $showGroupDetail) { group in
                GroupDetailView(group: group)
            }
            .sheet(item: $showBoardPost) { post in
                PostDetailView(post: post)
            }
        } else {
            authenticationRequiredView
        }
    }
    
    // MARK: - Authentication Required View
    
    private var authenticationRequiredView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "bell.badge")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("通知を見るには")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("通知機能を使用するには\nアカウントにログインしてください")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            NavigationLink(destination: LoginView()) {
                Text("ログイン・新規登録")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Filter Selector
    
    private var filterSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                filterButton(title: "全て", count: notificationManager.notifications.count, tag: 0)
                filterButton(title: "未読", count: notificationManager.unreadCount, tag: 1)
                filterButton(title: "フォロー", count: notificationManager.getNotifications(ofType: .newFollow).count, tag: 2)
                filterButton(title: "グループ", count: notificationManager.getNotifications(ofType: .groupInvitation).count, tag: 3)
                filterButton(title: "メッセージ", count: notificationManager.getNotifications(ofType: .newMessage).count, tag: 4)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    private func filterButton(title: String, count: Int, tag: Int) -> some View {
        Button {
            selectedFilter = tag
        } label: {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(selectedFilter == tag ? .semibold : .regular)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(selectedFilter == tag ? Color.white.opacity(0.3) : Color.red)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(selectedFilter == tag ? Color.blue : Color.gray.opacity(0.2))
            .foregroundColor(selectedFilter == tag ? .white : .primary)
            .cornerRadius(16)
        }
    }
    
    // MARK: - Notifications List
    
    private var notificationsList: some View {
        Group {
            if filteredNotifications.isEmpty {
                emptyNotificationsView
            } else {
                List(filteredNotifications, id: \.id) { notification in
                    NotificationRowView(notification: notification) {
                        await handleNotificationTap(notification)
                    } onMarkAsRead: {
                        if !notification.isRead {
                            Task {
                                await notificationManager.markAsRead(notification.id)
                            }
                        }
                    } onDelete: {
                        Task {
                            await notificationManager.deleteNotification(notification.id)
                        }
                    }
                }
            }
        }
    }
    
    private var emptyNotificationsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("通知なし")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(emptyStateMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helper Properties
    
    private var filteredNotifications: [SocialNotification] {
        switch selectedFilter {
        case 1:
            return notificationManager.getUnreadNotifications()
        case 2:
            return notificationManager.getNotifications(ofType: .newFollow)
        case 3:
            return notificationManager.getNotifications(ofType: .groupInvitation)
        case 4:
            return notificationManager.getNotifications(ofType: .newMessage)
        default:
            return notificationManager.notifications
        }
    }
    
    private var emptyStateMessage: String {
        switch selectedFilter {
        case 1:
            return "未読の通知はありません"
        case 2:
            return "フォロー関連の通知はありません"
        case 3:
            return "グループ関連の通知はありません"
        case 4:
            return "メッセージ関連の通知はありません"
        default:
            return "通知はありません"
        }
    }
    
    // MARK: - Notification Actions
    
    private func handleNotificationTap(_ notification: SocialNotification) async {
        // 未読の場合は既読にする
        if !notification.isRead {
            await notificationManager.markAsRead(notification.id)
        }
        
        // 通知の種類に応じて適切な画面を開く
        switch notification.type {
        case .newFollow, .follow, .friendRequest, .friendAccepted:
            // ユーザープロフィールを表示
            // 実際の実装では、ユーザー情報を取得してからプロフィールを表示
            break
            
        case .groupInvitation, .groupInvite:
            // グループ詳細を表示
            // 実際の実装では、グループ情報を取得してから詳細を表示
            break
            
        case .newMessage, .message, .groupMessage:
            // チャット画面を表示
            // 実際の実装では、チャット画面を表示
            break
            
        case .boardReply, .postReply:
            // 投稿詳細を表示
            // 実際の実装では、投稿情報を取得してから詳細を表示
            break
            
        default:
            break
        }
    }
}

// MARK: - Notification Row View

struct NotificationRowView: View {
    let notification: SocialNotification
    let onTap: () async -> Void
    let onMarkAsRead: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            // アイコン
            notificationIcon
            
            // 内容
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.subheadline)
                    .fontWeight(notification.isRead ? .regular : .semibold)
                    .foregroundColor(notification.isRead ? .secondary : .primary)
                
                if !notification.message.isEmpty {
                    Text(notification.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Text(timeAgo(from: notification.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // 送信者情報は一時的にコメントアウト
                    // if let sender = notification.sender {
                    //     Text(sender.displayName)
                    //         .font(.caption)
                    //         .foregroundColor(.blue)
                    // }
                }
            }
            
            Spacer()
            
            // 未読インジケーター
            if !notification.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            Task {
                await onTap()
            }
        }
        .contextMenu {
            if !notification.isRead {
                Button("既読にする") {
                    onMarkAsRead()
                }
            }
            
            Button("削除", role: .destructive) {
                onDelete()
            }
        }
    }
    
    private var notificationIcon: some View {
        ZStack {
            Circle()
                .fill(notificationColor.opacity(0.2))
                .frame(width: 40, height: 40)
            
            Image(systemName: iconName(for: notification.type))
                .foregroundColor(notificationColor)
                .font(.system(size: 16))
        }
    }
    
    private var notificationColor: Color {
        switch notification.type {
        case .newFollow, .friendRequest, .friendAccepted:
            return .blue
        case .groupInvitation, .groupInvite:
            return .green
        case .newMessage, .groupMessage:
            return .purple
        case .postReply, .boardReply:
            return .orange
        case .studyStatusChange, .studyReminder:
            return .yellow
        case .newChallenge, .challengeCompleted:
            return .red
        default:
            return .gray
        }
    }
    
    private func iconName(for type: NotificationType) -> String {
        switch type {
        case .friendRequest, .friendAccepted:
            return "person.badge.plus"
        case .groupInvite, .groupInvitation:
            return "person.3"
        case .groupMessage, .newMessage:
            return "message"
        case .studyReminder:
            return "bell"
        case .achievementUnlocked:
            return "trophy"
        case .postReply, .boardReply:
            return "bubble.right"
        case .postLike:
            return "heart"
        case .newChallenge, .challengeCompleted:
            return "star"
        case .follow, .newFollow:
            return "person.badge.plus"
        case .studyStatusChange:
            return "book"
        case .message:
            return "message"
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Notification Badge View

struct NotificationBadgeView: View {
    let count: Int
    
    var body: some View {
        ZStack {
            if count > 0 {
                Circle()
                    .fill(Color.red)
                    .frame(width: 20, height: 20)
                
                Text(count > 99 ? "99+" : "\(count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.5)
            }
        }
    }
}

// MARK: - Preview

struct NotificationListView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationListView()
    }
}
