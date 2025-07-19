import SwiftUI

struct DiscussionBoardView: View {
    @StateObject private var boardManager = DiscussionBoardManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var selectedCategory: BoardCategory?
    @State private var searchText = ""
    @State private var showCreatePostSheet = false
    @State private var selectedPost: BoardPost?
    
    var body: some View {
        NavigationView {
            VStack {
                // カテゴリー選択
                categorySelector
                
                // 検索バー
                searchBar
                
                // 投稿リスト
                postsList
            }
            .navigationTitle("掲示板")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreatePostSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showCreatePostSheet) {
                CreatePostView()
            }
            .sheet(item: $selectedPost) { post in
                PostDetailView(post: post)
            }
            .onAppear {
                Task {
                    await boardManager.loadCategories()
                    await boardManager.loadPosts()
                }
            }
        }
    }
    
    // MARK: - Category Selector
    
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                // 全て
                CategoryChipView(
                    category: nil,
                    isSelected: selectedCategory == nil,
                    onTap: {
                        selectedCategory = nil
                        Task {
                            await boardManager.loadPosts()
                        }
                    }
                )
                
                // カテゴリー
                ForEach(boardManager.categories, id: \.id) { category in
                    CategoryChipView(
                        category: category,
                        isSelected: selectedCategory?.id == category.id,
                        onTap: {
                            selectedCategory = category
                            Task {
                                await boardManager.loadPosts(categoryId: category.id)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("投稿を検索", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    Task {
                        await boardManager.loadPosts(searchQuery: searchText)
                    }
                }
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    Task {
                        await boardManager.loadPosts(categoryId: selectedCategory?.id)
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Posts List
    
    private var postsList: some View {
        Group {
            if boardManager.posts.isEmpty {
                emptyStateView
            } else {
                List(boardManager.posts, id: \.id) { post in
                    PostRowView(post: post) {
                        selectedPost = post
                    }
                }
                .refreshable {
                    await boardManager.loadPosts(categoryId: selectedCategory?.id)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("投稿がありません")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("新しい投稿を作成して議論を始めましょう")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("投稿を作成") {
                showCreatePostSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Category Chip View

struct CategoryChipView: View {
    let category: BoardCategory?
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            HStack {
                if let category = category {
                    if let icon = category.icon {
                        Image(systemName: icon)
                            .font(.caption)
                    }
                    Text(category.name)
                        .font(.subheadline)
                } else {
                    Text("全て")
                        .font(.subheadline)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isSelected ? Color.blue : Color.gray.opacity(0.2)
            )
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
    }
}

// MARK: - Post Row View

struct PostRowView: View {
    let post: BoardPost
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // ヘッダー
            HStack {
                // 作成者情報
                if !post.isAnonymous {
                    AsyncImage(url: URL(string: post.author?.avatarUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                                    .font(.caption)
                            )
                    }
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(post.author?.displayName ?? "Unknown")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Text(post.createdAt.timeAgo)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "person.fill.questionmark")
                                .foregroundColor(.white)
                                .font(.caption)
                        )
                        .frame(width: 30, height: 30)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("匿名")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Text(post.createdAt.timeAgo)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // カテゴリー
                if let category = post.category {
                    HStack {
                        if let icon = category.icon {
                            Image(systemName: icon)
                                .font(.caption)
                        }
                        Text(category.name)
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                }
            }
            
            // タイトル
            Text(post.title)
                .font(.headline)
                .fontWeight(.semibold)
                .lineLimit(2)
            
            // 内容プレビュー
            Text(post.content)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            // タグ
            if let tags = post.tags, !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            // 統計情報
            HStack {
                Label("\(post.viewCount)", systemImage: "eye")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label("\(post.likeCount)", systemImage: "heart")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label("\(post.replyCount)", systemImage: "bubble.left")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if post.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                if post.isLocked {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Create Post View

struct CreatePostView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var boardManager = DiscussionBoardManager.shared
    @State private var selectedCategory: BoardCategory?
    @State private var title = ""
    @State private var content = ""
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var isAnonymous = false
    @State private var isCreating = false
    
    var body: some View {
        NavigationView {
            Form {
                categorySection
                titleSection
                contentSection
                tagsSection
                settingsSection
            }
            .navigationTitle("投稿を作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    cancelButton
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    postButton
                }
            }
            .disabled(isCreating)
            .overlay(loadingOverlay)
        }
        .onAppear {
            if boardManager.categories.isEmpty {
                Task {
                    await boardManager.loadCategories()
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var categorySection: some View {
        Section(header: Text("カテゴリー")) {
            Picker("カテゴリーを選択", selection: $selectedCategory) {
                ForEach(boardManager.categories, id: \.id) { category in
                    HStack {
                        if let icon = category.icon {
                            Image(systemName: icon)
                        }
                        Text(category.name)
                    }
                    .tag(category as BoardCategory?)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }
    
    private var titleSection: some View {
        Section(header: Text("タイトル")) {
            TextField("投稿タイトル", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
    
    private var contentSection: some View {
        Section(header: Text("内容")) {
            TextField("投稿内容", text: $content, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(5...15)
        }
    }
    
    private var tagsSection: some View {
        Section(header: Text("タグ"), footer: Text("関連するキーワードを追加してください")) {
            if !tags.isEmpty {
                existingTagsView
            }
            newTagInputView
        }
    }
    
    private var existingTagsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(tags, id: \.self) { tag in
                    tagChip(tag: tag)
                }
            }
        }
    }
    
    private func tagChip(tag: String) -> some View {
        HStack {
            Text("#\(tag)")
                .font(.caption)
            
            Button {
                tags.removeAll { $0 == tag }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(8)
    }
    
    private var newTagInputView: some View {
        HStack {
            TextField("新しいタグ", text: $newTag)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    addTag()
                }
            
            Button("追加") {
                addTag()
            }
            .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
    
    private var settingsSection: some View {
        Section(header: Text("設定")) {
            Toggle("匿名で投稿", isOn: $isAnonymous)
        }
    }
    
    private var cancelButton: some View {
        Button("キャンセル") {
            dismiss()
        }
    }
    
    private var postButton: some View {
        Button("投稿") {
            Task {
                await createPost()
            }
        }
        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                 content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                 selectedCategory == nil ||
                 isCreating)
    }
    
    private var loadingOverlay: some View {
        Group {
            if isCreating {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
        }
    }
    
    private func addTag() {
        let tag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tag.isEmpty && !tags.contains(tag) {
            tags.append(tag)
            newTag = ""
        }
    }
    
    private func createPost() async {
        guard let category = selectedCategory else { return }
        
        isCreating = true
        
        let success = await boardManager.createPost(
            categoryId: category.id,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            tags: tags,
            isAnonymous: isAnonymous
        )
        
        isCreating = false
        
        if success {
            dismiss()
        }
    }
}

// MARK: - Post Detail View

struct PostDetailView: View {
    let post: BoardPost
    @Environment(\.dismiss) private var dismiss
    @StateObject private var boardManager = DiscussionBoardManager.shared
    @State private var replyText = ""
    @State private var showReplySheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 投稿詳細
                    postDetailContent
                    
                    Divider()
                    
                    // 返信セクション
                    repliesSection
                }
                .padding()
            }
            .navigationTitle("投稿詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("返信") {
                        showReplySheet = true
                    }
                }
            }
            .sheet(isPresented: $showReplySheet) {
                ReplyToPostView(post: post)
            }
            .onAppear {
                Task {
                    await boardManager.loadReplies(postId: post.id)
                }
            }
        }
    }
    
    private var postDetailContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 投稿者情報
            HStack {
                if !post.isAnonymous {
                    AsyncImage(url: URL(string: post.author?.avatarUrl ?? "")) { image in
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
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(post.author?.displayName ?? "Unknown")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(post.createdAt.timeAgo)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "person.fill.questionmark")
                                .foregroundColor(.white)
                        )
                        .frame(width: 40, height: 40)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("匿名")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(post.createdAt.timeAgo)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // カテゴリー
                if let category = post.category {
                    HStack {
                        if let icon = category.icon {
                            Image(systemName: icon)
                                .font(.caption)
                        }
                        Text(category.name)
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                }
            }
            
            // タイトル
            Text(post.title)
                .font(.title2)
                .fontWeight(.bold)
            
            // 内容
            Text(post.content)
                .font(.body)
            
            // タグ
            if let tags = post.tags, !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            // 統計情報
            HStack {
                Label("\(post.viewCount)", systemImage: "eye")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label("\(post.likeCount)", systemImage: "heart")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label("\(post.replyCount)", systemImage: "bubble.left")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var repliesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("返信 (\(boardManager.replies.count))")
                .font(.headline)
            
            if boardManager.replies.isEmpty {
                Text("返信がありません")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(boardManager.replies, id: \.id) { reply in
                    ReplyRowView(reply: reply)
                }
            }
        }
    }
}

// MARK: - Reply Row View

struct ReplyRowView: View {
    let reply: BoardReply
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if !reply.isAnonymous {
                    AsyncImage(url: URL(string: reply.author?.avatarUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                                    .font(.caption)
                            )
                    }
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(reply.author?.displayName ?? "Unknown")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Text(reply.createdAt.timeAgo)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "person.fill.questionmark")
                                .foregroundColor(.white)
                                .font(.caption)
                        )
                        .frame(width: 30, height: 30)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("匿名")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Text(reply.createdAt.timeAgo)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Label("\(reply.likeCount)", systemImage: "heart")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(reply.content)
                .font(.subheadline)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Reply To Post View

struct ReplyToPostView: View {
    let post: BoardPost
    @Environment(\.dismiss) private var dismiss
    @StateObject private var boardManager = DiscussionBoardManager.shared
    @State private var replyText = ""
    @State private var isAnonymous = false
    @State private var isReplying = false
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                // 元の投稿
                VStack(alignment: .leading, spacing: 8) {
                    Text("返信先")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(post.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(post.content)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // 返信入力
                VStack(alignment: .leading, spacing: 8) {
                    Text("返信内容")
                        .font(.headline)
                    
                    TextField("返信を入力してください", text: $replyText, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(5...15)
                }
                
                // 設定
                Toggle("匿名で返信", isOn: $isAnonymous)
                
                Spacer()
            }
            .padding()
            .navigationTitle("返信を作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("返信") {
                        Task {
                            await createReply()
                        }
                    }
                    .disabled(replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isReplying)
                }
            }
            .disabled(isReplying)
            .overlay(
                Group {
                    if isReplying {
                        ZStack {
                            Color.black.opacity(0.3)
                                .ignoresSafeArea()
                            ProgressView()
                                .scaleEffect(1.5)
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                    }
                }
            )
        }
    }
    
    private func createReply() async {
        isReplying = true
        
        let success = await boardManager.createReply(
            postId: post.id,
            content: replyText.trimmingCharacters(in: .whitespacesAndNewlines),
            isAnonymous: isAnonymous
        )
        
        isReplying = false
        
        if success {
            dismiss()
        }
    }
}

// MARK: - Extensions

extension Date {
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - Preview

struct DiscussionBoardView_Previews: PreviewProvider {
    static var previews: some View {
        DiscussionBoardView()
    }
}