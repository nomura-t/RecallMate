import SwiftUI

struct AuthenticationView: View {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showSuccess = false
    @State private var successMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Auth Form
                    authFormSection
                    
                    // Switch between sign in/up
                    switchModeSection
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle(isSignUp ? "アカウント作成" : "サインイン")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .alert("エラー", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .alert("成功", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(successMessage)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: isSignUp ? "person.badge.plus.fill" : "person.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text(isSignUp ? "アカウント作成" : "サインイン")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(isSignUp ? "メールアドレスでアカウントを作成" : "既存のアカウントでサインイン")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var authFormSection: some View {
        VStack(spacing: 16) {
            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Text("メールアドレス")
                    .font(.headline)
                
                TextField("example@email.com", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("パスワード")
                    .font(.headline)
                
                SecureField("6文字以上", text: $password)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Confirm Password (Sign Up only)
            if isSignUp {
                VStack(alignment: .leading, spacing: 8) {
                    Text("パスワード確認")
                        .font(.headline)
                    
                    SecureField("パスワードを再入力", text: $confirmPassword)
                        .textFieldStyle(.roundedBorder)
                }
            }
            
            // Submit Button
            Button(action: {
                if isSignUp {
                    signUp()
                } else {
                    signIn()
                }
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: isSignUp ? "person.badge.plus" : "arrow.right.circle")
                    }
                    Text(isSignUp ? "アカウント作成" : "サインイン")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!isFormValid || isLoading)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var switchModeSection: some View {
        VStack(spacing: 12) {
            Text(isSignUp ? "既にアカウントをお持ちですか？" : "アカウントをお持ちでないですか？")
                .font(.body)
                .foregroundColor(.secondary)
            
            Button(isSignUp ? "サインインする" : "アカウントを作成する") {
                withAnimation {
                    isSignUp.toggle()
                    clearForm()
                }
            }
            .foregroundColor(.blue)
        }
    }
    
    private var isFormValid: Bool {
        let emailValid = email.contains("@") && email.contains(".")
        let passwordValid = password.count >= 6
        
        if isSignUp {
            return emailValid && passwordValid && password == confirmPassword
        } else {
            return emailValid && passwordValid
        }
    }
    
    private func signUp() {
        guard password == confirmPassword else {
            showErrorMessage("パスワードが一致しません")
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let response = try await supabaseManager.client.auth.signUp(
                    email: email,
                    password: password
                )
                
                await MainActor.run {
                    isLoading = false
                    
                    let user = response.user
                    supabaseManager.currentUser = user
                    supabaseManager.isConnected = true
                    supabaseManager.connectionStatus = "メール認証でサインイン完了"
                    
                    print("✅ AuthenticationView: アカウント作成成功")
                    print("👤 新規ユーザーID: \(user.id)")
                    print("📧 メールアドレス: \(user.email ?? "不明")")
                    
                    successMessage = "アカウントが作成されました！"
                    showSuccess = true
                }
                
                // プロフィール作成確認（少し待ってからチェック）
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2秒待機
                print("🔍 AuthenticationView: プロフィール作成確認中...")
                await FriendshipManager.shared.loadCurrentUserProfile()
            } catch {
                await MainActor.run {
                    isLoading = false
                    showErrorMessage("アカウント作成に失敗しました: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func signIn() {
        isLoading = true
        
        Task {
            do {
                let response = try await supabaseManager.client.auth.signIn(
                    email: email,
                    password: password
                )
                
                await MainActor.run {
                    isLoading = false
                    
                    let user = response.user
                    supabaseManager.currentUser = user
                    supabaseManager.isConnected = true
                    supabaseManager.connectionStatus = "メール認証でサインイン完了"
                    
                    successMessage = "サインインが完了しました！"
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    showErrorMessage("サインインに失敗しました: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        errorMessage = ""
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}

#Preview {
    AuthenticationView()
}