import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                headerSection
                
                Spacer()
                
                authButtonsSection
                
                termsSection
                
                Spacer()
            }
            .navigationBarHidden(true)
            .overlay(loadingOverlay)
            .alert("エラー", isPresented: .constant(authManager.errorMessage != nil)) {
                Button("OK") {
                    authManager.errorMessage = nil
                }
            } message: {
                Text(authManager.errorMessage ?? "")
            }
            .onChange(of: authManager.isAuthenticated) {
                if authManager.isAuthenticated {
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("RecallMate")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("学習記録とフレンドと一緒に成長しよう")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }
    
    private var authButtonsSection: some View {
        VStack(spacing: 16) {
            googleSignInButton
            anonymousSignInButton
        }
        .padding(.horizontal, 32)
    }
    
    
    private var googleSignInButton: some View {
        Button(action: {
            Task {
                await authManager.signInWithGoogle()
            }
        }) {
            HStack {
                Image("google-logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                Text("Google でサインイン")
                    .font(.headline)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(8)
        }
        .disabled(authManager.isLoading)
    }
    
    private var anonymousSignInButton: some View {
        Button(action: {
            Task {
                await authManager.signInAnonymously()
            }
        }) {
            HStack {
                Image(systemName: "person.circle")
                    .font(.system(size: 20))
                Text("ゲストでログイン")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.gray)
            .cornerRadius(8)
        }
        .disabled(authManager.isLoading)
    }
    
    private var termsSection: some View {
        VStack(spacing: 8) {
            Text("続行することで、以下に同意したものとみなされます")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Button("利用規約") {
                    // 利用規約を開く
                }
                .font(.caption)
                .foregroundColor(.blue)
                
                Text("・")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("プライバシーポリシー") {
                    // プライバシーポリシーを開く
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(.bottom, 32)
    }
    
    private var loadingOverlay: some View {
        Group {
            if authManager.isLoading {
                LoadingOverlay(message: "認証中...")
            }
        }
    }
}


// MARK: - Account Migration View

struct AccountMigrationView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // ヘッダー
                VStack(spacing: 16) {
                    Image(systemName: "arrow.up.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("アカウントをアップグレード")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("現在はゲストユーザーです。\nGoogle アカウントでログインして、\nデータを安全に保存しましょう。")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)
                
                // メリット表示
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(
                        icon: "icloud",
                        title: "データの安全な保存",
                        description: "学習記録を失う心配がありません"
                    )
                    
                    FeatureRow(
                        icon: "person.2",
                        title: "フレンド機能",
                        description: "友達と一緒に学習できます"
                    )
                    
                    FeatureRow(
                        icon: "arrow.2.squarepath",
                        title: "デバイス間同期",
                        description: "どのデバイスでも同じデータにアクセス"
                    )
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // アップグレードボタン
                VStack(spacing: 16) {
                    Button(action: {
                        Task {
                            let success = await authManager.migrateFromAnonymous()
                            if success {
                                dismiss()
                            }
                        }
                    }) {
                        HStack {
                            Image("google-logo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                            Text("Google でアップグレード")
                                .font(.headline)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(8)
                    }
                    .disabled(authManager.isLoading)
                    
                    Button("後で行う") {
                        dismiss()
                    }
                    .font(.body)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("スキップ") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}

struct AccountMigrationView_Previews: PreviewProvider {
    static var previews: some View {
        AccountMigrationView()
    }
}