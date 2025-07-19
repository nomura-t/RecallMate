import SwiftUI
import PhotosUI

struct MyProfileView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var profileViewModel = ProfileViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditMode = false
    @State private var showingImagePicker = false
    @State private var selectedImage: PhotosPickerItem?
    @State private var showingLogoutAlert = false
    @State private var showingDeleteAccountAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // プロフィール画像セクション
                    profileImageSection
                    
                    // ユーザー情報セクション
                    userInfoSection
                    
                    // 統計情報セクション
                    statisticsSection
                    
                    // アカウントタイプセクション
                    accountTypeSection
                    
                    // 設定セクション
                    settingsSection
                    
                    // ログアウト/アカウント削除
                    accountActionsSection
                }
                .padding()
            }
            .navigationTitle("プロフィール")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(showingEditMode ? "完了" : "編集") {
                        showingEditMode.toggle()
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditMode) {
            EditProfileView()
        }
        .photosPicker(isPresented: $showingImagePicker, selection: $selectedImage)
        .onChange(of: selectedImage) { _, newItem in
            Task {
                await profileViewModel.updateProfileImage(newItem)
            }
        }
        .alert("ログアウト", isPresented: $showingLogoutAlert) {
            Button("ログアウト", role: .destructive) {
                Task {
                    await authManager.signOut()
                    dismiss()
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("本当にログアウトしますか？")
        }
        .alert("アカウント削除", isPresented: $showingDeleteAccountAlert) {
            Button("削除", role: .destructive) {
                Task {
                    await profileViewModel.deleteAccount()
                    dismiss()
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("アカウントを削除すると、すべてのデータが失われます。本当に削除しますか？")
        }
    }
    
    // MARK: - View Components
    
    private var profileImageSection: some View {
        VStack(spacing: 16) {
            // プロフィール画像
            ZStack(alignment: .bottomTrailing) {
                if let imageUrl = authManager.userProfile?.avatarUrl {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 120))
                        .foregroundColor(.gray)
                }
                
                if showingEditMode {
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                }
            }
            
            // ユーザー名
            Text(authManager.userProfile?.displayName ?? "ゲストユーザー")
                .font(.title2)
                .fontWeight(.bold)
            
            // ユーザーID
            if let username = authManager.userProfile?.username {
                Text("@\(username)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var userInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ユーザー情報")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                MyProfileInfoRow(
                    icon: "envelope",
                    title: "メール",
                    value: authManager.currentUser?.email ?? "未設定"
                )
                
                Divider()
                    .padding(.leading, 44)
                
                MyProfileInfoRow(
                    icon: "calendar",
                    title: "登録日",
                    value: formatDate(authManager.userProfile?.createdAt ?? Date())
                )
                
                if let bio = authManager.userProfile?.statusMessage, !bio.isEmpty {
                    Divider()
                        .padding(.leading, 44)
                    
                    MyProfileInfoRow(
                        icon: "text.alignleft",
                        title: "自己紹介",
                        value: bio
                    )
                }
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("学習統計")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    title: "総学習時間",
                    value: "\(profileViewModel.totalStudyHours)時間",
                    icon: "clock.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "メモ数",
                    value: "\(profileViewModel.totalMemos)",
                    icon: "doc.text.fill",
                    color: .green
                )
                
                StatCard(
                    title: "連続学習日数",
                    value: "\(profileViewModel.currentStreak)日",
                    icon: "flame.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "レベル",
                    value: "Lv.\(profileViewModel.userLevel)",
                    icon: "star.fill",
                    color: .purple
                )
            }
        }
    }
    
    private var accountTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("アカウントタイプ")
                .font(.headline)
                .padding(.horizontal)
            
            HStack {
                Image(systemName: authManager.isAnonymousUser ? "person.circle" : "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(authManager.isAnonymousUser ? .orange : .green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(authManager.isAnonymousUser ? "ゲストアカウント" : "登録済みアカウント")
                        .font(.headline)
                    
                    Text(authManager.isAnonymousUser ? 
                         "一部機能が制限されています" : 
                         "すべての機能が利用可能です")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if authManager.isAnonymousUser {
                    Button("アップグレード") {
                        // アップグレード画面を表示
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("設定")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                SettingRow(
                    icon: "bell",
                    title: "通知設定",
                    action: {
                        // 通知設定画面へ
                    }
                )
                
                Divider()
                    .padding(.leading, 44)
                
                SettingRow(
                    icon: "lock",
                    title: "プライバシー設定",
                    action: {
                        // プライバシー設定画面へ
                    }
                )
                
                Divider()
                    .padding(.leading, 44)
                
                SettingRow(
                    icon: "questionmark.circle",
                    title: "ヘルプ",
                    action: {
                        // ヘルプ画面へ
                    }
                )
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var accountActionsSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                showingLogoutAlert = true
            }) {
                Text("ログアウト")
                    .font(.headline)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
            
            if !authManager.isAnonymousUser {
                Button(action: {
                    showingDeleteAccountAlert = true
                }) {
                    Text("アカウントを削除")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.top, 24)
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct MyProfileInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SettingRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                    .frame(width: 32)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

// MARK: - View Model

class ProfileViewModel: ObservableObject {
    @Published var totalStudyHours: Int = 0
    @Published var totalMemos: Int = 0
    @Published var currentStreak: Int = 0
    @Published var userLevel: Int = 1
    
    init() {
        loadStatistics()
    }
    
    private func loadStatistics() {
        // ここで実際の統計データを読み込む
        // 仮のデータ
        totalStudyHours = 125
        totalMemos = 342
        currentStreak = 7
        userLevel = 5
    }
    
    func updateProfileImage(_ item: PhotosPickerItem?) async {
        // プロフィール画像の更新処理
    }
    
    func deleteAccount() async {
        // アカウント削除処理
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var displayName = ""
    @State private var username = ""
    @State private var bio = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本情報") {
                    TextField("表示名", text: $displayName)
                    TextField("ユーザー名", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Section("自己紹介") {
                    TextEditor(text: $bio)
                        .frame(minHeight: 100)
                }
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
                }
            }
            .onAppear {
                displayName = authManager.userProfile?.displayName ?? ""
                username = authManager.userProfile?.username ?? ""
                bio = authManager.userProfile?.statusMessage ?? ""
            }
        }
    }
    
    private func saveProfile() {
        // プロフィール保存処理
        dismiss()
    }
}

// MARK: - Preview

struct MyProfileView_Previews: PreviewProvider {
    static var previews: some View {
        MyProfileView()
    }
}