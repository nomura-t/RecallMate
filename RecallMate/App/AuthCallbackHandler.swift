import SwiftUI
import Supabase

struct AuthCallbackHandler: ViewModifier {
    @StateObject private var authManager = AuthenticationManager.shared
    
    func body(content: Content) -> some View {
        content
            .onOpenURL { url in
                handleAuthCallback(url)
            }
    }
    
    private func handleAuthCallback(_ url: URL) {
        print("🔗 Auth callback received: \(url.absoluteString)")
        
        // Bundle IDのURLスキームをチェック
        let bundleID = Bundle.main.bundleIdentifier ?? "tenten.RecallMate"
        guard url.scheme == bundleID else {
            print("⚠️ 無効なURLスキーム: \(url.scheme ?? "nil") (期待値: \(bundleID))")
            return
        }
        
        // Supabaseの認証コールバックを処理
        Task {
            do {
                try await SupabaseManager.shared.client.auth.session(from: url)
                print("✅ Auth callback処理成功")
                
                // 認証状態を更新
                await authManager.checkCurrentSession()
            } catch {
                print("❌ Auth callback処理エラー: \(error)")
            }
        }
    }
}

extension View {
    func handleAuthCallback() -> some View {
        self.modifier(AuthCallbackHandler())
    }
}