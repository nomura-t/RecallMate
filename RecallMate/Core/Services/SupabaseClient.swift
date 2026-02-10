import Foundation
import Supabase

class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    @Published var isConnected = false
    @Published var connectionStatus = "オフライン"
    @Published var currentUser: User?
    
    private init() {
        let url = URL(string: SupabaseConfig.supabaseURL) ?? URL(string: "https://placeholder.supabase.co")!
        if URL(string: SupabaseConfig.supabaseURL) == nil {
            print("⚠️ SupabaseManager: Invalid Supabase URL configured, using placeholder")
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