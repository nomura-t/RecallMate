import Foundation
import Supabase

class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    @Published var isConnected = false
    @Published var connectionStatus = "オフライン"
    @Published var currentUser: User?
    @Published var onlineFriends: [String] = []
    
    private init() {
        guard let url = URL(string: SupabaseConfig.supabaseURL) else {
            fatalError("Invalid Supabase URL")
        }
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: SupabaseConfig.supabaseAnonKey
        )
    }
    
    func connect() async {
        await MainActor.run {
            self.connectionStatus = "接続中..."
        }
        
        do {
            // Test connection by attempting to get session
            let session = try await client.auth.session
            await MainActor.run {
                self.isConnected = true
                self.currentUser = session.user
                self.connectionStatus = "認証済み"
            }
        } catch {
            print("Supabase connection error: \(error)")
            await MainActor.run {
                self.isConnected = false
                self.connectionStatus = "接続エラー: \(error.localizedDescription)"
            }
        }
    }
    
    func disconnect() {
        self.isConnected = false
        self.connectionStatus = "オフライン"
        self.currentUser = nil
        self.onlineFriends = []
    }
    
    // Test connection to Supabase
    func testConnection() async -> Bool {
        do {
            // Simple query to test database connectivity
            let _: [Profile] = try await client
                .from("profiles")
                .select("id")
                .limit(1)
                .execute()
                .value
            
            await MainActor.run {
                self.isConnected = true
                self.connectionStatus = "データベース接続確認済み"
            }
            return true
        } catch {
            print("Database connection test failed: \(error)")
            await MainActor.run {
                self.isConnected = false
                self.connectionStatus = "データベース接続エラー: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    // Sign in anonymously for testing
    func signInAnonymously() async {
        do {
            let response = try await client.auth.signInAnonymously()
            await MainActor.run {
                self.currentUser = response.user
                self.connectionStatus = "匿名ユーザーでサインイン完了"
                self.isConnected = true
            }
        } catch {
            print("Anonymous sign in failed: \(error)")
            await MainActor.run {
                self.connectionStatus = "匿名サインインエラー: \(error.localizedDescription)"
            }
        }
    }
    
    // Sign in with test email for development
    func signInWithTestEmail() async {
        do {
            let testEmail = "test@recallmate.app"
            let testPassword = "test123456"
            
            // Try to sign up first, then sign in
            do {
                let signUpResponse = try await client.auth.signUp(
                    email: testEmail,
                    password: testPassword
                )
                await MainActor.run {
                    self.currentUser = signUpResponse.user
                    self.connectionStatus = "テストアカウント作成完了"
                    self.isConnected = true
                }
            } catch {
                // If signup fails (user exists), try sign in
                let signInResponse = try await client.auth.signIn(
                    email: testEmail,
                    password: testPassword
                )
                await MainActor.run {
                    self.currentUser = signInResponse.user
                    self.connectionStatus = "テストアカウントでサインイン完了"
                    self.isConnected = true
                }
            }
        } catch {
            print("Test email sign in failed: \(error)")
            await MainActor.run {
                self.connectionStatus = "テストサインインエラー: \(error.localizedDescription)"
            }
        }
    }
    
    // Check online friends (mock implementation)
    func checkOnlineFriends() async {
        guard isConnected else { return }
        
        // Mock implementation - in real app, this would query actual friend status
        let mockFriends = ["友達A", "友達B", "友達C"]
        let randomOnlineFriends = mockFriends.shuffled().prefix(Int.random(in: 0...3))
        
        await MainActor.run {
            self.onlineFriends = Array(randomOnlineFriends)
        }
    }
    
    // Test discussion board connection
    func testDiscussionBoard() async -> Bool {
        do {
            // Test loading categories
            let categories: [BoardCategory] = try await client
                .from("board_categories")
                .select("*")
                .eq("is_active", value: true)
                .order("sort_order")
                .execute()
                .value
            
            await MainActor.run {
                self.connectionStatus = "掲示板テスト成功: \(categories.count)個のカテゴリを確認"
            }
            
            print("Discussion board test successful. Found \(categories.count) categories:")
            for category in categories {
                print("- \(category.name)")
            }
            
            return true
        } catch {
            print("Discussion board test failed: \(error)")
            await MainActor.run {
                self.connectionStatus = "掲示板テストエラー: \(error.localizedDescription)"
            }
            return false
        }
    }
}

// Profile model for database queries
struct Profile: Codable {
    let id: String
    let username: String?
    let fullName: String?
    let avatarUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
    }
}