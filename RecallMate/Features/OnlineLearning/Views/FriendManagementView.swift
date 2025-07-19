import SwiftUI

struct FriendManagementView: View {
    @StateObject private var friendshipManager = FriendshipManager.shared
    @StateObject private var studySessionManager = StudySessionManager.shared
    @State private var showAddFriendSheet = false
    @State private var showProfileSheet = false
    @State private var showRemoveFriendAlert = false
    @State private var friendToRemove: FriendInfo?
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("表示モード", selection: $selectedTab) {
                    Text("フレンド").tag(0)
                    Text("ランキング").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    // Friends Tab
                    ScrollView {
                        VStack(spacing: 20) {
                            // Header
                            headerSection
                            
                            // My Study Code Section
                            myStudyCodeSection
                            
                            // My Study Stats
                            myStudyStatsSection
                            
                            // Friends List
                            friendsListSection
                            
                            Spacer()
                        }
                        .padding()
                    }
                    .tag(0)
                    
                    // Ranking Tab
                    ScrollView {
                        VStack(spacing: 20) {
                            rankingHeaderSection
                            friendsRankingSection
                        }
                        .padding()
                    }
                    .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle(selectedTab == 0 ? "フレンド管理" : "学習ランキング")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddFriendSheet = true
                    }) {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showAddFriendSheet) {
                AddFriendView()
            }
            .sheet(isPresented: $showProfileSheet) {
                ProfileEditView()
            }
            .alert("フレンド削除", isPresented: $showRemoveFriendAlert, presenting: friendToRemove) { friend in
                Button("削除", role: .destructive) {
                    Task {
                        await friendshipManager.removeFriend(friendId: friend.friendId)
                    }
                }
                Button("キャンセル", role: .cancel) { }
            } message: { friend in
                Text("\(friend.displayName)をフレンドから削除しますか？")
            }
            .task {
                await friendshipManager.refreshData()
                await studySessionManager.refreshAllData()
            }
            .refreshable {
                await friendshipManager.refreshData()
                await studySessionManager.refreshAllData()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.2.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("フレンド管理")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("学習コードを共有してフレンドを追加しよう")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var myStudyCodeSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("あなたの学習コード")
                    .font(.headline)
                Spacer()
                Button("プロフィール編集") {
                    showProfileSheet = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if let profile = friendshipManager.currentUserProfile {
                VStack(spacing: 12) {
                    // Study Code Display
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("学習コード")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(profile.studyCode ?? "未設定")
                                .font(.title2)
                                .fontWeight(.bold)
                                .fontDesign(.monospaced)
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 8) {
                            Button(action: {
                                if let studyCode = profile.studyCode {
                                    UIPasteboard.general.string = studyCode
                                }
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .font(.title3)
                            }
                            .disabled(profile.studyCode == nil)
                            
                            Button(action: {
                                Task {
                                    await friendshipManager.generateNewStudyCode()
                                }
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.title3)
                            }
                        }
                        .foregroundColor(.blue)
                    }
                    
                    // User Info
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("表示名")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(profile.displayName)
                                .font(.body)
                        }
                        Spacer()
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                VStack {
                    ProgressView()
                    Text("プロフィール読み込み中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(height: 80)
            }
        }
    }
    
    private var myStudyStatsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("あなたの学習統計")
                    .font(.headline)
                Spacer()
            }
            
            if let stats = studySessionManager.myStudyStats {
                VStack(spacing: 12) {
                    HStack {
                        StudyStatCard(
                            title: "今日",
                            value: formatTime(TimeInterval(stats.dailyStudyTime * 60)),
                            icon: "clock.fill",
                            color: .blue
                        )
                        
                        StudyStatCard(
                            title: "今週",
                            value: formatTime(TimeInterval(stats.weeklyStudyTime * 60)),
                            icon: "calendar.badge.clock",
                            color: .green
                        )
                    }
                    
                    HStack {
                        StudyStatCard(
                            title: "合計",
                            value: formatTime(TimeInterval(stats.totalStudyTime * 60)),
                            icon: "chart.bar.fill",
                            color: .orange
                        )
                        
                        StudyStatCard(
                            title: "連続日数",
                            value: "\(stats.currentStreak)日",
                            icon: "flame.fill",
                            color: .red
                        )
                    }
                    
                    // Current study status
                    HStack {
                        Circle()
                            .fill(stats.isCurrentlyStudying ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)
                        
                        Text(stats.isCurrentlyStudying ? "学習中" : "オフライン")
                            .font(.caption)
                            .foregroundColor(stats.isCurrentlyStudying ? .green : .secondary)
                        
                        Spacer()
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                VStack {
                    ProgressView()
                    Text("統計読み込み中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(height: 100)
            }
        }
    }
    
    private var rankingHeaderSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("学習ランキング")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("フレンドと学習時間を競い合おう")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var friendsRankingSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("週間ランキング")
                    .font(.headline)
                Spacer()
                Button("更新") {
                    Task {
                        await studySessionManager.loadFriendsStudyInfo()
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if studySessionManager.isLoading {
                VStack {
                    ProgressView()
                    Text("ランキング読み込み中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
            } else if studySessionManager.friendsStudyInfo.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    Text("ランキングデータがありません")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("フレンドを追加して学習時間を競い合いましょう")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(studySessionManager.friendsStudyInfo.enumerated()), id: \.element.id) { index, friendInfo in
                        FriendRankingRowView(friendInfo: friendInfo, rank: index + 1)
                    }
                }
            }
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private var friendsListSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("フレンド一覧")
                    .font(.headline)
                Spacer()
                Text("\(friendshipManager.friends.count)人")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if friendshipManager.isLoading {
                VStack {
                    ProgressView()
                    Text("読み込み中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(height: 100)
            } else if friendshipManager.friends.isEmpty {
                emptyFriendsView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(friendshipManager.friends) { friend in
                        FriendRowView(friend: friend) {
                            friendToRemove = friend
                            showRemoveFriendAlert = true
                        }
                    }
                }
            }
        }
    }
    
    private var emptyFriendsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("まだフレンドがいません")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("右上の + ボタンからフレンドを追加できます")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("フレンドを追加") {
                showAddFriendSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct FriendRowView: View {
    let friend: FriendInfo
    let onRemove: () -> Void
    @StateObject private var studySessionManager = StudySessionManager.shared
    
    private var friendStudyInfo: FriendStudyInfo? {
        studySessionManager.friendsStudyInfo.first { $0.userId == friend.friendId }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar with online indicator
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Text(String(friend.displayName.prefix(1)))
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                
                // Online status indicator
                Circle()
                    .fill(friendStudyInfo?.isCurrentlyStudying == true ? Color.green : Color.gray)
                    .frame(width: 12, height: 12)
                    .background(Color.white)
                    .clipShape(Circle())
            }
            
            // Friend Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(friend.displayName)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    if friendStudyInfo?.isCurrentlyStudying == true {
                        Text("学習中")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(8)
                    }
                }
                
                if let studyCode = friend.friendStudyCode {
                    Text("学習コード: \(studyCode)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fontDesign(.monospaced)
                }
                
                // Study stats
                if let studyInfo = friendStudyInfo {
                    HStack(spacing: 12) {
                        Text("今週: \(studyInfo.formattedWeeklyTime)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("合計: \(studyInfo.formattedTotalTime)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if let acceptedAt = friend.acceptedAt {
                    Text("追加日: \(acceptedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Rank badge if available
            if let studyInfo = friendStudyInfo, let rank = studyInfo.rank {
                VStack {
                    Image(systemName: rank <= 3 ? "crown.fill" : "number.circle.fill")
                        .foregroundColor(rank == 1 ? .yellow : rank == 2 ? .gray : rank == 3 ? .orange : .blue)
                        .font(.caption)
                    Text("#\(rank)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .contextMenu {
            Button(action: onRemove) {
                Label("フレンドを削除", systemImage: "person.fill.xmark")
            }
        }
    }
}

// MARK: - Supporting Views

struct FriendRankingRowView: View {
    let friendInfo: FriendStudyInfo
    let rank: Int
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }
    
    private var rankIcon: String {
        switch rank {
        case 1: return "crown.fill"
        case 2: return "medal.fill"
        case 3: return "medal.fill"
        default: return "number.circle.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank
            VStack {
                Image(systemName: rankIcon)
                    .font(.title2)
                    .foregroundColor(rankColor)
                
                Text("#\(rank)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(rankColor)
            }
            .frame(width: 40)
            
            // Avatar with online status
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 50)
                    .overlay {
                        Text(String(friendInfo.displayName.prefix(1)))
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                
                if friendInfo.isCurrentlyStudying {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 14, height: 14)
                        .background(Color.white)
                        .clipShape(Circle())
                }
            }
            
            // Friend info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(friendInfo.displayName)
                        .font(.body)
                        .fontWeight(.semibold)
                    
                    if friendInfo.isCurrentlyStudying {
                        Text("学習中")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(8)
                    }
                }
                
                Text("今週: \(friendInfo.formattedWeeklyTime)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("合計: \(friendInfo.formattedTotalTime)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Study time (large)
            VStack(alignment: .trailing) {
                Text(friendInfo.formattedWeeklyTime)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("今週")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    FriendManagementView()
}