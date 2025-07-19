import SwiftUI
import Foundation

struct StudyGroupsView: View {
    @StateObject private var groupManager = StudyGroupManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var showCreateGroupSheet = false
    @State private var showJoinGroupSheet = false
    @State private var joinGroupCode = ""
    @State private var selectedGroup: StudyGroup?
    @State private var showGroupDetail: StudyGroup?
    
    var body: some View {
        VStack {
            // 検索バー
            searchBar
            
            // タブ選択
            tabSelector
            
            // コンテンツ
            TabView(selection: $selectedTab) {
                // 参加中のグループ（要認証）
                if authManager.isAuthenticated {
                    myGroupsView
                        .tag(0)
                } else {
                    authenticationRequiredForMyGroups
                        .tag(0)
                }
                
                // 公開グループ（閲覧可能）
                publicGroupsView
                    .tag(1)
                
                // 招待・申請（要認証）
                if authManager.isAuthenticated {
                    invitationsView
                        .tag(2)
                } else {
                    authenticationRequiredForInvitations
                        .tag(2)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .sheet(isPresented: $showCreateGroupSheet) {
            CreateGroupView()
        }
        .sheet(isPresented: $showJoinGroupSheet) {
            JoinGroupSheetView(joinGroupCode: $joinGroupCode, groupManager: groupManager)
        }
        .sheet(item: $showGroupDetail) { group in
            GroupDetailView(group: group)
        }
        .onAppear {
            Task {
                await groupManager.refreshAllData()
            }
        }
    }
    
    // MARK: - Authentication Required Views
    
    private var authenticationRequiredForMyGroups: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "person.3.fill")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            Text("参加中のグループを見るには\nログインが必要です")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            NavigationLink(destination: LoginView()) {
                Text("ログインする")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            Spacer()
        }
    }
    
    private var authenticationRequiredForInvitations: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "envelope.badge")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            Text("招待・申請を管理するには\nログインが必要です")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            NavigationLink(destination: LoginView()) {
                Text("ログインする")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            Spacer()
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("グループを検索", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    Task {
                        await performSearch()
                    }
                }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack {
            tabButton(title: "参加中", count: groupManager.myGroups.count, tag: 0)
            tabButton(title: "公開グループ", count: groupManager.publicGroups.count, tag: 1)
            tabButton(title: "招待・申請", count: groupManager.invitations.count, tag: 2)
        }
        .padding(.horizontal)
    }
    
    private func tabButton(title: String, count: Int, tag: Int) -> some View {
        Button {
            selectedTab = tag
        } label: {
            VStack(spacing: 4) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(selectedTab == tag ? .semibold : .regular)
                    
                    if count > 0 {
                        Text("\(count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Rectangle()
                    .fill(selectedTab == tag ? Color.blue : Color.clear)
                    .frame(height: 2)
            }
        }
        .foregroundColor(selectedTab == tag ? .blue : .secondary)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - My Groups View
    
    private var myGroupsView: some View {
        Group {
            if groupManager.myGroups.isEmpty {
                emptyStateView(
                    icon: "person.3",
                    title: "参加中のグループなし",
                    description: "学習グループに参加して、みんなで学習しましょう",
                    buttonTitle: "グループを作成",
                    buttonAction: {
                        showCreateGroupSheet = true
                    }
                )
            } else {
                List(filteredMyGroups, id: \.id) { group in
                    GroupRowView(group: group, showRole: true) {
                        showGroupDetail = group
                    }
                }
            }
        }
        .refreshable {
            await groupManager.loadMyGroups()
        }
    }
    
    // MARK: - Public Groups View
    
    private var publicGroupsView: some View {
        Group {
            if groupManager.publicGroups.isEmpty {
                emptyStateView(
                    icon: "globe",
                    title: "公開グループなし",
                    description: "公開グループが見つかりません",
                    buttonTitle: "グループを作成",
                    buttonAction: {
                        showCreateGroupSheet = true
                    }
                )
            } else {
                List(filteredPublicGroups, id: \.id) { group in
                    GroupRowView(group: group, showRole: false) {
                        showGroupDetail = group
                    }
                }
            }
        }
        .refreshable {
            await groupManager.loadPublicGroups()
        }
    }
    
    // MARK: - Invitations View
    
    private var invitationsView: some View {
        Group {
            if groupManager.invitations.isEmpty {
                emptyStateView(
                    icon: "envelope",
                    title: "招待・申請なし",
                    description: "グループ招待や参加申請があると表示されます",
                    buttonTitle: "グループを探す",
                    buttonAction: {
                        selectedTab = 1
                    }
                )
            } else {
                List(groupManager.invitations, id: \.id) { invitation in
                    InvitationRowView(invitation: invitation)
                }
            }
        }
        .refreshable {
            await groupManager.loadInvitations()
        }
    }
    
    // MARK: - Helper Views
    
    private func emptyStateView(
        icon: String,
        title: String,
        description: String,
        buttonTitle: String,
        buttonAction: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(buttonTitle) {
                buttonAction()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Filtered Data
    
    private var filteredMyGroups: [StudyGroup] {
        if searchText.isEmpty {
            return groupManager.myGroups
        }
        return groupManager.myGroups.filter { group in
            group.name.localizedCaseInsensitiveContains(searchText) ||
            group.description?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
    
    private var filteredPublicGroups: [StudyGroup] {
        if searchText.isEmpty {
            return groupManager.publicGroups
        }
        return groupManager.publicGroups.filter { group in
            group.name.localizedCaseInsensitiveContains(searchText) ||
            group.description?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
    
    // MARK: - Search
    
    private func performSearch() async {
        guard !searchText.isEmpty else { return }
        
        await groupManager.searchGroups(query: searchText)
    }
}

// MARK: - Group Row View

struct GroupRowView: View {
    let group: StudyGroup
    let showRole: Bool
    let onTap: () -> Void
    
    @ObservedObject var groupManager: StudyGroupManager = StudyGroupManager.shared
    
    var body: some View {
        HStack {
            // グループアイコン
            AsyncImage(url: URL(string: group.coverImageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.3.fill")
                            .foregroundColor(.white)
                            .font(.title3)
                    )
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.headline)
                    .lineLimit(1)
                
                if let description = group.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // メンバー数と公開状態
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
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if showRole {
                    // 自分の役割を表示
                    RoleDisplayView(groupId: group.id, groupManager: groupManager)
                } else {
                    // 参加ボタン
                    Button {
                        Task {
                            await groupManager.joinGroup(groupId: group.id)
                        }
                    } label: {
                        Text(group.canJoin ? "参加" : "満員")
                            .font(.caption)
                            .foregroundColor(group.canJoin ? .blue : .secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        group.canJoin ? Color.blue : Color.secondary,
                                        lineWidth: 1
                                    )
                            )
                    }
                    .disabled(!group.canJoin)
                }
                
                Text(group.groupCode)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontDesign(.monospaced)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Role Display View

struct RoleDisplayView: View {
    let groupId: String
    @ObservedObject var groupManager: StudyGroupManager
    @State private var currentMember: GroupMemberDetail?
    
    var body: some View {
        Group {
            if let member = currentMember {
                Text(member.role.displayName)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            } else {
                Text("メンバー")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .onAppear {
            loadCurrentMember()
        }
        .onChange(of: groupManager.groupMembers) {
            loadCurrentMember()
        }
    }
    
    private func loadCurrentMember() {
        currentMember = groupManager.getCurrentMember(groupId: groupId)
        
        // If we don't have member data, load it
        if currentMember == nil && groupManager.currentGroup?.id != groupId {
            Task {
                await groupManager.loadGroupMembers(groupId: groupId)
                await MainActor.run {
                    currentMember = groupManager.getCurrentMember(groupId: groupId)
                }
            }
        }
    }
}

// MARK: - Invitation Row View

struct InvitationRowView: View {
    let invitation: GroupInvitation
    
    @ObservedObject var groupManager: StudyGroupManager = StudyGroupManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // タイプアイコン
                Image(systemName: invitation.type == .invitation ? "envelope.fill" : "person.crop.circle.badge.plus")
                    .foregroundColor(invitation.type == .invitation ? .blue : .green)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(invitation.type.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(invitation.type == .invitation ? .blue : .green)
                    
                    if let groupName = invitation.group?.name {
                        Text(groupName)
                            .font(.headline)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Text(invitation.status.displayName)
                    .font(.caption)
                    .foregroundColor(statusColor(invitation.status))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(invitation.status).opacity(0.1))
                    .cornerRadius(8)
            }
            
            if let message = invitation.message, !message.isEmpty {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            if invitation.status == .pending {
                HStack {
                    Button("承認") {
                        Task {
                            await groupManager.respondToInvitation(
                                invitationId: invitation.id,
                                accept: true
                            )
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    
                    Button("拒否") {
                        Task {
                            await groupManager.respondToInvitation(
                                invitationId: invitation.id,
                                accept: false
                            )
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Spacer()
                    
                    Text("期限: \(DateFormatter.shortDate.string(from: invitation.expiresAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func statusColor(_ status: InvitationStatus) -> Color {
        switch status {
        case .pending:
            return .orange
        case .accepted:
            return .green
        case .rejected:
            return .red
        case .expired:
            return .secondary
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
}

// MARK: - Join Group Sheet View

struct JoinGroupSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var joinGroupCode: String
    @ObservedObject var groupManager: StudyGroupManager
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    VStack(spacing: 8) {
                        Text("グループに参加")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("グループコードを入力してください")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("グループコード")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("例: ABC123", text: $joinGroupCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }
                
                Button {
                    joinGroup()
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .tint(.white)
                                .scaleEffect(0.8)
                        } else {
                            Text("参加")
                                .fontWeight(.medium)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(joinGroupCode.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(joinGroupCode.isEmpty || isLoading)
                
                Spacer()
            }
            .padding()
            .navigationTitle("グループに参加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func joinGroup() {
        isLoading = true
        
        Task {
            let success = await groupManager.joinGroupByCode(joinGroupCode)
            await MainActor.run {
                isLoading = false
                if success {
                    joinGroupCode = ""
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Preview

struct StudyGroupsView_Previews: PreviewProvider {
    static var previews: some View {
        StudyGroupsView()
    }
}