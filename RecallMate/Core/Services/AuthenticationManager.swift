import Foundation
import Supabase
import AuthenticationServices
import SwiftUI

@MainActor
class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    // Delegated properties from state manager
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var userProfile: UserProfile?
    @Published var authenticationState: AuthenticationStateManager.AuthenticationState = .initial
    
    // Delegated properties from service
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let stateManager: AuthenticationStateManager
    private let authService: AuthenticationService
    
    private init() {
        self.stateManager = AuthenticationStateManager()
        self.authService = AuthenticationService(stateManager: stateManager)
        
        // Bind published properties
        setupPropertyBinding()
    }
    
    private func setupPropertyBinding() {
        // State manager bindings
        stateManager.$isAuthenticated.assign(to: &$isAuthenticated)
        stateManager.$currentUser.assign(to: &$currentUser)
        stateManager.$userProfile.assign(to: &$userProfile)
        stateManager.$authenticationState.assign(to: &$authenticationState)
        
        // Service bindings
        authService.$isLoading.assign(to: &$isLoading)
        authService.$errorMessage.assign(to: &$errorMessage)
    }
    
    // MARK: - Public Interface
    
    // Delegate to AuthenticationService
    func signInWithApple() async {
        await authService.signInWithApple()
    }
    
    func signInWithGoogle() async {
        await authService.signInWithGoogle()
    }
    
    func signInAnonymously() async {
        await authService.signInAnonymously()
    }
    
    func signOut() async {
        await authService.signOut()
    }
    
    func migrateFromAnonymous() async -> Bool {
        return await authService.migrateFromAnonymous()
    }
    
    // Delegate to AuthenticationStateManager
    func checkCurrentSession() async {
        await stateManager.checkCurrentSession()
    }
    
    func refreshProfile() async {
        await stateManager.refreshProfile()
    }
    
    // MARK: - Computed Properties
    
    var isAnonymousUser: Bool {
        return stateManager.isAnonymousUser
    }
    
    var authProviderName: String {
        return stateManager.authProviderName
    }
    
}