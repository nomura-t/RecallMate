import SwiftUI

struct AddFriendView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var friendshipManager = EnhancedFriendshipManager.shared
    @State private var searchText = ""
    @State private var studyCode = ""
    @State private var searchResults: [EnhancedProfile] = []
    @State private var foundUser: EnhancedProfile?
    @State private var isSearching = false
    @State private var showUserProfile: EnhancedProfile?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 検索方法選択
                searchMethodPicker
                
                // 検索フィールド
                searchField
                
                // 検索結果
                searchResultsView
                
                Spacer()
            }
            .navigationTitle("フレンドを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $showUserProfile) { profile in
                SocialUserProfileView(profile: profile)
            }
        }
    }
    
    // MARK: - Search Method Picker
    
    @State private var selectedSearchMethod = 0 // 0: 名前/ユーザー名, 1: 学習コード
    
    private var searchMethodPicker: some View {
        Picker("検索方法", selection: $selectedSearchMethod) {
            Text("名前で検索").tag(0)
            Text("学習コードで検索").tag(1)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
    }
    
    // MARK: - Search Field
    
    private var searchField: some View {
        VStack(spacing: 16) {
            if selectedSearchMethod == 0 {
                // 名前/ユーザー名検索
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("名前またはユーザー名を入力", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            Task {
                                await searchByName()
                            }
                        }
                    
                    if isSearching {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding(.horizontal)
                
            } else {
                // 学習コード検索
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "number")
                            .foregroundColor(.secondary)
                        
                        TextField("学習コード（例: AB12CD34）", text: $studyCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.allCharacters)
                            .disableAutocorrection(true)
                            .onSubmit {
                                Task {
                                    await searchByStudyCode()
                                }
                            }
                        
                        if isSearching {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    
                    Text("💡 学習コードは各ユーザーのプロフィールで確認できます")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
        }
        .padding(.bottom)
    }
    
    // MARK: - Search Results
    
    private var searchResultsView: some View {
        Group {
            if selectedSearchMethod == 0 {
                // 名前検索結果
                nameSearchResults
            } else {
                // 学習コード検索結果
                studyCodeSearchResults
            }
        }
    }
    
    private var nameSearchResults: some View {
        Group {
            if searchText.isEmpty {
                searchSuggestions
            } else if searchResults.isEmpty && !isSearching {
                emptySearchResults
            } else {
                List(searchResults, id: \.id) { user in
                    AddFriendUserRowView(user: user) {
                        showUserProfile = user
                    } onFollow: {
                        Task {
                            let success = await friendshipManager.followUser(userId: user.id)
                            if success {
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var studyCodeSearchResults: some View {
        Group {
            if studyCode.isEmpty {
                studyCodeInstructions
            } else if let user = foundUser {
                VStack(spacing: 16) {
                    Text("ユーザーが見つかりました！")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    AddFriendUserRowView(user: user) {
                        showUserProfile = user
                    } onFollow: {
                        Task {
                            let success = await friendshipManager.followUser(userId: user.id)
                            if success {
                                dismiss()
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
            } else if !isSearching && !studyCode.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    
                    Text("ユーザーが見つかりません")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("学習コードを確認してもう一度お試しください")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
    }
    
    // MARK: - Helper Views
    
    private var searchSuggestions: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.badge.plus")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("フレンドを見つけよう")
                    .font(.headline)
                
                Text("名前またはユーザー名を入力して検索してください")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                suggestionButton(
                    icon: "magnifyingglass",
                    title: "名前で検索",
                    description: "表示名やユーザー名で検索"
                )
                
                suggestionButton(
                    icon: "number",
                    title: "学習コードで検索",
                    description: "8桁の学習コードで検索"
                )
            }
        }
        .padding()
    }
    
    private var studyCodeInstructions: some View {
        VStack(spacing: 20) {
            Image(systemName: "number.circle")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("学習コードで検索")
                    .font(.headline)
                
                Text("8桁の学習コード（例: AB12CD34）を入力してください")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "1.circle.fill")
                        .foregroundColor(.blue)
                    Text("相手のプロフィールで学習コードを確認")
                        .font(.subheadline)
                }
                
                HStack {
                    Image(systemName: "2.circle.fill")
                        .foregroundColor(.blue)
                    Text("上記のフィールドに学習コードを入力")
                        .font(.subheadline)
                }
                
                HStack {
                    Image(systemName: "3.circle.fill")
                        .foregroundColor(.blue)
                    Text("フォローボタンをタップして完了")
                        .font(.subheadline)
                }
            }
        }
        .padding()
    }
    
    private var emptySearchResults: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("検索結果なし")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("「\(searchText)」に一致するユーザーが見つかりません")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private func suggestionButton(icon: String, title: String, description: String) -> some View {
        Button {
            // 検索方法を切り替え
            selectedSearchMethod = (title == "学習コードで検索") ? 1 : 0
        } label: {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Search Functions
    
    private func searchByName() async {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        let results = await friendshipManager.searchUsers(query: searchText)
        
        await MainActor.run {
            searchResults = results
            isSearching = false
        }
    }
    
    private func searchByStudyCode() async {
        guard !studyCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            foundUser = nil
            return
        }
        
        isSearching = true
        
        let user = await friendshipManager.findUserByStudyCode(studyCode.uppercased())
        
        await MainActor.run {
            foundUser = user
            isSearching = false
        }
    }
}

// MARK: - Add Friend User Row View

struct AddFriendUserRowView: View {
    let user: EnhancedProfile
    let onTap: () -> Void
    let onFollow: () -> Void
    
    @StateObject private var friendshipManager = EnhancedFriendshipManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    
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
            .frame(width: 60, height: 60)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
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
                
                // 学習統計
                HStack {
                    Label("\(user.formattedStudyTime)", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Label("Lv.\(user.currentLevel)", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                // 自分自身の場合はボタンを表示しない
                if user.id != authManager.currentUser?.id.uuidString {
                    Button {
                        onFollow()
                    } label: {
                        Text(friendshipManager.isFollowing(userId: user.id) ? "フォロー中" : "フォロー")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                friendshipManager.isFollowing(userId: user.id) ?
                                Color.secondary : Color.blue
                            )
                            .cornerRadius(20)
                    }
                    .disabled(friendshipManager.isFollowing(userId: user.id))
                }
                
                Button("プロフィール") {
                    onTap()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

struct AddFriendView_Previews: PreviewProvider {
    static var previews: some View {
        AddFriendView()
    }
}