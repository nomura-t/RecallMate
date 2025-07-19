import SwiftUI

struct ProfileEditView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var friendshipManager = FriendshipManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var displayName: String = ""
    @State private var nickname: String = ""
    @State private var bio: String = ""
    @State private var selectedIcon: AvatarIcon = AvatarIcons.defaultIcon
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: UIConstants.extraLargeSpacing) {
                    // プロフィール画像セクション
                    profileImageSection
                    
                    // 基本情報セクション
                    basicInfoSection
                    
                    // 自己紹介セクション
                    bioSection
                    
                    Spacer(minLength: UIConstants.extraLargeSpacing)
                }
                .padding()
            }
            .navigationTitle("プロフィール編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveProfile()
                    }
                    .disabled(isLoading || displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                loadCurrentProfile()
            }
            .alert("プロフィール編集", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .overlay {
                if isLoading {
                    LoadingOverlay(message: "保存中...")
                }
            }
        }
    }
    
    // MARK: - Profile Image Section
    private var profileImageSection: some View {
        VStack(spacing: UIConstants.mediumSpacing) {
            AvatarIconView(icon: selectedIcon, size: 100)
                .shadow(color: AppColors.overlay.opacity(0.2), radius: 4, x: 0, y: 2)
            
            AvatarIconSelector(selectedIcon: $selectedIcon)
        }
        .padding()
        .background(AppColors.backgroundSecondary)
        .cornerRadius(UIConstants.mediumCornerRadius)
    }
    
    // MARK: - Basic Info Section
    private var basicInfoSection: some View {
        VStack(spacing: UIConstants.mediumSpacing) {
            SectionHeader("基本情報")
            
            VStack(spacing: UIConstants.mediumSpacing) {
                // 表示名
                VStack(alignment: .leading, spacing: UIConstants.smallSpacing) {
                    Text("表示名 *")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)
                    
                    TextField("あなたの名前", text: $displayName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textInputAutocapitalization(.words)
                }
                
                // ニックネーム
                VStack(alignment: .leading, spacing: UIConstants.smallSpacing) {
                    Text("ニックネーム")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)
                    
                    TextField("呼び方（オプション）", text: $nickname)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textInputAutocapitalization(.words)
                }
            }
            .padding()
            .background(AppColors.backgroundSecondary)
            .cornerRadius(UIConstants.mediumCornerRadius)
        }
    }
    
    // MARK: - Bio Section
    private var bioSection: some View {
        VStack(spacing: UIConstants.mediumSpacing) {
            SectionHeader("自己紹介")
            
            VStack(alignment: .leading, spacing: UIConstants.smallSpacing) {
                Text("自己紹介文")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
                
                TextEditor(text: $bio)
                    .frame(minHeight: 100)
                    .padding(UIConstants.smallSpacing)
                    .background(AppColors.backgroundPrimary)
                    .cornerRadius(UIConstants.smallCornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: UIConstants.smallCornerRadius)
                            .stroke(AppColors.divider, lineWidth: 1)
                    )
                
                HStack {
                    Spacer()
                    Text("\\(bio.count)/200")
                        .font(.caption)
                        .foregroundColor(bio.count > 200 ? AppColors.error : AppColors.textSecondary)
                }
            }
            .padding()
            .background(AppColors.backgroundSecondary)
            .cornerRadius(UIConstants.mediumCornerRadius)
        }
    }
    
    // MARK: - Methods
    private func loadCurrentProfile() {
        guard let profile = friendshipManager.currentUserProfile else {
            // デフォルト値を設定
            displayName = authManager.currentUser?.email?.components(separatedBy: "@").first ?? ""
            return
        }
        
        displayName = profile.fullName ?? ""
        nickname = profile.nickname ?? ""
        bio = profile.statusMessage ?? ""
        
        // アイコンIDからアイコンを取得
        if let iconId = profile.avatarUrl {
            selectedIcon = AvatarIcons.icon(for: iconId)
        }
    }
    
    private func saveProfile() {
        guard !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "表示名を入力してください"
            showingAlert = true
            return
        }
        
        if bio.count > 200 {
            alertMessage = "自己紹介文は200文字以内で入力してください"
            showingAlert = true
            return
        }
        
        isLoading = true
        
        Task {
            // プロフィール情報を作成
            let trimmedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedBio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // アイコンIDを保存（画像URLの代わりに）
            let iconId = selectedIcon.id
            
            // プロフィール更新
            let success = await friendshipManager.updateProfile(
                fullName: trimmedDisplayName,
                nickname: trimmedNickname.isEmpty ? nil : trimmedNickname,
                bio: trimmedBio.isEmpty ? nil : trimmedBio,
                avatarIconId: iconId
            )
            
            await MainActor.run {
                isLoading = false
                
                if success {
                    alertMessage = "プロフィールが更新されました"
                    showingAlert = true
                    
                    // 1秒後に閉じる
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        dismiss()
                    }
                } else {
                    alertMessage = "プロフィールの更新に失敗しました"
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - Preview
struct ProfileEditView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileEditView()
    }
}