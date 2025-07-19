import Foundation
import Supabase

@MainActor
class DiscussionBoardManager: ObservableObject {
    static let shared = DiscussionBoardManager()
    
    @Published var posts: [BoardPost] = []
    @Published var categories: [BoardCategory] = []
    @Published var replies: [BoardReply] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseManager.shared.client
    
    private init() {}
    
    // MARK: - Public Methods (一時的に無効化)
    
    func loadPosts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedPosts: [BoardPost] = try await supabase
                .from("board_posts")
                .select("""
                    *,
                    board_categories(name, color),
                    profiles(username, full_name, avatar_url)
                """)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            posts = fetchedPosts
        } catch {
            errorMessage = "投稿の読み込みに失敗しました: \(error.localizedDescription)"
            print("Error loading posts: \(error)")
        }
        
        isLoading = false
    }
    
    func loadPosts(categoryId: String?) async {
        // categoryIdがnilの場合は全ての投稿を読み込み
        if categoryId == nil {
            await loadPosts()
            return
        }
        
        guard let categoryId = categoryId else { return }
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedPosts: [BoardPost] = try await supabase
                .from("board_posts")
                .select("""
                    *,
                    board_categories(name, color),
                    profiles(username, full_name, avatar_url)
                """)
                .eq("category_id", value: categoryId)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            posts = fetchedPosts
        } catch {
            errorMessage = "投稿の読み込みに失敗しました: \(error.localizedDescription)"
            print("Error loading posts for category: \(error)")
        }
        
        isLoading = false
    }
    
    func loadCategories() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedCategories: [BoardCategory] = try await supabase
                .from("board_categories")
                .select("*")
                .eq("is_active", value: true)
                .order("sort_order")
                .execute()
                .value
            
            categories = fetchedCategories
        } catch {
            errorMessage = "カテゴリの読み込みに失敗しました: \(error.localizedDescription)"
            print("Error loading categories: \(error)")
        }
        
        isLoading = false
    }
    
    func loadPosts(searchQuery: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedPosts: [BoardPost] = try await supabase
                .from("board_posts")
                .select("""
                    *,
                    board_categories(name, color),
                    profiles(username, full_name, avatar_url)
                """)
                .or("title.ilike.%\(searchQuery)%,content.ilike.%\(searchQuery)%")
                .order("created_at", ascending: false)
                .execute()
                .value
            
            posts = fetchedPosts
        } catch {
            errorMessage = "投稿の検索に失敗しました: \(error.localizedDescription)"
            print("Error searching posts: \(error)")
        }
        
        isLoading = false
    }
    
    func createPost(title: String, content: String, groupId: String?) async -> Bool {
        // 一時的な実装
        return false
    }
    
    func createPost(categoryId: String, title: String, content: String, tags: [String], isAnonymous: Bool) async -> Bool {
        guard let currentUser = SupabaseManager.shared.currentUser else {
            errorMessage = "ログインが必要です"
            return false
        }
        
        do {
            let newPost = CreatePostRequest(
                categoryId: categoryId,
                authorId: currentUser.id.uuidString,
                title: title,
                content: content,
                tags: tags,
                isAnonymous: isAnonymous
            )
            
            let _: BoardPost = try await supabase
                .from("board_posts")
                .insert(newPost)
                .execute()
                .value
            
            // 投稿一覧を再読み込み
            await loadPosts()
            return true
            
        } catch {
            errorMessage = "投稿の作成に失敗しました: \(error.localizedDescription)"
            print("Error creating post: \(error)")
            return false
        }
    }
    
    func loadReplies(postId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedReplies: [BoardReply] = try await supabase
                .from("board_replies")
                .select("""
                    *,
                    profiles(username, full_name, avatar_url)
                """)
                .eq("post_id", value: postId)
                .order("created_at", ascending: true)
                .execute()
                .value
            
            replies = fetchedReplies
        } catch {
            errorMessage = "返信の読み込みに失敗しました: \(error.localizedDescription)"
            print("Error loading replies: \(error)")
        }
        
        isLoading = false
    }
    
    func createReply(postId: String, content: String, isAnonymous: Bool) async -> Bool {
        guard let currentUser = SupabaseManager.shared.currentUser else {
            errorMessage = "ログインが必要です"
            return false
        }
        
        do {
            let newReply = CreateReplyRequest(
                postId: postId,
                authorId: currentUser.id.uuidString,
                content: content,
                isAnonymous: isAnonymous,
                parentReplyId: nil
            )
            
            let _: BoardReply = try await supabase
                .from("board_replies")
                .insert(newReply)
                .execute()
                .value
            
            // 返信一覧を再読み込み
            await loadReplies(postId: postId)
            return true
            
        } catch {
            errorMessage = "返信の作成に失敗しました: \(error.localizedDescription)"
            print("Error creating reply: \(error)")
            return false
        }
    }
    
    func likePost(_ postId: String) async -> Bool {
        guard let currentUser = SupabaseManager.shared.currentUser else {
            errorMessage = "ログインが必要です"
            return false
        }
        
        do {
            // まず既存のいいねがあるかチェック
            let existingLikes: [PostLike] = try await supabase
                .from("post_likes")
                .select("*")
                .eq("post_id", value: postId)
                .eq("user_id", value: currentUser.id.uuidString)
                .execute()
                .value
            
            if existingLikes.isEmpty {
                // いいねを追加
                let newLike = PostLike(
                    postId: postId,
                    userId: currentUser.id.uuidString
                )
                
                let _: PostLike = try await supabase
                    .from("post_likes")
                    .insert(newLike)
                    .execute()
                    .value
            } else {
                // いいねを削除
                try await supabase
                    .from("post_likes")
                    .delete()
                    .eq("post_id", value: postId)
                    .eq("user_id", value: currentUser.id.uuidString)
                    .execute()
            }
            
            // 投稿一覧を再読み込み
            await loadPosts()
            return true
            
        } catch {
            errorMessage = "いいねの操作に失敗しました: \(error.localizedDescription)"
            print("Error liking post: \(error)")
            return false
        }
    }
    
    func addReply(to postId: String, content: String) async -> Bool {
        // 一時的な実装
        return false
    }
    
    func deletePost(_ postId: String) async -> Bool {
        // 一時的な実装
        return false
    }
    
    func deleteReply(_ replyId: String) async -> Bool {
        // 一時的な実装
        return false
    }
    
    func editPost(_ postId: String, newContent: String) async -> Bool {
        // 一時的な実装
        return false
    }
    
    func editReply(_ replyId: String, newContent: String) async -> Bool {
        // 一時的な実装
        return false
    }
    
    func reportPost(_ postId: String, reason: String) async -> Bool {
        // 一時的な実装
        return false
    }
    
    func reportReply(_ replyId: String, reason: String) async -> Bool {
        // 一時的な実装
        return false
    }
    
    func startListening() async {
        // 一時的な実装
    }
    
    func stopListening() {
        // 一時的な実装
    }
}

// MARK: - Data Models for API Requests

struct CreatePostRequest: Codable {
    let categoryId: String
    let authorId: String
    let title: String
    let content: String
    let tags: [String]
    let isAnonymous: Bool
    
    enum CodingKeys: String, CodingKey {
        case categoryId = "category_id"
        case authorId = "author_id"
        case title
        case content
        case tags
        case isAnonymous = "is_anonymous"
    }
}

struct CreateReplyRequest: Codable {
    let postId: String
    let authorId: String
    let content: String
    let isAnonymous: Bool
    let parentReplyId: String?
    
    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case authorId = "author_id"
        case content
        case isAnonymous = "is_anonymous"
        case parentReplyId = "parent_reply_id"
    }
}

struct PostLike: Codable {
    let postId: String
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case userId = "user_id"
    }
}