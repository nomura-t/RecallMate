import SwiftUI

struct ProfileView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var showingEditProfile = false
    @State private var studyStats: UserStudyStats?
    @State private var isLoadingStats = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: UIConstants.extraLargeSpacing) {
                    // プロフィールヘッダー
                    profileHeader
                    
                    // 学習統計セクション
                    studyStatsSection
                    
                    // 自己紹介セクション
                    if let bio = authManager.userProfile?.statusMessage,
                       !bio.isEmpty {
                        bioSection(bio: bio)
                    }
                    
                    // アカウント情報セクション
                    accountInfoSection
                    
                    Spacer(minLength: UIConstants.extraLargeSpacing)
                }
                .padding()
            }
            .navigationTitle("プロフィール")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("編集") {
                        showingEditProfile = true
                    }
                    .disabled(!authManager.isAuthenticated)
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                ProfileEditView()
            }
            .onAppear {
                loadStudyStats()
            }
            .refreshable {
                await refreshData()
            }
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: UIConstants.mediumSpacing) {
            // アバター
            Group {
                if let profile = authManager.userProfile,
                   let iconId = profile.avatarUrl {
                    AvatarIconView(icon: AvatarIcons.icon(for: iconId), size: 120)
                } else {
                    AvatarIconView(icon: AvatarIcons.defaultIcon, size: 120)
                }
            }
            .shadow(color: AppColors.overlay.opacity(0.3), radius: 8, x: 0, y: 4)
            
            // 名前とニックネーム
            VStack(spacing: UIConstants.smallSpacing) {
                Text(authManager.userProfile?.fullName ?? "未設定")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                
                if let nickname = authManager.userProfile?.nickname,
                   !nickname.isEmpty {
                    Text("@\\(nickname)")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            // 学習コードとレベル
            HStack(spacing: UIConstants.largeSpacing) {
                VStack {
                    Text("学習コード")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text(authManager.userProfile?.studyCode ?? "未設定")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                Divider()
                    .frame(height: 30)
                
                VStack {
                    Text("レベル")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("\\(authManager.userProfile?.currentLevel ?? 1)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
        .padding()
        .background(AppColors.backgroundSecondary)
        .cornerRadius(UIConstants.mediumCornerRadius)
    }
    
    // MARK: - Study Stats Section
    private var studyStatsSection: some View {
        VStack(spacing: UIConstants.mediumSpacing) {
            SectionHeader("学習統計")
            
            if isLoadingStats {
                ProgressView("読み込み中...")
                    .frame(height: 100)
            } else if let stats = studyStats {
                VStack(spacing: UIConstants.mediumSpacing) {
                    // 今週の学習時間
                    StudyStatCard(
                        title: "今週の学習時間",
                        value: formatTime(stats.thisWeekMinutes),
                        icon: "calendar.badge.clock",
                        color: AppColors.primary
                    )
                    
                    // 総学習時間
                    StudyStatCard(
                        title: "総学習時間",
                        value: formatTime(stats.totalMinutes),
                        icon: "clock.fill",
                        color: AppColors.success
                    )
                    
                    // 連続学習日数
                    StudyStatCard(
                        title: "連続学習日数",
                        value: "\\(stats.streakDays)日",
                        icon: "flame.fill",
                        color: AppColors.warning
                    )
                }
            } else {
                CommonEmptyStateView(
                    icon: "chart.bar",
                    title: "学習統計がありません",
                    description: "学習を開始すると統計が表示されます"
                )
                .frame(height: 150)
            }
        }
    }
    
    // MARK: - Bio Section
    private func bioSection(bio: String) -> some View {
        VStack(spacing: UIConstants.mediumSpacing) {
            SectionHeader("自己紹介")
            
            VStack(alignment: .leading, spacing: UIConstants.smallSpacing) {
                Text(bio)
                    .font(.body)
                    .foregroundColor(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(AppColors.backgroundSecondary)
            .cornerRadius(UIConstants.mediumCornerRadius)
        }
    }
    
    // MARK: - Account Info Section
    private var accountInfoSection: some View {
        VStack(spacing: UIConstants.mediumSpacing) {
            SectionHeader("アカウント情報")
            
            VStack(spacing: UIConstants.smallSpacing) {
                InfoRow(
                    title: "認証方法",
                    value: authManager.authProviderName,
                    icon: "person.badge.shield.checkmark"
                )
                
                InfoRow(
                    title: "登録日",
                    value: formatDate(authManager.userProfile?.createdAt ?? Date()),
                    icon: "calendar"
                )
                
                if authManager.isAnonymousUser {
                    Button(action: {
                        // アカウントアップグレード処理
                        Task {
                            await authManager.migrateFromAnonymous()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(AppColors.primary)
                            
                            Text("アカウントをアップグレード")
                                .font(.subheadline)
                                .foregroundColor(AppColors.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .padding()
                        .background(AppColors.backgroundSecondary)
                        .cornerRadius(UIConstants.smallCornerRadius)
                    }
                }
            }
            .padding()
            .background(AppColors.backgroundSecondary)
            .cornerRadius(UIConstants.mediumCornerRadius)
        }
    }
    
    // MARK: - Helper Methods
    private func loadStudyStats() {
        isLoadingStats = true
        
        Task {
            let stats = await StudyStatsCalculator.calculateStats()
            await MainActor.run {
                self.studyStats = stats
                self.isLoadingStats = false
            }
        }
    }
    
    private func refreshData() async {
        await authManager.refreshProfile()
        loadStudyStats()
    }
    
    private func formatTime(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)時間\(remainingMinutes)分"
        } else {
            return "\(remainingMinutes)分"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// MARK: - Study Stat Card
struct StudyStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: UIConstants.mediumSpacing) {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Spacer()
        }
        .padding()
        .background(AppColors.backgroundSecondary)
        .cornerRadius(UIConstants.mediumCornerRadius)
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(AppColors.textSecondary)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(.vertical, 4)
    }
}



// MARK: - Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}