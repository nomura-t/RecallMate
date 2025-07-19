import SwiftUI

struct RankingView: View {
    @StateObject private var studySessionManager = StudySessionManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var selectedPeriod = 0 // 0: 今週, 1: 今月, 2: 全期間
    @State private var isLoading = false
    @State private var rankings: [RankingEntry] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // 期間選択
            periodSelector
            
            // ランキングリスト
            if isLoading {
                Spacer()
                ProgressView("ランキングを読み込み中...")
                Spacer()
            } else if rankings.isEmpty {
                emptyState
            } else {
                rankingList
            }
        }
        .onAppear {
            Task {
                await loadRankings()
            }
        }
        .refreshable {
            await loadRankings()
        }
    }
    
    // MARK: - Period Selector
    
    private var periodSelector: some View {
        Picker("期間", selection: $selectedPeriod) {
            Text("今週").tag(0)
            Text("今月").tag(1)
            Text("全期間").tag(2)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
        .onChange(of: selectedPeriod) {
            Task {
                await loadRankings()
            }
        }
    }
    
    // MARK: - Ranking List
    
    private var rankingList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(Array(rankings.enumerated()), id: \.offset) { index, entry in
                    RankingRowView(
                        rank: index + 1,
                        entry: entry,
                        isCurrentUser: entry.userId == (authManager.currentUser?.id.uuidString ?? "")
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "trophy")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("ランキングデータがありません")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("友達を追加して学習時間を競いましょう！")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Methods
    
    private func loadRankings() async {
        isLoading = true
        
        // モックデータを生成
        await MainActor.run {
            self.rankings = generateMockRankings()
            self.isLoading = false
        }
    }
    
    private func generateMockRankings() -> [RankingEntry] {
        // モックデータを生成
        let mockProfiles = [
            EnhancedProfile(
                id: "1",
                username: "user1",
                fullName: "田中太郎",
                nickname: "たろう",
                bio: "よろしくお願いします！",
                avatarUrl: nil,
                studyCode: "STU001",
                totalStudyMinutes: 480,
                totalMemoCount: 25,
                levelPoints: 1200,
                currentLevel: 5,
                longestStreak: 15,
                currentStreak: 8,
                isStudying: false,
                studyStartTime: nil,
                studySubject: nil,
                statusMessage: "今日も頑張るぞ！",
                isPublic: true,
                allowFriendRequests: true,
                allowGroupInvites: true,
                emailNotifications: true,
                createdAt: Date(),
                updatedAt: Date(),
                lastActiveAt: Date()
            ),
            EnhancedProfile(
                id: "2",
                username: "user2",
                fullName: "佐藤花子",
                nickname: "はなこ",
                bio: "一緒に頑張りましょう✨",
                avatarUrl: nil,
                studyCode: "STU002",
                totalStudyMinutes: 360,
                totalMemoCount: 18,
                levelPoints: 900,
                currentLevel: 4,
                longestStreak: 10,
                currentStreak: 5,
                isStudying: true,
                studyStartTime: Date(),
                studySubject: "英語",
                statusMessage: "英語学習中📚",
                isPublic: true,
                allowFriendRequests: true,
                allowGroupInvites: true,
                emailNotifications: false,
                createdAt: Date(),
                updatedAt: Date(),
                lastActiveAt: Date()
            ),
            EnhancedProfile(
                id: "3",
                username: "user3",
                fullName: "鈴木一郎",
                nickname: "いちろう",
                bio: "コツコツ頑張ってます",
                avatarUrl: nil,
                studyCode: "STU003",
                totalStudyMinutes: 240,
                totalMemoCount: 12,
                levelPoints: 600,
                currentLevel: 3,
                longestStreak: 7,
                currentStreak: 3,
                isStudying: false,
                studyStartTime: nil,
                studySubject: nil,
                statusMessage: "今日は休憩中",
                isPublic: true,
                allowFriendRequests: true,
                allowGroupInvites: false,
                emailNotifications: true,
                createdAt: Date(),
                updatedAt: Date(),
                lastActiveAt: Date()
            )
        ]
        
        return mockProfiles.enumerated().map { index, profile in
            let studyMinutes: Int
            switch selectedPeriod {
            case 0: // 今週
                studyMinutes = (3 - index) * 120
            case 1: // 今月
                studyMinutes = (3 - index) * 480
            default: // 全期間
                studyMinutes = profile.totalStudyMinutes
            }
            
            return RankingEntry(
                userId: profile.id,
                userProfile: profile,
                studyMinutes: studyMinutes,
                sessionCount: studyMinutes / 30
            )
        }.sorted { $0.studyMinutes > $1.studyMinutes }
    }
}

// MARK: - Ranking Entry Model

struct RankingEntry: Identifiable {
    let id = UUID()
    let userId: String
    let userProfile: EnhancedProfile
    let studyMinutes: Int
    let sessionCount: Int
    
    var formattedStudyTime: String {
        let hours = studyMinutes / 60
        let minutes = studyMinutes % 60
        return hours > 0 ? "\(hours)時間\(minutes)分" : "\(minutes)分"
    }
}

// MARK: - Ranking Row View

struct RankingRowView: View {
    let rank: Int
    let entry: RankingEntry
    let isCurrentUser: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // ランク表示
            rankBadge
            
            // ユーザーアバター
            if let avatarURL = entry.userProfile.avatarUrl, !avatarURL.isEmpty {
                AsyncImage(url: URL(string: avatarURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.gray)
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.gray)
            }
            
            // ユーザー情報
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.userProfile.displayName)
                    .font(.headline)
                    .foregroundColor(isCurrentUser ? .blue : .primary)
                
                HStack {
                    Label(entry.formattedStudyTime, systemImage: "clock.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label("\(entry.sessionCount)回", systemImage: "book.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(isCurrentUser ? Color.blue.opacity(0.1) : Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentUser ? Color.blue : Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var rankBadge: some View {
        ZStack {
            Circle()
                .fill(rankColor)
                .frame(width: 40, height: 40)
            
            if rank <= 3 {
                Image(systemName: rankIcon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            } else {
                Text("\(rank)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color.gray
        case 3: return Color.orange
        default: return Color.blue
        }
    }
    
    private var rankIcon: String {
        switch rank {
        case 1: return "crown.fill"
        case 2: return "medal.fill"
        case 3: return "rosette"
        default: return ""
        }
    }
}

// MARK: - Preview

struct RankingView_Previews: PreviewProvider {
    static var previews: some View {
        RankingView()
    }
}