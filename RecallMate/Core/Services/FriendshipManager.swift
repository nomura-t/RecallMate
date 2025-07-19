import Foundation
import Supabase

// MARK: - Enhanced Data Models
struct UserProfile: Codable, Identifiable {
    let id: String
    let username: String?
    let fullName: String?
    let nickname: String?
    let studyCode: String?
    let avatarUrl: String?
    let isStudying: Bool
    let studyStartTime: Date?
    let totalStudyMinutes: Int
    let levelPoints: Int
    let currentLevel: Int
    let statusMessage: String?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case fullName = "full_name"
        case nickname
        case studyCode = "study_code"
        case avatarUrl = "avatar_url"
        case isStudying = "is_studying"
        case studyStartTime = "study_start_time"
        case totalStudyMinutes = "total_study_minutes"
        case levelPoints = "level_points"
        case currentLevel = "current_level"
        case statusMessage = "status_message"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    var displayName: String {
        return nickname ?? fullName ?? username ?? "名無しユーザー"
    }
    
    var formattedTotalStudyTime: String {
        let hours = totalStudyMinutes / 60
        let minutes = totalStudyMinutes % 60
        return hours > 0 ? "\(hours)時間\(minutes)分" : "\(minutes)分"
    }
}

struct Friendship: Codable, Identifiable {
    let id: String
    let userId: String
    let friendId: String
    let status: String
    let createdAt: Date
    let acceptedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case friendId = "friend_id"
        case status
        case createdAt = "created_at"
        case acceptedAt = "accepted_at"
    }
}

struct FriendInfo: Codable, Identifiable {
    let userId: String
    let friendId: String
    let friendStudyCode: String?
    let friendNickname: String?
    let friendFullName: String?
    let createdAt: Date
    let acceptedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case friendId = "friend_id"
        case friendStudyCode = "friend_study_code"
        case friendNickname = "friend_nickname"
        case friendFullName = "friend_full_name"
        case createdAt = "created_at"
        case acceptedAt = "accepted_at"
    }
    
    var id: String { friendId }
    
    var displayName: String {
        return friendNickname ?? friendFullName ?? "名無しユーザー"
    }
}

// MARK: - API Response Models
struct FriendshipResponse: Codable {
    let success: Bool
    let error: String?
    let friendId: String?
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case error
        case friendId = "friend_id"
        case message
    }
}

// MARK: - Friendship Manager
@MainActor
class FriendshipManager: ObservableObject {
    static let shared = FriendshipManager()
    
    @Published var currentUserProfile: UserProfile?
    @Published var friends: [FriendInfo] = []
    @Published var enhancedFriends: [EnhancedFriend] = []
    @Published var friendRequests: [FriendRequest] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabaseClient = SupabaseManager.shared.client
    
    private init() {}
    
    // MARK: - User Profile Management
    
    func loadCurrentUserProfile() async {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            print("❌ FriendshipManager: ユーザーがサインインしていません")
            errorMessage = "ユーザーがサインインしていません"
            return
        }
        
        print("🔍 FriendshipManager: プロフィール読み込み開始 - UserID: \(userId)")
        print("🔍 ユーザーID文字列: \(userId.uuidString)")
        isLoading = true
        
        do {
            // Try to get the profile directly
            let profile: UserProfile = try await supabaseClient
                .from("profiles")
                .select("*")
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            
            print("✅ FriendshipManager: プロフィール読み込み成功")
            print("📋 プロフィール詳細:")
            print("   - ID: \(profile.id)")
            print("   - 表示名: \(profile.displayName)")
            print("   - 学習コード: \(profile.studyCode ?? "未設定")")
            print("   - 作成日: \(profile.createdAt?.formatted() ?? "不明")")
            
            currentUserProfile = profile
            errorMessage = nil
        } catch {
            print("❌ FriendshipManager: プロフィール読み込みエラー - \(error)")
            print("🔍 エラー詳細: \(error.localizedDescription)")
            
            // Try to create profile if it doesn't exist
            if error.localizedDescription.contains("No rows") || error.localizedDescription.contains("single") {
                print("🔄 プロフィールが存在しないため作成を試行")
                await createMissingProfile(userId: userId)
            } else {
                errorMessage = "プロフィールの読み込みに失敗しました: \(error.localizedDescription)"
            }
        }
        
        isLoading = false
    }
    
    private func createMissingProfile(userId: UUID) async {
        print("🔨 FriendshipManager: 欠落プロフィール作成開始")
        
        do {
            // Generate a study code
            let studyCode: String = try await supabaseClient
                .rpc("generate_study_code")
                .execute()
                .value
            
            print("✅ 学習コード生成成功: \(studyCode)")
            
            // Create the profile
            let newProfile = [
                "id": userId.uuidString,
                "study_code": studyCode,
                "nickname": "新規ユーザー",
                "created_at": Date().ISO8601Format(),
                "updated_at": Date().ISO8601Format()
            ]
            
            try await supabaseClient
                .from("profiles")
                .insert(newProfile)
                .execute()
            
            print("✅ プロフィール作成成功")
            
            // Also create study stats
            let newStats = [
                "user_id": userId.uuidString,
                "total_study_time": "0 seconds",
                "weekly_study_time": "0 seconds",
                "daily_study_time": "0 seconds",
                "longest_streak": "0",
                "current_streak": "0",
                "is_currently_studying": "false",
                "updated_at": Date().ISO8601Format()
            ]
            
            try await supabaseClient
                .from("user_study_stats")
                .insert(newStats)
                .execute()
            
            print("✅ 学習統計作成成功")
            
            // Reload profile
            await loadCurrentUserProfile()
            
        } catch {
            print("❌ プロフィール作成エラー: \(error)")
            errorMessage = "プロフィールの作成に失敗しました: \(error.localizedDescription)"
        }
    }
    
    func updateNickname(_ nickname: String) async -> Bool {
        guard let userId = SupabaseManager.shared.currentUser?.id else { return false }
        
        do {
            try await supabaseClient
                .from("profiles")
                .update(["nickname": nickname])
                .eq("id", value: userId)
                .execute()
            
            await loadCurrentUserProfile()
            return true
        } catch {
            print("Nickname update error: \(error)")
            errorMessage = "ニックネームの更新に失敗しました"
            return false
        }
    }
    
    // MARK: - Profile Update
    
    func updateProfile(
        fullName: String,
        nickname: String?,
        bio: String?,
        avatarIconId: String
    ) async -> Bool {
        guard let userId = SupabaseManager.shared.currentUser?.id else { 
            errorMessage = "ユーザーがサインインしていません"
            return false 
        }
        
        // Supabase設定チェック
        if SupabaseConfig.supabaseURL == "https://your-project-id.supabase.co" {
            return await updateProfileOffline(
                fullName: fullName,
                nickname: nickname,
                bio: bio,
                avatarIconId: avatarIconId
            )
        }
        
        do {
            print("🔄 プロフィール更新開始")
            
            // Create an encodable struct for the update
            struct ProfileUpdate: Encodable {
                let full_name: String
                let avatar_url: String
                let updated_at: String
                let nickname: String?
                let status_message: String?
            }
            
            let updateData = ProfileUpdate(
                full_name: fullName,
                avatar_url: avatarIconId,
                updated_at: Date().ISO8601Format(),
                nickname: nickname,
                status_message: bio
            )
            
            try await supabaseClient
                .from("profiles")
                .update(updateData)
                .eq("id", value: userId)
                .execute()
            
            print("✅ プロフィール更新成功")
            
            // ローカルプロフィールを更新
            await loadCurrentUserProfile()
            
            return true
            
        } catch {
            print("❌ プロフィール更新エラー: \(error)")
            errorMessage = "プロフィールの更新に失敗しました: \(error.localizedDescription)"
            return false
        }
    }
    
    private func updateProfileOffline(
        fullName: String,
        nickname: String?,
        bio: String?,
        avatarIconId: String
    ) async -> Bool {
        print("🔄 オフラインプロフィール更新開始")
        
        // オフラインモードでは現在のプロフィールを直接更新
        if var profile = currentUserProfile {
            profile = UserProfile(
                id: profile.id,
                username: profile.username,
                fullName: fullName,
                nickname: nickname,
                studyCode: profile.studyCode,
                avatarUrl: avatarIconId,
                isStudying: profile.isStudying,
                studyStartTime: profile.studyStartTime,
                totalStudyMinutes: profile.totalStudyMinutes,
                levelPoints: profile.levelPoints,
                currentLevel: profile.currentLevel,
                statusMessage: bio,
                createdAt: profile.createdAt,
                updatedAt: Date()
            )
            
            currentUserProfile = profile
            print("✅ オフラインプロフィール更新成功")
            return true
        }
        
        return false
    }
    
    // MARK: - Friend Management
    
    func loadFriends() async {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            errorMessage = "ユーザーがサインインしていません"
            return
        }
        
        isLoading = true
        
        do {
            let friendsList: [FriendInfo] = try await supabaseClient
                .from("user_friends")
                .select("*")
                .eq("user_id", value: userId)
                .execute()
                .value
            
            friends = friendsList
            errorMessage = nil
        } catch {
            print("Friends load error: \(error)")
            errorMessage = "フレンド一覧の読み込みに失敗しました"
        }
        
        isLoading = false
    }
    
    func addFriend(studyCode: String) async -> Bool {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            errorMessage = "ユーザーがサインインしていません"
            return false
        }
        
        isLoading = true
        
        do {
            // RPC call with proper parameter structure
            struct CreateFriendshipParams: Codable {
                let requesting_user_id: String
                let target_study_code: String
            }
            
            let params = CreateFriendshipParams(
                requesting_user_id: userId.uuidString,
                target_study_code: studyCode.uppercased()
            )
            
            let response: FriendshipResponse = try await supabaseClient
                .rpc("create_mutual_friendship", params: params)
                .execute()
                .value
            
            if response.success {
                await loadFriends()
                errorMessage = nil
                isLoading = false
                return true
            } else {
                errorMessage = response.error ?? "フレンド追加に失敗しました"
                isLoading = false
                return false
            }
        } catch {
            print("Add friend error: \(error)")
            errorMessage = "フレンド追加に失敗しました"
            isLoading = false
            return false
        }
    }
    
    func removeFriend(friendId: String) async -> Bool {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            errorMessage = "ユーザーがサインインしていません"
            return false
        }
        
        isLoading = true
        
        do {
            // Remove both directions of friendship
            try await supabaseClient
                .from("friendships")
                .delete()
                .or("and(user_id.eq.\(userId),friend_id.eq.\(friendId)),and(user_id.eq.\(friendId),friend_id.eq.\(userId))")
                .execute()
            
            await loadFriends()
            errorMessage = nil
            isLoading = false
            return true
        } catch {
            print("Remove friend error: \(error)")
            errorMessage = "フレンド削除に失敗しました"
            isLoading = false
            return false
        }
    }
    
    // MARK: - Utility Methods
    
    func generateNewStudyCode() async -> Bool {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            print("❌ FriendshipManager: 学習コード生成失敗 - ユーザー未認証")
            return false
        }
        
        print("🔄 FriendshipManager: 学習コード生成開始 - UserID: \(userId)")
        
        do {
            // Call the generate_study_code function and update profile
            print("🎲 学習コード生成関数を呼び出し中...")
            let newCode: String = try await supabaseClient
                .rpc("generate_study_code")
                .execute()
                .value
            
            print("✅ 新しい学習コード生成: \(newCode)")
            
            print("💾 プロフィールに学習コードを保存中...")
            try await supabaseClient
                .from("profiles")
                .update(["study_code": newCode])
                .eq("id", value: userId)
                .execute()
            
            print("✅ 学習コード保存完了")
            print("🔄 プロフィール再読み込み中...")
            await loadCurrentUserProfile()
            print("✅ 学習コード生成プロセス完了")
            return true
        } catch {
            print("❌ FriendshipManager: 学習コード生成エラー - \(error)")
            print("🔍 エラー詳細: \(error.localizedDescription)")
            errorMessage = "学習コードの生成に失敗しました: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Enhanced Friend Management
    
    /// 拡張フレンド一覧の読み込み（学習状態を含む）
    func loadEnhancedFriends() async {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            errorMessage = "ユーザーがサインインしていません"
            return
        }
        
        isLoading = true
        
        do {
            let friendsList: [EnhancedFriend] = try await supabaseClient
                .from("user_friends_enhanced")
                .select("*")
                .eq("user_id", value: userId)
                .execute()
                .value
            
            enhancedFriends = friendsList
            errorMessage = nil
            print("✅ 拡張フレンド一覧読み込み成功: \(friendsList.count)人")
        } catch {
            print("❌ 拡張フレンド読み込みエラー: \(error)")
            errorMessage = "フレンド一覧の読み込みに失敗しました"
        }
        
        isLoading = false
    }
    
    /// 学習コードでフレンド追加（改良版）
    func addFriendByCode(_ studyCode: String) async -> Bool {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            errorMessage = "ユーザーがサインインしていません"
            return false
        }
        
        guard !studyCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "学習コードを入力してください"
            return false
        }
        
        isLoading = true
        
        do {
            struct AddFriendParams: Codable {
                let requesting_user_id: String
                let target_study_code: String
            }
            
            let params = AddFriendParams(
                requesting_user_id: userId.uuidString,
                target_study_code: studyCode.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            let response: AddFriendResponse = try await supabaseClient
                .rpc("add_friend_by_code", params: params)
                .execute()
                .value
            
            if response.success {
                await loadEnhancedFriends()
                await loadFriends() // 既存のフレンド一覧も更新
                errorMessage = nil
                isLoading = false
                return true
            } else {
                errorMessage = response.error ?? "フレンド追加に失敗しました"
                isLoading = false
                return false
            }
        } catch {
            print("❌ フレンド追加エラー: \(error)")
            errorMessage = "フレンド追加に失敗しました: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// フレンドの削除（改良版）
    func removeFriendEnhanced(friendId: String) async -> Bool {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            errorMessage = "ユーザーがサインインしていません"
            return false
        }
        
        isLoading = true
        
        do {
            // 双方向のフレンド関係を削除
            try await supabaseClient
                .from("friendships")
                .delete()
                .or("and(user_id.eq.\(userId.uuidString),friend_id.eq.\(friendId)),and(user_id.eq.\(friendId),friend_id.eq.\(userId.uuidString))")
                .execute()
            
            // 両方のフレンド一覧を更新
            await loadEnhancedFriends()
            await loadFriends()
            errorMessage = nil
            isLoading = false
            return true
        } catch {
            print("❌ フレンド削除エラー: \(error)")
            errorMessage = "フレンド削除に失敗しました"
            isLoading = false
            return false
        }
    }
    
    /// ステータスメッセージの更新
    func updateStatusMessage(_ message: String) async -> Bool {
        guard let userId = SupabaseManager.shared.currentUser?.id else { return false }
        
        do {
            try await supabaseClient
                .from("profiles")
                .update(["status_message": message])
                .eq("id", value: userId)
                .execute()
            
            await loadCurrentUserProfile()
            return true
        } catch {
            print("❌ ステータスメッセージ更新エラー: \(error)")
            errorMessage = "ステータスメッセージの更新に失敗しました"
            return false
        }
    }
    
    /// フレンドの学習統計取得
    func getFriendSocialStudyStats(friendId: String) async -> SocialStudyStats? {
        do {
            let stats: SocialStudyStats = try await supabaseClient
                .from("user_study_stats")
                .select("*")
                .eq("user_id", value: friendId)
                .single()
                .execute()
                .value
            
            return stats
        } catch {
            print("❌ フレンド学習統計取得エラー: \(error)")
            return nil
        }
    }
    
    /// 全データの更新（拡張版）
    func refreshAllData() async {
        await loadCurrentUserProfile()
        await loadFriends()
        await loadEnhancedFriends()
    }
    
    // MARK: - Legacy compatibility
    func refreshData() async {
        await refreshAllData()
    }
}