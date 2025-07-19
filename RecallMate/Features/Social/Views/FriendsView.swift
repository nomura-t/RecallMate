import SwiftUI

struct FriendsView: View {
    @StateObject private var friendshipManager = EnhancedFriendshipManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var showAddFriendSheet = false
    @State private var showUserProfile: EnhancedProfile?
    
    var body: some View {
        if authManager.isAuthenticated {
            VStack {
                // 検索バー
                searchBar
                
                // タブ選択
                tabSelector
                
                // コンテンツ
                TabView(selection: $selectedTab) {
                    // フォロー中
                    followingView
                        .tag(0)
                    
                    // フォロワー
                    followersView
                        .tag(1)
                    
                    // 学習中
                    studyingFriendsView
                        .tag(2)
                    
                    // 推薦
                    recommendedView
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .sheet(isPresented: $showAddFriendSheet) {
                AddFriendView()
            }
            .sheet(item: $showUserProfile) { profile in
                SocialUserProfileView(profile: profile)
            }
            .onAppear {
                Task {
                    await friendshipManager.refreshAllData()
                }
            }
        } else {
            authenticationRequiredView
        }
    }
    
    // MARK: - Authentication Required View
    
    private var authenticationRequiredView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "person.2.fill")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("フレンド機能を使用するには")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("友達とつながって学習を共有するには\nアカウントにログインしてください")
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
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("ユーザーを検索", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    Task {
                        await performSearch()
                    }
                }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack {
            tabButton(title: "フォロー中", count: friendshipManager.following.count, tag: 0)
            tabButton(title: "フォロワー", count: friendshipManager.followers.count, tag: 1)
            tabButton(title: "学習中", count: friendshipManager.studyingFriends.count, tag: 2)
            tabButton(title: "推薦", count: friendshipManager.recommendedUsers.count, tag: 3)
        }
        .padding(.horizontal)
    }
    
    private func tabButton(title: String, count: Int, tag: Int) -> some View {
        Button {
            selectedTab = tag
        } label: {
            VStack(spacing: 4) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(selectedTab == tag ? .semibold : .regular)
                    
                    if count > 0 {
                        Text("\(count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Rectangle()
                    .fill(selectedTab == tag ? Color.blue : Color.clear)
                    .frame(height: 2)
            }
        }
        .foregroundColor(selectedTab == tag ? .blue : .secondary)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Following View
    
    private var followingView: some View {
        Group {
            if friendshipManager.following.isEmpty {
                emptyStateView(
                    icon: "person.badge.plus",
                    title: "フォロー中のユーザーなし",
                    description: "新しいフレンドを見つけてフォローしましょう"
                )
            } else {
                List(filteredFollowing, id: \.id) { user in
                    UserRowView(user: user) {
                        showUserProfile = user
                    } onFollow: {
                        Task {
                            await friendshipManager.unfollowUser(userId: user.id)
                        }
                    }
                }
            }
        }
        .refreshable {
            await friendshipManager.loadFollowRelationships()
        }
    }
    
    // MARK: - Followers View
    
    private var followersView: some View {
        Group {
            if friendshipManager.followers.isEmpty {
                emptyStateView(
                    icon: "person.2",
                    title: "フォロワーなし",
                    description: "より多くの人とつながりましょう"
                )
            } else {
                List(filteredFollowers, id: \.id) { user in
                    UserRowView(user: user) {
                        showUserProfile = user
                    } onFollow: {
                        Task {
                            if friendshipManager.isFollowing(userId: user.id) {
                                await friendshipManager.unfollowUser(userId: user.id)
                            } else {
                                await friendshipManager.followUser(userId: user.id)
                            }
                        }
                    }
                }
            }
        }
        .refreshable {
            await friendshipManager.loadFollowRelationships()
        }
    }
    
    // MARK: - Studying Friends View
    
    private var studyingFriendsView: some View {
        Group {
            if friendshipManager.studyingFriends.isEmpty {
                emptyStateView(
                    icon: "book.closed",
                    title: "学習中のフレンドなし",
                    description: "フレンドが学習を開始すると表示されます"
                )
            } else {
                List(friendshipManager.studyingFriends, id: \.id) { user in
                    StudyingUserRowView(user: user) {
                        showUserProfile = user
                    }
                }
            }
        }
        .refreshable {
            await friendshipManager.loadStudyingFriends()
        }
    }
    
    // MARK: - Recommended View
    
    private var recommendedView: some View {
        Group {
            if friendshipManager.recommendedUsers.isEmpty {
                emptyStateView(
                    icon: "sparkles",
                    title: "推薦ユーザーなし",
                    description: "新しい推薦が見つかるとここに表示されます"
                )
            } else {
                List(friendshipManager.recommendedUsers, id: \.id) { user in
                    UserRowView(user: user) {
                        showUserProfile = user
                    } onFollow: {
                        Task {
                            await friendshipManager.followUser(userId: user.id)
                        }
                    }
                }
            }
        }
        .refreshable {
            await friendshipManager.loadRecommendedUsers()
        }
    }
    
    // MARK: - Helper Views
    
    private func emptyStateView(icon: String, title: String, description: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("フレンドを追加") {
                showAddFriendSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Filtered Data
    
    private var filteredFollowing: [EnhancedProfile] {
        if searchText.isEmpty {
            return friendshipManager.following
        }
        return friendshipManager.following.filter { user in
            user.displayName.localizedCaseInsensitiveContains(searchText) ||
            user.username?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
    
    private var filteredFollowers: [EnhancedProfile] {
        if searchText.isEmpty {
            return friendshipManager.followers
        }
        return friendshipManager.followers.filter { user in
            user.displayName.localizedCaseInsensitiveContains(searchText) ||
            user.username?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
    
    // MARK: - Search
    
    private func performSearch() async {
        guard !searchText.isEmpty else { return }
        
        // 検索機能は将来実装
        // let results = await friendshipManager.searchUsers(query: searchText)
    }
}

// MARK: - User Row View

struct UserRowView: View {
    let user: EnhancedProfile
    let onTap: () -> Void
    let onFollow: () -> Void
    
    @StateObject private var friendshipManager = EnhancedFriendshipManager.shared
    
    var body: some View {
        HStack {
            // アバター
            AsyncImage(url: URL(string: user.avatarUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.headline)
                    .lineLimit(1)
                
                if let username = user.username {
                    Text("@\(username)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                // レベル表示
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    
                    Text("Lv.\(user.currentLevel)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // フォローボタン
                Button {
                    onFollow()
                } label: {
                    Text(friendshipManager.isFollowing(userId: user.id) ? "フォロー中" : "フォロー")
                        .font(.caption)
                        .foregroundColor(friendshipManager.isFollowing(userId: user.id) ? .secondary : .blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    friendshipManager.isFollowing(userId: user.id) ? Color.secondary : Color.blue,
                                    lineWidth: 1
                                )
                        )
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Studying User Row View

struct StudyingUserRowView: View {
    let user: EnhancedProfile
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            // アバター（学習中インジケーター付き）
            ZStack {
                AsyncImage(url: URL(string: user.avatarUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                        )
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                
                // 学習中インジケーター
                Circle()
                    .fill(Color.green)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .offset(x: 18, y: -18)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.headline)
                    .lineLimit(1)
                
                if let subject = user.studySubject {
                    Text("📚 \(subject)")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                }
                
                Text("⏱️ \(user.currentStudyTimeFormatted)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("学習中")
                    .font(.caption)
                    .foregroundColor(.green)
                    .fontWeight(.medium)
                
                Text("Lv.\(user.currentLevel)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Preview

struct FriendsView_Previews: PreviewProvider {
    static var previews: some View {
        FriendsView()
    }
}