import SwiftUI

// MARK: - Enhanced Home View
// 統一されたUI/UXを持つホームビュー

struct EnhancedHomeView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var friendshipManager = FriendshipManager.shared
    @State private var studyStats: UserStudyStats?
    @State private var sessionStats: DailySessionStats?
    @State private var isLoadingStats = false
    @State private var showingProfile = false
    @State private var showingStudyRecords = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // 認証ステータスバナー（匿名ユーザーのみ）
                    AuthStatusBanner()
                    
                    // メインコンテンツ
                    VStack(spacing: UIConstants.extraLargeSpacing) {
                        // 今日の学習状況
                        todayStudySection
                        
                        // 学習統計（認証済みユーザーのみ）
                        if authManager.isAuthenticated {
                            studyStatsSection
                        }
                        
                        // クイックアクション
                        quickActionsSection
                        
                        // 今日の復習予定
                        todayReviewSection
                    }
                    .padding()
                }
            }
            .navigationTitle(homeTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if authManager.isAuthenticated {
                        Button(action: {
                            showingProfile = true
                        }) {
                            if let profile = friendshipManager.currentUserProfile,
                               let iconId = profile.avatarUrl {
                                AvatarIconView(icon: AvatarIcons.icon(for: iconId), size: 32)
                            } else {
                                AvatarIconView(icon: AvatarIcons.defaultIcon, size: 32)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
            .sheet(isPresented: $showingStudyRecords) {
                StudyRecordsListView()
            }
            .onAppear {
                loadStats()
            }
            .refreshable {
                await refreshData()
            }
        }
    }
    
    // MARK: - Today Study Section
    private var todayStudySection: some View {
        VStack(spacing: UIConstants.mediumSpacing) {
            SectionHeader("今日の学習")
            
            if let sessionStats = sessionStats {
                VStack(spacing: UIConstants.mediumSpacing) {
                    // 今日の実績
                    HStack(spacing: UIConstants.mediumSpacing) {
                        StudyStatCard(
                            title: "復習完了",
                            value: "\\(sessionStats.todayReviewCount)件",
                            icon: "checkmark.circle.fill",
                            color: AppColors.success
                        )
                        
                        StudyStatCard(
                            title: "学習時間",
                            value: formatTime(sessionStats.todayStudyMinutes),
                            icon: "clock.fill",
                            color: AppColors.primary
                        )
                    }
                    
                    // 復習率
                    if sessionStats.todayReviewCount > 0 {
                        VStack(alignment: .leading, spacing: UIConstants.smallSpacing) {
                            HStack {
                                Text("今日の復習率")
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.textSecondary)
                                
                                Spacer()
                                
                                Text("\\(Int(sessionStats.reviewRate * 100))%")
                                    .font(.headline)
                                    .foregroundColor(AppColors.textPrimary)
                            }
                            
                            ProgressView(value: sessionStats.reviewRate)
                                .progressViewStyle(LinearProgressViewStyle())
                                .tint(AppColors.primary)
                        }
                        .padding()
                        .background(AppColors.backgroundSecondary)
                        .cornerRadius(UIConstants.mediumCornerRadius)
                    }
                }
            } else {
                ProgressView("読み込み中...")
                    .frame(height: 100)
            }
        }
    }
    
    // MARK: - Study Stats Section
    private var studyStatsSection: some View {
        VStack(spacing: UIConstants.mediumSpacing) {
            HStack {
                SectionHeader("学習統計")
                
                Spacer()
                
                Button("詳細") {
                    showingStudyRecords = true
                }
                .font(.subheadline)
                .foregroundColor(AppColors.primary)
            }
            
            if isLoadingStats {
                ProgressView("読み込み中...")
                    .frame(height: 120)
            } else if let stats = studyStats {
                VStack(spacing: UIConstants.mediumSpacing) {
                    HStack(spacing: UIConstants.mediumSpacing) {
                        StudyStatCard(
                            title: "今週",
                            value: formatTime(stats.thisWeekMinutes),
                            icon: "calendar.badge.clock",
                            color: AppColors.primary
                        )
                        
                        StudyStatCard(
                            title: "総時間",
                            value: formatTime(stats.totalMinutes),
                            icon: "clock.fill",
                            color: AppColors.success
                        )
                    }
                    
                    StudyStatCard(
                        title: "連続学習",
                        value: "\\(stats.streakDays)日",
                        icon: "flame.fill",
                        color: AppColors.warning
                    )
                }
            } else {
                CommonEmptyStateView(
                    icon: "chart.bar",
                    title: "学習統計がありません",
                    description: "復習を開始すると統計が表示されます"
                )
                .frame(height: 120)
            }
        }
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(spacing: UIConstants.mediumSpacing) {
            SectionHeader("クイックアクション")
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: UIConstants.mediumSpacing) {
                QuickActionCard(
                    title: "復習開始",
                    description: "今日の復習を開始",
                    icon: "play.circle.fill",
                    color: AppColors.primary,
                    destination: AnyView(ReviewListView())
                )
                
                QuickActionCard(
                    title: "メモ追加",
                    description: "新しいメモを作成",
                    icon: "plus.circle.fill",
                    color: AppColors.success,
                    destination: AnyView(ContentView())
                )
                
                QuickActionCard(
                    title: "学習記録",
                    description: "過去の学習を確認",
                    icon: "chart.line.uptrend.xyaxis",
                    color: AppColors.warning,
                    action: {
                        showingStudyRecords = true
                    }
                )
                
                if authManager.isAuthenticated {
                    QuickActionCard(
                        title: "プロフィール",
                        description: "設定とプロフィール",
                        icon: "person.circle.fill",
                        color: AppColors.secondary,
                        action: {
                            showingProfile = true
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Today Review Section
    private var todayReviewSection: some View {
        VStack(spacing: UIConstants.mediumSpacing) {
            SectionHeader("今日の復習予定")
            
            TodayReviewPreview()
        }
    }
    
    // MARK: - Computed Properties
    private var homeTitle: String {
        if let profile = friendshipManager.currentUserProfile {
            let name = profile.nickname ?? profile.fullName ?? "ユーザー"
            return "おかえりなさい、\\(name)さん"
        } else {
            return "RecallMate"
        }
    }
    
    // MARK: - Helper Methods
    private func loadStats() {
        isLoadingStats = true
        
        Task {
            let stats = await StudyStatsCalculator.calculateStats()
            let sessionStats = await StudyStatsCalculator.calculateSessionStats()
            
            await MainActor.run {
                self.studyStats = stats
                self.sessionStats = sessionStats
                self.isLoadingStats = false
            }
        }
    }
    
    private func refreshData() async {
        await friendshipManager.refreshAllData()
        loadStats()
    }
    
    private func formatTime(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\\(hours)h\\(remainingMinutes)m"
        } else {
            return "\\(remainingMinutes)m"
        }
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let destination: AnyView?
    let action: (() -> Void)?
    
    init(title: String, description: String, icon: String, color: Color, destination: AnyView) {
        self.title = title
        self.description = description
        self.icon = icon
        self.color = color
        self.destination = destination
        self.action = nil
    }
    
    init(title: String, description: String, icon: String, color: Color, action: @escaping () -> Void) {
        self.title = title
        self.description = description
        self.icon = icon
        self.color = color
        self.destination = nil
        self.action = action
    }
    
    var body: some View {
        Group {
            if let destination = destination {
                NavigationLink(destination: destination) {
                    cardContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Button(action: action ?? {}) {
                    cardContent
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var cardContent: some View {
        VStack(spacing: UIConstants.mediumSpacing) {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                )
            
            VStack(spacing: UIConstants.smallSpacing) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(AppColors.backgroundSecondary)
        .cornerRadius(UIConstants.mediumCornerRadius)
    }
}

// MARK: - Today Review Preview
struct TodayReviewPreview: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Memo.nextReviewDate, ascending: true)],
        predicate: NSPredicate(format: "nextReviewDate <= %@", Date() as NSDate),
        animation: .default
    )
    private var dueMemos: FetchedResults<Memo>
    
    var body: some View {
        VStack(spacing: UIConstants.mediumSpacing) {
            if dueMemos.isEmpty {
                emptyStateView
            } else {
                reviewListView
            }
        }
    }
    
    private var emptyStateView: some View {
        CommonEmptyStateView(
            icon: "checkmark.circle",
            title: "復習完了！",
            description: "今日の復習はすべて完了しました"
        )
        .frame(height: 120)
    }
    
    private var reviewListView: some View {
        VStack(spacing: UIConstants.smallSpacing) {
            headerView
            memoScrollView
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("復習待ち: \(dueMemos.count)件")
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            
            Spacer()
            
            NavigationLink("すべて見る", destination: ReviewListView())
                .font(.subheadline)
                .foregroundColor(AppColors.primary)
        }
    }
    
    private var memoScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: UIConstants.mediumSpacing) {
                ForEach(Array(dueMemos.prefix(5)), id: \.self) { memo in
                    Button(action: {
                        // メモの詳細表示や復習開始のアクションをここに実装
                    }) {
                        MemoPreviewCard(memo: memo)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Memo Preview Card
struct MemoPreviewCard: View {
    let memo: Memo
    
    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.smallSpacing) {
            Text(memo.title ?? "無題")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(2)
            
            if let content = memo.content, !content.isEmpty {
                Text(content)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(3)
            }
            
            HStack {
                Text("\\(memo.recallScore)%")
                    .font(.caption)
                    .foregroundColor(AppColors.retentionColor(for: Int16(memo.recallScore)))
                
                Spacer()
                
                if let nextReview = memo.nextReviewDate {
                    Text(timeAgoString(from: nextReview))
                        .font(.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
        }
        .padding()
        .frame(width: 160, height: 120)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(UIConstants.mediumCornerRadius)
    }
    
    private func timeAgoString(from date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 3600 {
            return "\\(Int(interval / 60))分前"
        } else if interval < 86400 {
            return "\\(Int(interval / 3600))時間前"
        } else {
            return "\\(Int(interval / 86400))日前"
        }
    }
}


// MARK: - Preview
struct EnhancedHomeView_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedHomeView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}