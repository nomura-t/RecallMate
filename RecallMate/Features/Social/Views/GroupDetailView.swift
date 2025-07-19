import SwiftUI

struct GroupDetailView: View {
    let group: StudyGroup
    @Environment(\.dismiss) private var dismiss
    @StateObject private var groupManager = StudyGroupManager.shared
    @StateObject private var chatManager = GroupChatManager.shared
    @State private var selectedTab = 0
    @State private var showInviteSheet = false
    @State private var showManageSheet = false
    @State private var showLeaveAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
                // グループヘッダー
                groupHeader
                
                // タブ選択
                tabSelector
                
                // コンテンツ
                TabView(selection: $selectedTab) {
                    // 概要
                    overviewView
                        .tag(0)
                    
                    // メンバー
                    membersView
                        .tag(1)
                    
                    // アクティビティ
                    activityView
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle(group.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if canManageGroup {
                            Button("グループを管理") {
                                showManageSheet = true
                            }
                            
                            Button("メンバーを招待") {
                                showInviteSheet = true
                            }
                        }
                        
                        Button("チャットを開く") {
                            // チャット画面を開く
                        }
                        
                        Button("グループを退出", role: .destructive) {
                            showLeaveAlert = true
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
            .sheet(isPresented: $showInviteSheet) {
                InviteMemberView(group: group)
            }
            .sheet(isPresented: $showManageSheet) {
                ManageGroupView(group: group)
            }
            .alert("グループを退出", isPresented: $showLeaveAlert) {
                Button("退出", role: .destructive) {
                    Task {
                        let success = await groupManager.leaveGroup(groupId: group.id)
                        if success {
                            dismiss()
                        }
                    }
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("本当にグループを退出しますか？")
            }
            .onAppear {
                Task {
                    await groupManager.loadGroupDetails(groupId: group.id)
                }
            }
        }
    }
    
    // MARK: - Group Header
    
    private var groupHeader: some View {
        VStack(spacing: 16) {
            // グループアイコン
            AsyncImage(url: URL(string: group.coverImageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.3.fill")
                            .foregroundColor(.white)
                            .font(.title)
                    )
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(spacing: 8) {
                Text(group.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                if let description = group.description {
                    Text(description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // 基本情報
                HStack {
                    Label("\(group.currentMembers)/\(group.maxMembers)", systemImage: "person.2.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if group.isPublic {
                        Label("公開", systemImage: "globe")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Label("非公開", systemImage: "lock")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    Label(group.groupCode, systemImage: "number")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .fontDesign(.monospaced)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack {
            tabButton(title: "概要", tag: 0)
            tabButton(title: "メンバー", tag: 1)
            tabButton(title: "アクティビティ", tag: 2)
        }
        .padding(.horizontal)
    }
    
    private func tabButton(title: String, tag: Int) -> some View {
        Button {
            selectedTab = tag
        } label: {
            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(selectedTab == tag ? .semibold : .regular)
                
                Rectangle()
                    .fill(selectedTab == tag ? Color.blue : Color.clear)
                    .frame(height: 2)
            }
        }
        .foregroundColor(selectedTab == tag ? .blue : .secondary)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Overview View
    
    private var overviewView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 学習目標
                if let goals = group.studyGoals, !goals.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("学習目標")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        ForEach(goals, id: \.self) { goal in
                            HStack {
                                Image(systemName: "target")
                                    .foregroundColor(.blue)
                                
                                Text(goal)
                                    .font(.subheadline)
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // グループ統計
                groupStats
                
                // 最近のアクティビティ
                recentActivity
                
                // チャットプレビュー
                chatPreview
            }
            .padding()
        }
    }
    
    // MARK: - Members View
    
    private var membersView: some View {
        List(groupManager.groupMembers, id: \.id) { member in
            GroupMemberDetailRowView(member: member)
        }
        .refreshable {
            await groupManager.loadGroupMembers(groupId: group.id)
        }
    }
    
    // MARK: - Activity View
    
    private var activityView: some View {
        VStack {
            // アクティビティフィルター
            // 実装予定
            
            Text("アクティビティ履歴")
                .font(.headline)
                .padding()
            
            // アクティビティリスト
            // 実装予定
            
            Spacer()
        }
    }
    
    // MARK: - Group Stats
    
    private var groupStats: some View {
        VStack(spacing: 16) {
            Text("グループ統計")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                statCard(
                    title: "総学習時間",
                    value: "120時間",
                    icon: "clock.fill",
                    color: .blue
                )
                
                statCard(
                    title: "平均学習時間",
                    value: "2.5時間",
                    icon: "chart.bar.fill",
                    color: .green
                )
                
                statCard(
                    title: "アクティブメンバー",
                    value: "\(group.currentMembers - 2)人",
                    icon: "person.fill.checkmark",
                    color: .orange
                )
                
                statCard(
                    title: "今週の目標達成率",
                    value: "85%",
                    icon: "target",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(radius: 1)
    }
    
    // MARK: - Recent Activity
    
    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近のアクティビティ")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                activityItem(
                    user: "田中さん",
                    action: "30分間学習しました",
                    time: "2時間前",
                    icon: "clock.fill",
                    color: .blue
                )
                
                activityItem(
                    user: "佐藤さん",
                    action: "新しいメモを作成しました",
                    time: "3時間前",
                    icon: "doc.text.fill",
                    color: .green
                )
                
                activityItem(
                    user: "鈴木さん",
                    action: "グループに参加しました",
                    time: "5時間前",
                    icon: "person.badge.plus",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func activityItem(user: String, action: String, time: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20, height: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(action)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Chat Preview
    
    private var chatPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("チャット")
                    .font(.headline)
                
                Spacer()
                
                Button("すべて表示") {
                    // チャット画面を開く
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            VStack(spacing: 8) {
                chatMessage(
                    user: "田中さん",
                    message: "今日も頑張りましょう！",
                    time: "10:30"
                )
                
                chatMessage(
                    user: "佐藤さん",
                    message: "英語の勉強を始めます",
                    time: "10:28"
                )
                
                chatMessage(
                    user: "鈴木さん",
                    message: "よろしくお願いします",
                    time: "10:25"
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func chatMessage(user: String, message: String, time: String) -> some View {
        HStack {
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 30, height: 30)
                .overlay(
                    Text(String(user.prefix(1)))
                        .font(.caption)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(message)
                    .font(.subheadline)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text(time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Helper Properties
    
    private var canManageGroup: Bool {
        guard let member = groupManager.getCurrentMember(groupId: group.id) else {
            return false
        }
        return member.role.canManageMembers
    }
}

// MARK: - Group Member Row View

struct GroupMemberRowView: View {
    let member: GroupMember
    
    var body: some View {
        HStack {
            // アバター
            AsyncImage(url: URL(string: member.profile?.avatarUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(member.profile?.displayName ?? "Unknown")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("参加日: \(DateFormatter.shortDate.string(from: member.joinedAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(member.role.displayName)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                
                if member.contributionScore > 0 {
                    Text("貢献度: \(member.contributionScore)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Invite Member View

struct InviteMemberView: View {
    let group: StudyGroup
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("メンバー招待機能")
                    .font(.headline)
                    .padding()
                
                Text("実装予定")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("メンバーを招待")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Manage Group View

struct ManageGroupView: View {
    let group: StudyGroup
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("グループ管理機能")
                    .font(.headline)
                    .padding()
                
                Text("実装予定")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("グループを管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Group Member Detail Row View

struct GroupMemberDetailRowView: View {
    let member: GroupMemberDetail
    
    var body: some View {
        HStack {
            // アバター
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(member.nickname?.prefix(1) ?? member.fullName?.prefix(1) ?? "?"))
                        .font(.headline)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(member.nickname ?? member.fullName ?? "Unknown")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(member.role.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if member.isStudying {
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    
                    Text("学習中")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

struct GroupDetailView_Previews: PreviewProvider {
    static var previews: some View {
        GroupDetailView(group: StudyGroup(
            id: "1",
            name: "英語学習グループ",
            description: "一緒に英語を学習しましょう",
            groupCode: "ENG12345",
            coverImageUrl: nil,
            ownerId: "owner1",
            maxMembers: 20,
            currentMembers: 5,
            isPublic: true,
            allowJoinRequests: true,
            requireApproval: false,
            studyGoals: ["TOEIC 800点", "英会話スキル向上"],
            studySchedule: nil,
            createdAt: Date(),
            updatedAt: Date()
        ))
    }
}