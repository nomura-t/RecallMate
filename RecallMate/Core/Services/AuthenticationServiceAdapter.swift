import Foundation
import Combine
import Supabase

// MARK: - Authentication Service Adapter
/// 既存のAuthenticationManagerをAuthenticationServiceProtocolに適合させるアダプター
@MainActor
public class AuthenticationServiceAdapter: ObservableObject, AuthenticationServiceProtocol {
    
    @Published public var currentUser: UnifiedUserProfile?
    @Published public var isAuthenticated: Bool = false
    @Published public var authState: AuthenticationState = .unknown
    
    private let authManager = AuthenticationManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // AuthenticationManagerの状態をバインド
        authManager.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                self?.isAuthenticated = isAuthenticated
                self?.updateAuthState()
            }
            .store(in: &cancellables)
        
        authManager.$userProfile
            .combineLatest(authManager.$currentUser)
            .sink { [weak self] userProfile, currentUser in
                self?.updateCurrentUser(from: userProfile, user: currentUser)
                self?.updateAuthState()
            }
            .store(in: &cancellables)
        
        authManager.$isLoading
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.authState = .loading
                } else {
                    self?.updateAuthState()
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateCurrentUser(from userProfile: UserProfile?, user: User?) {
        guard let userProfile = userProfile else {
            self.currentUser = nil
            return
        }
        
        // UserProfileをUnifiedUserProfileに変換
        self.currentUser = UnifiedUserProfile(
            id: userProfile.id,
            email: user?.email, // UserオブジェクトからEmailを取得
            fullName: userProfile.fullName,
            nickname: userProfile.nickname,
            avatarURL: userProfile.avatarUrl,
            avatarIconId: nil, // UserProfileにはavatarIconIdがない
            bio: nil, // UserProfileにはbioフィールドがない
            statusMessage: userProfile.statusMessage,
            isOnline: userProfile.isStudying, // isStudyingをisOnlineとして使用
            lastActiveAt: userProfile.studyStartTime,
            createdAt: userProfile.createdAt ?? Date(),
            updatedAt: userProfile.updatedAt ?? Date()
        )
    }
    
    private func updateAuthState() {
        if authManager.isLoading {
            authState = .loading
        } else if let user = currentUser, isAuthenticated {
            authState = .authenticated(user)
        } else if !isAuthenticated {
            authState = .unauthenticated
        } else {
            authState = .unknown
        }
    }
    
    // MARK: - AuthenticationServiceProtocol Implementation
    
    public func signIn(email: String, password: String) async -> Result<UnifiedUserProfile, UnifiedError> {
        // 既存のAuthenticationManagerはAppleサインインのみサポート
        // Email/Password認証は未実装のため、エラーを返す
        return .failure(.authentication(.invalidCredentials))
    }
    
    public func signUp(email: String, password: String, name: String) async -> Result<UnifiedUserProfile, UnifiedError> {
        // 既存のAuthenticationManagerはAppleサインインのみサポート
        // Email/Password認証は未実装のため、エラーを返す
        return .failure(.authentication(.invalidCredentials))
    }
    
    public func signOut() async -> Result<Void, UnifiedError> {
        await authManager.signOut()
        return .success(())
    }
    
    public func refreshToken() async -> Result<Void, UnifiedError> {
        await authManager.checkCurrentSession()
        if isAuthenticated {
            return .success(())
        } else {
            return .failure(.authentication(.sessionExpired))
        }
    }
    
    public func updateProfile(_ profile: UnifiedUserProfile) async -> Result<UnifiedUserProfile, UnifiedError> {
        // ProfileManagerを通じてプロフィール更新を実装する必要がある
        // 現在は未実装のため、エラーを返す
        return .failure(.system(.permissionDenied))
    }
}

// MARK: - Apple Sign In Support
extension AuthenticationServiceAdapter {
    /// Apple Sign Inを実行
    public func signInWithApple() async -> Result<UnifiedUserProfile, UnifiedError> {
        await authManager.signInWithApple()
        
        // 認証結果を待つ
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒待機
        
        if let user = currentUser, isAuthenticated {
            return .success(user)
        } else if let errorMessage = authManager.errorMessage {
            return .failure(.authentication(.invalidCredentials))
        } else {
            return .failure(.unknown("認証に失敗しました"))
        }
    }
    
    /// 匿名サインインを実行
    public func signInAnonymously() async -> Result<UnifiedUserProfile, UnifiedError> {
        await authManager.signInAnonymously()
        
        // 認証結果を待つ
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒待機
        
        if let user = currentUser, isAuthenticated {
            return .success(user)
        } else if let errorMessage = authManager.errorMessage {
            return .failure(.authentication(.invalidCredentials))
        } else {
            return .failure(.unknown("匿名認証に失敗しました"))
        }
    }
}