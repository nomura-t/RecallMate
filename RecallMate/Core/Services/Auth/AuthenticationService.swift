import Foundation
import Supabase
import AuthenticationServices

// MARK: - Authentication Service

@MainActor
class AuthenticationService: ObservableObject, ErrorHandling {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabaseClient = SupabaseManager.shared.client
    private let stateManager: AuthenticationStateManager
    
    init(stateManager: AuthenticationStateManager) {
        self.stateManager = stateManager
    }
    
    // MARK: - Apple Sign In
    
    func signInWithApple() async {
        isLoading = true
        stateManager.authenticationState = .signingIn
        clearError()
        
        do {
            print("🍎 AuthenticationService: Apple Sign In開始")
            
            let result = try await supabaseClient.auth.signInWithOAuth(provider: .apple)
            
            print("✅ AuthenticationService: Apple Sign In成功")
            print("   - ユーザーID: \(result.user.id)")
            print("   - メール: \(result.user.email ?? "不明")")
            
        } catch {
            print("❌ AuthenticationService: Apple Sign Inエラー - \(error)")
            handleAuthError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Google Sign In
    
    func signInWithGoogle() async {
        isLoading = true
        stateManager.authenticationState = .signingIn
        clearError()
        
        do {
            print("🔵 AuthenticationService: Google Sign In開始")
            
            let result = try await supabaseClient.auth.signInWithOAuth(provider: .google)
            
            print("✅ AuthenticationService: Google Sign In成功")
            print("   - ユーザーID: \(result.user.id)")
            print("   - メール: \(result.user.email ?? "不明")")
            
        } catch {
            print("❌ AuthenticationService: Google Sign Inエラー - \(error)")
            handleAuthError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Anonymous Sign In
    
    func signInAnonymously() async {
        if SupabaseConfig.supabaseURL != "https://your-project-id.supabase.co" {
            await signInAnonymouslyWithSupabase()
        } else {
            await signInOffline()
        }
    }
    
    private func signInOffline() async {
        isLoading = true
        stateManager.authenticationState = .signingIn
        clearError()
        
        print("👤 AuthenticationService: オフライン認証開始")
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        stateManager.currentUser = nil
        stateManager.isAuthenticated = true
        stateManager.authenticationState = .signedIn
        
        print("✅ AuthenticationService: オフライン認証成功")
        
        await createMockProfile()
        isLoading = false
    }
    
    private func signInAnonymouslyWithSupabase() async {
        isLoading = true
        stateManager.authenticationState = .signingIn
        clearError()
        
        do {
            print("👤 AuthenticationService: 匿名サインイン開始")
            
            let result = try await supabaseClient.auth.signInAnonymously()
            
            print("✅ AuthenticationService: 匿名サインイン成功")
            print("   - ユーザーID: \(result.user.id)")
            
        } catch {
            print("❌ AuthenticationService: 匿名サインインエラー - \(error)")
            handleSupabaseError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Sign Out
    
    func signOut() async {
        isLoading = true
        clearError()
        
        do {
            print("📤 AuthenticationService: サインアウト開始")
            
            try await supabaseClient.auth.signOut()
            
            print("✅ AuthenticationService: サインアウト成功")
            
        } catch {
            print("❌ AuthenticationService: サインアウトエラー - \(error)")
            handleError(error, context: "サインアウト")
        }
        
        isLoading = false
    }
    
    // MARK: - Account Migration
    
    func migrateFromAnonymous() async -> Bool {
        guard let currentUser = stateManager.currentUser,
              currentUser.isAnonymous else {
            handleError(AppError.custom("匿名ユーザーではありません"))
            return false
        }
        
        isLoading = true
        clearError()
        
        do {
            print("🔄 AuthenticationService: 匿名ユーザーからの移行開始")
            
            try await supabaseClient.auth.signInWithOAuth(provider: .apple)
            
            print("✅ AuthenticationService: アカウント移行成功")
            return true
            
        } catch {
            print("❌ AuthenticationService: アカウント移行エラー - \(error)")
            handleError(error, context: "アカウント移行")
            return false
        }
    }
    
    // MARK: - Error Handling
    
    private func handleAuthError(_ error: Error) {
        if let authError = error as? AuthError {
            switch authError {
            case .sessionMissing:
                errorMessage = "認証セッションが見つかりません"
            case .weakPassword:
                errorMessage = "パスワードが弱すぎます"
            default:
                errorMessage = "Apple Sign Inに失敗しました: \(authError.localizedDescription)"
            }
        } else {
            errorMessage = "Apple Sign Inに失敗しました: \(error.localizedDescription)"
        }
        
        stateManager.authenticationState = .error(errorMessage ?? "不明なエラー")
    }
    
    private func handleSupabaseError(_ error: Error) {
        if error.localizedDescription.contains("サーバーが見つかりません") ||
           error.localizedDescription.contains("Could not resolve host") {
            errorMessage = "Supabaseプロジェクトが設定されていません。設定を確認してください。"
            stateManager.authenticationState = .error("Supabase設定エラー")
        } else {
            errorMessage = "匿名サインインに失敗しました: \(error.localizedDescription)"
            stateManager.authenticationState = .error(errorMessage ?? "不明なエラー")
        }
    }
    
    // MARK: - Mock Data
    
    private func createMockProfile() async {
        let mockProfile = UserProfile(
            id: UUID().uuidString,
            username: "offline_user",
            fullName: "オフラインユーザー",
            nickname: "オフラインユーザー",
            studyCode: "DEMO123",
            avatarUrl: nil,
            isStudying: false,
            studyStartTime: nil,
            totalStudyMinutes: 0,
            levelPoints: 0,
            currentLevel: 1,
            statusMessage: "オフラインモードでテスト中",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        stateManager.userProfile = mockProfile
        print("✅ AuthenticationService: オフラインプロフィール作成完了")
    }
}