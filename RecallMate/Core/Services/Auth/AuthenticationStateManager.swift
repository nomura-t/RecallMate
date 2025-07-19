import Foundation
import Supabase
import SwiftUI

// MARK: - Authentication State Manager

@MainActor
class AuthenticationStateManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var userProfile: UserProfile?
    @Published var authenticationState: AuthenticationState = .initial
    
    private let supabaseClient = SupabaseManager.shared.client
    
    enum AuthenticationState {
        case initial
        case signedOut
        case signingIn
        case signedIn
        case error(String)
    }
    
    init() {
        Task {
            await setupAuthStateListener()
        }
    }
    
    // MARK: - Auth State Management
    
    private func setupAuthStateListener() async {
        for await (event, session) in supabaseClient.auth.authStateChanges {
            await handleAuthStateChange(event, session: session)
        }
    }
    
    private func handleAuthStateChange(_ event: AuthChangeEvent, session: Session?) async {
        switch event {
        case .signedIn:
            if let session = session {
                print("✅ AuthenticationStateManager: ユーザーがサインインしました")
                currentUser = session.user
                isAuthenticated = true
                authenticationState = .signedIn
                
                await loadUserProfile()
                await initializeServices()
            }
            
        case .signedOut:
            print("📤 AuthenticationStateManager: ユーザーがサインアウトしました")
            currentUser = nil
            userProfile = nil
            isAuthenticated = false
            authenticationState = .signedOut
            
            cleanupServices()
            
        case .tokenRefreshed:
            if let session = session {
                print("🔄 AuthenticationStateManager: トークンが更新されました")
                currentUser = session.user
            }
            
        case .userUpdated:
            if let session = session {
                print("👤 AuthenticationStateManager: ユーザー情報が更新されました")
                currentUser = session.user
                await loadUserProfile()
            }
            
        case .userDeleted:
            print("🗑️ AuthenticationStateManager: ユーザーが削除されました")
            currentUser = nil
            userProfile = nil
            isAuthenticated = false
            authenticationState = .signedOut
            
        case .initialSession:
            print("📱 AuthenticationStateManager: 初期セッションが検出されました")
            if let session = session {
                currentUser = session.user
                isAuthenticated = true
                authenticationState = .signedIn
                
                await loadUserProfile()
                await initializeServices()
            } else {
                authenticationState = .signedOut
            }
            
        default:
            print("❓ AuthenticationStateManager: 不明な認証状態変更")
        }
    }
    
    // MARK: - Profile Management
    
    private func loadUserProfile() async {
        guard currentUser?.id != nil else {
            print("⚠️ AuthenticationStateManager: ユーザーIDが見つかりません")
            return
        }
        
        await FriendshipManager.shared.loadCurrentUserProfile()
        
        if let profile = FriendshipManager.shared.currentUserProfile {
            userProfile = profile
            print("✅ AuthenticationStateManager: プロフィール読み込み成功")
        } else {
            print("⚠️ AuthenticationStateManager: プロフィールが見つかりません")
        }
    }
    
    // MARK: - Service Management
    
    private func initializeServices() async {
        print("🔄 AuthenticationStateManager: サービス初期化開始")
        
        await FriendshipManager.shared.refreshAllData()
        await StudyGroupManager.shared.refreshAllData()
        
        print("✅ AuthenticationStateManager: サービス初期化完了")
    }
    
    private func cleanupServices() {
        print("🧹 AuthenticationStateManager: サービスクリーンアップ開始")
        
        FriendshipManager.shared.currentUserProfile = nil
        FriendshipManager.shared.friends = []
        FriendshipManager.shared.enhancedFriends = []
        
        StudySessionManager.shared.currentSession = nil
        
        StudyGroupManager.shared.myGroups = []
        StudyGroupManager.shared.currentGroup = nil
        StudyGroupManager.shared.groupMembers = []
        
        print("✅ AuthenticationStateManager: サービスクリーンアップ完了")
    }
    
    // MARK: - Session Management
    
    func checkCurrentSession() async {
        do {
            let session = try await supabaseClient.auth.session
            let user = session.user
            print("✅ AuthenticationStateManager: 既存セッション発見")
            print("   - ユーザーID: \(user.id)")
            print("   - 認証方法: \(user.appMetadata["provider"] ?? "不明")")
        } catch {
            print("ℹ️ AuthenticationStateManager: 既存セッションなし - \(error)")
            authenticationState = .signedOut
        }
    }
    
    // MARK: - Utility Methods
    
    var isAnonymousUser: Bool {
        return currentUser?.isAnonymous == true
    }
    
    var authProviderName: String {
        guard let provider = currentUser?.appMetadata["provider"] as? String else {
            return "不明"
        }
        
        switch provider {
        case "apple":
            return "Apple"
        case "anonymous":
            return "匿名"
        default:
            return provider.capitalized
        }
    }
    
    func refreshProfile() async {
        await loadUserProfile()
    }
}