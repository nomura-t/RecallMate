import Foundation
import Supabase
import AuthenticationServices
import SwiftUI

// MARK: - User Profile Model
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

// MARK: - Authentication Manager
/// 認証の状態管理・操作を一元化したマネージャー

@MainActor
class AuthenticationManager: ObservableObject, ErrorHandling {
    static let shared = AuthenticationManager()

    // MARK: - Published Properties

    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var userProfile: UserProfile?
    @Published var authenticationState: AuthenticationState = .initial
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Auth State Enum

    enum AuthenticationState {
        case initial
        case signedOut
        case signingIn
        case signedIn
        case error(String)
    }

    // MARK: - Private Properties

    private let supabaseClient = SupabaseManager.shared.client

    // MARK: - Init

    private init() {
        Task {
            await setupAuthStateListener()
        }
    }

    // MARK: - Auth State Listener

    private func setupAuthStateListener() async {
        for await (event, session) in supabaseClient.auth.authStateChanges {
            await handleAuthStateChange(event, session: session)
        }
    }

    private func handleAuthStateChange(_ event: AuthChangeEvent, session: Session?) async {
        switch event {
        case .signedIn:
            if let session = session {
                print("✅ AuthenticationManager: ユーザーがサインインしました")
                currentUser = session.user
                isAuthenticated = true
                authenticationState = .signedIn

                await loadUserProfile()
                await initializeServices()
            }

        case .signedOut:
            print("📤 AuthenticationManager: ユーザーがサインアウトしました")
            currentUser = nil
            userProfile = nil
            isAuthenticated = false
            authenticationState = .signedOut
            cleanupServices()

        case .tokenRefreshed:
            if let session = session {
                print("🔄 AuthenticationManager: トークンが更新されました")
                currentUser = session.user
            }

        case .userUpdated:
            if let session = session {
                print("👤 AuthenticationManager: ユーザー情報が更新されました")
                currentUser = session.user
                await loadUserProfile()
            }

        case .userDeleted:
            print("🗑️ AuthenticationManager: ユーザーが削除されました")
            currentUser = nil
            userProfile = nil
            isAuthenticated = false
            authenticationState = .signedOut

        case .initialSession:
            print("📱 AuthenticationManager: 初期セッションが検出されました")
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
            print("❓ AuthenticationManager: 不明な認証状態変更")
        }
    }

    // MARK: - Google Sign In

    func signInWithGoogle() async {
        isLoading = true
        authenticationState = .signingIn
        clearError()

        do {
            print("🔵 AuthenticationManager: Google Sign In開始")

            let bundleID = Bundle.main.bundleIdentifier ?? "tenten.RecallMate"
            guard let redirectURL = URL(string: "\(bundleID)://auth-callback") else {
                print("❌ AuthenticationManager: リダイレクトURLの生成に失敗")
                errorMessage = "リダイレクトURLの生成に失敗しました"
                authenticationState = .error("URLエラー")
                isLoading = false
                return
            }

            _ = try await supabaseClient.auth.signInWithOAuth(
                provider: .google,
                redirectTo: redirectURL
            )

            print("⏳ OAuth認証フローが開始されました")

        } catch {
            print("❌ AuthenticationManager: Google Sign Inエラー - \(error)")
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
        authenticationState = .signingIn
        clearError()

        print("👤 AuthenticationManager: オフライン認証開始")

        try? await Task.sleep(nanoseconds: 500_000_000)

        currentUser = nil
        isAuthenticated = true
        authenticationState = .signedIn

        print("✅ AuthenticationManager: オフライン認証成功")

        await createMockProfile()
        isLoading = false
    }

    private func signInAnonymouslyWithSupabase() async {
        isLoading = true
        authenticationState = .signingIn
        clearError()

        do {
            print("👤 AuthenticationManager: 匿名サインイン開始")

            let result = try await supabaseClient.auth.signInAnonymously()

            print("✅ AuthenticationManager: 匿名サインイン成功")
            print("   - ユーザーID: \(result.user.id)")

        } catch {
            print("❌ AuthenticationManager: 匿名サインインエラー - \(error)")
            handleSupabaseError(error)
        }

        isLoading = false
    }

    // MARK: - Sign Out

    func signOut() async {
        isLoading = true
        clearError()

        do {
            print("📤 AuthenticationManager: サインアウト開始")
            try await supabaseClient.auth.signOut()
            print("✅ AuthenticationManager: サインアウト成功")
        } catch {
            print("❌ AuthenticationManager: サインアウトエラー - \(error)")
            handleError(error, context: "サインアウト")
        }

        isLoading = false
    }

    // MARK: - Account Migration

    func migrateFromAnonymous() async -> Bool {
        guard let user = currentUser, user.isAnonymous else {
            handleError(AppError.custom("匿名ユーザーではありません"))
            return false
        }

        isLoading = true
        clearError()

        do {
            print("🔄 AuthenticationManager: 匿名ユーザーからの移行開始")

            let bundleID = Bundle.main.bundleIdentifier ?? "tenten.RecallMate"
            guard let redirectURL = URL(string: "\(bundleID)://auth-callback") else {
                print("❌ AuthenticationManager: リダイレクトURLの生成に失敗")
                errorMessage = "リダイレクトURLの生成に失敗しました"
                isLoading = false
                return false
            }

            try await supabaseClient.auth.signInWithOAuth(
                provider: .google,
                redirectTo: redirectURL
            )

            print("✅ AuthenticationManager: アカウント移行成功")
            return true

        } catch {
            print("❌ AuthenticationManager: アカウント移行エラー - \(error)")
            handleError(error, context: "アカウント移行")
            return false
        }
    }

    // MARK: - Session Management

    func checkCurrentSession() async {
        do {
            let session = try await supabaseClient.auth.session
            let user = session.user
            print("✅ AuthenticationManager: 既存セッション発見")
            print("   - ユーザーID: \(user.id)")
            print("   - 認証方法: \(user.appMetadata["provider"] ?? "不明")")
        } catch {
            print("ℹ️ AuthenticationManager: 既存セッションなし - \(error)")
            authenticationState = .signedOut
        }
    }

    func refreshProfile() async {
        await loadUserProfile()
    }

    // MARK: - Computed Properties

    var isAnonymousUser: Bool {
        return currentUser?.isAnonymous == true
    }

    var authProviderName: String {
        guard let provider = currentUser?.appMetadata["provider"] as? String else {
            return "不明"
        }

        switch provider {
        case "google":
            return "Google"
        case "anonymous":
            return "匿名"
        default:
            return provider.capitalized
        }
    }

    // MARK: - Profile Management

    private func loadUserProfile() async {
        guard let userId = currentUser?.id else {
            print("⚠️ AuthenticationManager: ユーザーIDが見つかりません")
            return
        }

        do {
            let profile: UserProfile = try await supabaseClient
                .from("profiles")
                .select("*")
                .eq("id", value: userId)
                .single()
                .execute()
                .value

            userProfile = profile
            print("✅ AuthenticationManager: プロフィール読み込み成功")
        } catch {
            print("⚠️ AuthenticationManager: プロフィール読み込みエラー - \(error)")
            if error.localizedDescription.contains("No rows") || error.localizedDescription.contains("single") {
                await createMissingProfile(userId: userId)
            }
        }
    }

    private func createMissingProfile(userId: UUID) async {
        do {
            let studyCode: String = try await supabaseClient
                .rpc("generate_study_code")
                .execute()
                .value

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

            await loadUserProfile()
        } catch {
            print("❌ プロフィール作成エラー: \(error)")
        }
    }

    func updateProfile(
        fullName: String,
        nickname: String?,
        bio: String?,
        avatarIconId: String
    ) async -> Bool {
        guard let userId = currentUser?.id else { return false }

        if SupabaseConfig.supabaseURL == "https://your-project-id.supabase.co" {
            return updateProfileOffline(
                fullName: fullName,
                nickname: nickname,
                bio: bio,
                avatarIconId: avatarIconId
            )
        }

        do {
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

            await loadUserProfile()
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
    ) -> Bool {
        if let profile = userProfile {
            userProfile = UserProfile(
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
            return true
        }
        return false
    }

    // MARK: - Service Management

    private func initializeServices() async {
        print("🔄 AuthenticationManager: サービス初期化開始")
        await loadUserProfile()
        print("✅ AuthenticationManager: サービス初期化完了")
    }

    private func cleanupServices() {
        print("🧹 AuthenticationManager: サービスクリーンアップ開始")
        userProfile = nil
        print("✅ AuthenticationManager: サービスクリーンアップ完了")
    }

    // MARK: - Error Handling (Auth-specific)

    private func handleAuthError(_ error: Error) {
        if let authError = error as? AuthError {
            switch authError {
            case .sessionMissing:
                errorMessage = "認証セッションが見つかりません"
            case .weakPassword:
                errorMessage = "パスワードが弱すぎます"
            default:
                errorMessage = "Google Sign Inに失敗しました: \(authError.localizedDescription)"
            }
        } else {
            errorMessage = "Google Sign Inに失敗しました: \(error.localizedDescription)"
        }

        authenticationState = .error(errorMessage ?? "不明なエラー")
    }

    private func handleSupabaseError(_ error: Error) {
        if error.localizedDescription.contains("サーバーが見つかりません") ||
           error.localizedDescription.contains("Could not resolve host") {
            errorMessage = "Supabaseプロジェクトが設定されていません。設定を確認してください。"
            authenticationState = .error("Supabase設定エラー")
        } else {
            errorMessage = "匿名サインインに失敗しました: \(error.localizedDescription)"
            authenticationState = .error(errorMessage ?? "不明なエラー")
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

        userProfile = mockProfile
        print("✅ AuthenticationManager: オフラインプロフィール作成完了")
    }
}
