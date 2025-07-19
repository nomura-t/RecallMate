import SwiftUI

struct SocialUserProfileView: View {
    let profile: EnhancedProfile
    @Environment(\.dismiss) private var dismiss
    @StateObject private var friendshipManager = EnhancedFriendshipManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // プロフィールヘッダー
                    profileHeader
                    
                    // 学習統計
                    studyStats
                    
                    // 学習状態
                    if profile.isCurrentlyStudying {
                        currentStudyStatus
                    }
                    
                    // アクションボタン
                    actionButtons
                    
                    // 詳細情報
                    detailInfo
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("プロフィール")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(text: shareText)
            }
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // アバター
            AsyncImage(url: URL(string: profile.avatarUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 40))
                    )
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
            )
            
            VStack(spacing: 8) {
                // 名前
                Text(profile.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                // ユーザー名
                if let username = profile.username {
                    Text("@\(username)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // バイオ
                if let bio = profile.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // 学習コード
                if let studyCode = profile.studyCode {
                    HStack {
                        Image(systemName: "number")
                            .foregroundColor(.blue)
                        
                        Text("学習コード: \(studyCode)")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - Study Stats
    
    private var studyStats: some View {
        VStack(spacing: 16) {
            Text("学習統計")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                statCard(
                    title: "総学習時間",
                    value: profile.formattedStudyTime,
                    icon: "clock.fill",
                    color: .blue
                )
                
                statCard(
                    title: "レベル",
                    value: "Lv.\(profile.currentLevel)",
                    icon: "star.fill",
                    color: .yellow
                )
                
                statCard(
                    title: "現在の連続日数",
                    value: "\(profile.currentStreak)日",
                    icon: "flame.fill",
                    color: .orange
                )
                
                statCard(
                    title: "最長連続日数",
                    value: "\(profile.longestStreak)日",
                    icon: "trophy.fill",
                    color: .green
                )
                
                statCard(
                    title: "総メモ数",
                    value: "\(profile.totalMemoCount)",
                    icon: "doc.text.fill",
                    color: .purple
                )
                
                statCard(
                    title: "レベルポイント",
                    value: "\(profile.levelPoints)",
                    icon: "diamond.fill",
                    color: .pink
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(radius: 1)
    }
    
    // MARK: - Current Study Status
    
    private var currentStudyStatus: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                
                Text("現在学習中")
                    .font(.headline)
                    .foregroundColor(.green)
                
                Spacer()
            }
            
            if let subject = profile.studySubject {
                HStack {
                    Image(systemName: "book.closed")
                        .foregroundColor(.blue)
                    
                    Text(subject)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    
                    Spacer()
                }
            }
            
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                
                Text("学習時間: \(profile.currentStudyTimeFormatted)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // 自分自身の場合は編集ボタンを表示
            if profile.id == authManager.currentUser?.id.uuidString {
                Button {
                    // プロフィール編集画面を開く
                } label: {
                    Label("プロフィールを編集", systemImage: "pencil")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            } else {
                // 他のユーザーの場合はフォロー/アンフォローボタン
                Button {
                    Task {
                        if friendshipManager.isFollowing(userId: profile.id) {
                            await friendshipManager.unfollowUser(userId: profile.id)
                        } else {
                            await friendshipManager.followUser(userId: profile.id)
                        }
                    }
                } label: {
                    Label(
                        friendshipManager.isFollowing(userId: profile.id) ? "フォロー中" : "フォロー",
                        systemImage: friendshipManager.isFollowing(userId: profile.id) ? "person.fill.checkmark" : "person.badge.plus"
                    )
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(friendshipManager.isFollowing(userId: profile.id) ? Color.secondary : Color.blue)
                    .cornerRadius(10)
                }
                
                // メッセージボタン（将来実装）
                Button {
                    // ダイレクトメッセージ機能
                } label: {
                    Label("メッセージ", systemImage: "message")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                }
            }
        }
    }
    
    // MARK: - Detail Info
    
    private var detailInfo: some View {
        VStack(spacing: 16) {
            Text("詳細情報")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                infoRow(
                    label: "参加日",
                    value: DateFormatter.userProfile.string(from: profile.createdAt),
                    icon: "calendar"
                )
                
                infoRow(
                    label: "最終アクティブ",
                    value: RelativeDateTimeFormatter().localizedString(for: profile.lastActiveAt, relativeTo: Date()),
                    icon: "clock"
                )
                
                if let statusMessage = profile.statusMessage, !statusMessage.isEmpty {
                    infoRow(
                        label: "ステータス",
                        value: statusMessage,
                        icon: "message"
                    )
                }
                
                // プライバシー設定
                infoRow(
                    label: "プロフィール",
                    value: profile.isPublic ? "公開" : "非公開",
                    icon: profile.isPublic ? "eye" : "eye.slash"
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func infoRow(label: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20, height: 20)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Share
    
    private var shareText: String {
        var text = "RecallMateで\(profile.displayName)さんをチェック！\n"
        
        if let studyCode = profile.studyCode {
            text += "学習コード: \(studyCode)\n"
        }
        
        text += "総学習時間: \(profile.formattedStudyTime)\n"
        text += "レベル: Lv.\(profile.currentLevel)"
        
        return text
    }
}


// MARK: - Extensions

extension DateFormatter {
    static let userProfile: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
}

// MARK: - Preview

struct SocialUserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        SocialUserProfileView(profile: EnhancedProfile(
            id: "1",
            username: "testuser",
            fullName: "テストユーザー",
            nickname: "テスト",
            bio: "学習を頑張っています！",
            avatarUrl: nil,
            studyCode: "AB12CD34",
            totalStudyMinutes: 1200,
            totalMemoCount: 150,
            levelPoints: 2500,
            currentLevel: 5,
            longestStreak: 15,
            currentStreak: 7,
            isStudying: true,
            studyStartTime: Date(),
            studySubject: "英語",
            statusMessage: "今日も頑張ります！",
            isPublic: true,
            allowFriendRequests: true,
            allowGroupInvites: true,
            emailNotifications: true,
            createdAt: Date(),
            updatedAt: Date(),
            lastActiveAt: Date()
        ))
    }
}