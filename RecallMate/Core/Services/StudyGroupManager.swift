import Foundation
import Supabase

@MainActor
class StudyGroupManager: ObservableObject {
    static let shared = StudyGroupManager()
    
    @Published var myGroups: [StudyGroup] = []
    @Published var publicGroups: [StudyGroup] = []
    @Published var invitations: [GroupInvitation] = []
    @Published var currentGroup: StudyGroup?
    @Published var groupMembers: [GroupMemberDetail] = []
    @Published var groupCompetitions: [GroupCompetition] = []
    @Published var competitionRankings: [CompetitionRanking] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabaseClient = SupabaseManager.shared.client
    
    private init() {}
    
    // MARK: - Group Management
    
    func createGroup(name: String, description: String?, maxMembers: Int = 10, isPublic: Bool = true, requireApproval: Bool = false, studyGoals: [String]? = nil) async -> Bool {
        guard let userId = AuthenticationManager.shared.currentUser?.id else {
            errorMessage = "ユーザーがサインインしていません"
            return false
        }
        
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "グループ名を入力してください"
            return false
        }
        
        guard maxMembers >= 2 && maxMembers <= 50 else {
            errorMessage = "最大メンバー数は2人から50人までです"
            return false
        }
        
        isLoading = true
        
        do {
            struct CreateGroupParams: Codable {
                let p_owner_id: String
                let p_name: String
                let p_description: String?
                let p_max_members: Int
            }
            
            let params = CreateGroupParams(
                p_owner_id: userId.uuidString,
                p_name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                p_description: description?.trimmingCharacters(in: .whitespacesAndNewlines),
                p_max_members: maxMembers
            )
            
            let response: CreateGroupResponse = try await supabaseClient
                .rpc("create_study_group", params: params)
                .execute()
                .value
            
            if response.success {
                await loadMyGroups()
                errorMessage = nil
                isLoading = false
                return true
            } else {
                errorMessage = response.message ?? "グループの作成に失敗しました"
                isLoading = false
                return false
            }
        } catch {
            print("❌ グループ作成エラー: \(error)")
            errorMessage = "グループの作成に失敗しました: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    func joinGroupByCode(_ groupCode: String) async -> Bool {
        guard let userId = AuthenticationManager.shared.currentUser?.id else {
            errorMessage = "ユーザーがサインインしていません"
            return false
        }
        
        guard !groupCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "グループコードを入力してください"
            return false
        }
        
        isLoading = true
        
        do {
            // まずグループを検索
            let groups: [StudyGroup] = try await supabaseClient
                .from("study_groups")
                .select("*")
                .eq("group_code", value: groupCode.uppercased().trimmingCharacters(in: .whitespacesAndNewlines))
                .execute()
                .value
            
            guard let group = groups.first else {
                errorMessage = "グループコードが見つかりません"
                isLoading = false
                return false
            }
            
            if group.isFull {
                errorMessage = "このグループは満員です"
                isLoading = false
                return false
            }
            
            // 既にメンバーかチェック
            let existingMembers: [GroupMember] = try await supabaseClient
                .from("group_members")
                .select("*")
                .eq("group_id", value: group.id)
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            
            if !existingMembers.isEmpty {
                errorMessage = "既にこのグループのメンバーです"
                isLoading = false
                return false
            }
            
            // メンバーとして追加
            let newMember = [
                "group_id": group.id,
                "user_id": userId.uuidString,
                "role": "member"
            ]
            
            try await supabaseClient
                .from("group_members")
                .insert(newMember)
                .execute()
            
            // グループのメンバー数を更新
            try await supabaseClient
                .from("study_groups")
                .update(["current_members": group.currentMembers + 1])
                .eq("id", value: group.id)
                .execute()
            
            await loadMyGroups()
            errorMessage = nil
            isLoading = false
            return true
        } catch {
            print("❌ グループ参加エラー: \(error)")
            errorMessage = "グループ参加に失敗しました: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    func leaveGroup(groupId: String) async -> Bool {
        guard let userId = AuthenticationManager.shared.currentUser?.id else {
            errorMessage = "ユーザーがサインインしていません"
            return false
        }
        
        isLoading = true
        
        do {
            // メンバーから削除
            try await supabaseClient
                .from("group_members")
                .delete()
                .eq("group_id", value: groupId)
                .eq("user_id", value: userId.uuidString)
                .execute()
            
            // グループのメンバー数を更新
            let group: StudyGroup = try await supabaseClient
                .from("study_groups")
                .select("*")
                .eq("id", value: groupId)
                .single()
                .execute()
                .value
            
            try await supabaseClient
                .from("study_groups")
                .update(["current_members": max(0, group.currentMembers - 1)])
                .eq("id", value: groupId)
                .execute()
            
            await loadMyGroups()
            errorMessage = nil
            isLoading = false
            return true
        } catch {
            print("❌ グループ退出エラー: \(error)")
            errorMessage = "グループ退出に失敗しました: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    func loadMyGroups() async {
        guard let userId = AuthenticationManager.shared.currentUser?.id else {
            errorMessage = "ユーザーがサインインしていません"
            return
        }
        
        isLoading = true
        
        do {
            let groups: [StudyGroup] = try await supabaseClient
                .from("study_groups")
                .select("*")
                .eq("id", value: "in.(select group_id from group_members where user_id = '\(userId.uuidString)')")
                .order("created_at", ascending: false)
                .execute()
                .value
            
            myGroups = groups
            errorMessage = nil
            print("✅ 自分のグループ一覧読み込み成功: \(groups.count)個")
        } catch {
            print("❌ グループ一覧読み込みエラー: \(error)")
            errorMessage = "グループ一覧の読み込みに失敗しました"
        }
        
        isLoading = false
    }
    
    func loadGroupMembers(groupId: String) async {
        isLoading = true
        
        do {
            let members: [GroupMemberDetail] = try await supabaseClient
                .from("group_members_detailed")
                .select("*")
                .eq("group_id", value: groupId)
                .order("joined_at", ascending: true)
                .execute()
                .value
            
            groupMembers = members
            errorMessage = nil
            print("✅ グループメンバー読み込み成功: \(members.count)人")
        } catch {
            print("❌ グループメンバー読み込みエラー: \(error)")
            errorMessage = "グループメンバーの読み込みに失敗しました"
        }
        
        isLoading = false
    }
    
    func kickMember(groupId: String, userId: String) async -> Bool {
        guard let currentUserId = AuthenticationManager.shared.currentUser?.id else {
            errorMessage = "ユーザーがサインインしていません"
            return false
        }
        
        isLoading = true
        
        do {
            // 現在のユーザーがオーナーまたは管理者かチェック
            let currentUserMembership: [GroupMember] = try await supabaseClient
                .from("group_members")
                .select("*")
                .eq("group_id", value: groupId)
                .eq("user_id", value: currentUserId.uuidString)
                .execute()
                .value
            
            guard let membership = currentUserMembership.first,
                  membership.role == .owner || membership.role == .admin else {
                errorMessage = "メンバーを削除する権限がありません"
                isLoading = false
                return false
            }
            
            // メンバーを削除
            try await supabaseClient
                .from("group_members")
                .delete()
                .eq("group_id", value: groupId)
                .eq("user_id", value: userId)
                .execute()
            
            // グループのメンバー数を更新
            let group: StudyGroup = try await supabaseClient
                .from("study_groups")
                .select("*")
                .eq("id", value: groupId)
                .single()
                .execute()
                .value
            
            try await supabaseClient
                .from("study_groups")
                .update(["current_members": max(0, group.currentMembers - 1)])
                .eq("id", value: groupId)
                .execute()
            
            await loadGroupMembers(groupId: groupId)
            errorMessage = nil
            isLoading = false
            return true
        } catch {
            print("❌ メンバー削除エラー: \(error)")
            errorMessage = "メンバー削除に失敗しました: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    // MARK: - Competition Management
    
    func createCompetition(groupId: String, name: String, description: String?, type: CompetitionType, durationDays: Int) async -> Bool {
        guard let userId = AuthenticationManager.shared.currentUser?.id else {
            errorMessage = "ユーザーがサインインしていません"
            return false
        }
        
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "対戦名を入力してください"
            return false
        }
        
        guard durationDays >= 1 && durationDays <= 30 else {
            errorMessage = "期間は1日から30日までです"
            return false
        }
        
        isLoading = true
        
        do {
            // 現在のユーザーがグループのメンバーかチェック
            let membership: [GroupMember] = try await supabaseClient
                .from("group_members")
                .select("*")
                .eq("group_id", value: groupId)
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            
            guard !membership.isEmpty else {
                errorMessage = "このグループのメンバーではありません"
                isLoading = false
                return false
            }
            
            let startDate = Date()
            let endDate = Calendar.current.date(byAdding: .day, value: durationDays, to: startDate) ?? startDate
            
            let competition = [
                "id": UUID().uuidString,
                "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
                "description": description?.trimmingCharacters(in: .whitespacesAndNewlines),
                "group_id": groupId,
                "competition_type": type.rawValue,
                "start_date": startDate.ISO8601Format(),
                "end_date": endDate.ISO8601Format(),
                "is_active": "true",
                "created_by": userId.uuidString
            ]
            
            try await supabaseClient
                .from("group_competitions")
                .insert(competition)
                .execute()
            
            await loadGroupCompetitions(groupId: groupId)
            errorMessage = nil
            isLoading = false
            return true
        } catch {
            print("❌ 対戦作成エラー: \(error)")
            errorMessage = "対戦の作成に失敗しました: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    func loadGroupCompetitions(groupId: String) async {
        isLoading = true
        
        do {
            let competitions: [GroupCompetition] = try await supabaseClient
                .from("group_competitions")
                .select("*")
                .eq("group_id", value: groupId)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            groupCompetitions = competitions
            errorMessage = nil
            print("✅ グループ対戦一覧読み込み成功: \(competitions.count)個")
        } catch {
            print("❌ グループ対戦読み込みエラー: \(error)")
            errorMessage = "グループ対戦の読み込みに失敗しました"
        }
        
        isLoading = false
    }
    
    func loadCompetitionRankings(competitionId: String) async {
        isLoading = true
        
        do {
            let rankings: [CompetitionRanking] = try await supabaseClient
                .from("competition_rankings")
                .select("*")
                .eq("competition_id", value: competitionId)
                .order("rank", ascending: true)
                .execute()
                .value
            
            competitionRankings = rankings
            errorMessage = nil
            print("✅ 対戦ランキング読み込み成功: \(rankings.count)人")
        } catch {
            print("❌ 対戦ランキング読み込みエラー: \(error)")
            errorMessage = "対戦ランキングの読み込みに失敗しました"
        }
        
        isLoading = false
    }
    
    func joinCompetition(competitionId: String) async -> Bool {
        guard let userId = AuthenticationManager.shared.currentUser?.id else {
            errorMessage = "ユーザーがサインインしていません"
            return false
        }
        
        isLoading = true
        
        do {
            // 既に参加しているかチェック
            let participants: [CompetitionParticipant] = try await supabaseClient
                .from("competition_participants")
                .select("*")
                .eq("competition_id", value: competitionId)
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            
            if !participants.isEmpty {
                errorMessage = "既にこの対戦に参加しています"
                isLoading = false
                return false
            }
            
            // 参加者として追加
            let participant = [
                "id": UUID().uuidString,
                "competition_id": competitionId,
                "user_id": userId.uuidString,
                "study_minutes": "0",
                "memo_count": "0",
                "streak_days": "0"
            ]
            
            try await supabaseClient
                .from("competition_participants")
                .insert(participant)
                .execute()
            
            await loadCompetitionRankings(competitionId: competitionId)
            errorMessage = nil
            isLoading = false
            return true
        } catch {
            print("❌ 対戦参加エラー: \(error)")
            errorMessage = "対戦参加に失敗しました: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    // MARK: - Utility Methods
    
    func findGroupByCode(_ groupCode: String) async -> StudyGroup? {
        guard !groupCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        
        do {
            let groups: [StudyGroup] = try await supabaseClient
                .from("study_groups")
                .select("*")
                .eq("group_code", value: groupCode.uppercased().trimmingCharacters(in: .whitespacesAndNewlines))
                .execute()
                .value
            
            return groups.first
        } catch {
            print("❌ グループコード検索エラー: \(error)")
            return nil
        }
    }
    
    func selectGroup(_ group: StudyGroup) async {
        currentGroup = group
        await loadGroupMembers(groupId: group.id)
        await loadGroupCompetitions(groupId: group.id)
    }
    
    func refreshGroupData() async {
        await loadMyGroups()
        if let currentGroup = currentGroup {
            await loadGroupMembers(groupId: currentGroup.id)
            await loadGroupCompetitions(groupId: currentGroup.id)
        }
    }
    
    func refreshAllData() async {
        await refreshGroupData()
        await loadPublicGroups()
        await loadInvitations()
    }
    
    // MARK: - Helper Methods
    
    func getUserRole(in groupId: String) -> GroupRole? {
        guard let userId = AuthenticationManager.shared.currentUser?.id else { return nil }
        return groupMembers.first(where: { $0.userId == userId.uuidString })?.role
    }
    
    func canManageGroup(_ groupId: String) -> Bool {
        guard let role = getUserRole(in: groupId) else { return false }
        return role.canManageGroup
    }
    
    func canKickMembers(_ groupId: String) -> Bool {
        guard let role = getUserRole(in: groupId) else { return false }
        return role.canKickMembers
    }
    
    func getCurrentMember(groupId: String) -> GroupMemberDetail? {
        guard let userId = AuthenticationManager.shared.currentUser?.id else { return nil }
        
        // If we have member data loaded for this group, use it
        if currentGroup?.id == groupId {
            return groupMembers.first(where: { $0.userId == userId.uuidString })
        }
        
        // Otherwise return nil - the UI should handle loading state
        return nil
    }
    
    func getCurrentMemberRole(groupId: String) -> GroupRole? {
        return getCurrentMember(groupId: groupId)?.role
    }
    
    // MARK: - Public Groups
    
    func loadPublicGroups() async {
        isLoading = true
        
        do {
            let groups: [StudyGroup] = try await supabaseClient
                .from("study_groups")
                .select("*")
                .eq("is_public", value: true)
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
                .value
            
            publicGroups = groups
            errorMessage = nil
            print("✅ 公開グループ一覧読み込み成功: \(groups.count)個")
        } catch {
            print("❌ 公開グループ読み込みエラー: \(error)")
            errorMessage = "公開グループの読み込みに失敗しました"
        }
        
        isLoading = false
    }
    
    func searchGroups(query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            await loadPublicGroups()
            return
        }
        
        isLoading = true
        
        do {
            let groups: [StudyGroup] = try await supabaseClient
                .from("study_groups")
                .select("*")
                .eq("is_public", value: true)
                .or("name.ilike.%\(query)%,description.ilike.%\(query)%")
                .order("created_at", ascending: false)
                .limit(20)
                .execute()
                .value
            
            publicGroups = groups
            errorMessage = nil
            print("✅ グループ検索成功: \(groups.count)個")
        } catch {
            print("❌ グループ検索エラー: \(error)")
            errorMessage = "グループ検索に失敗しました"
        }
        
        isLoading = false
    }
    
    func joinGroup(groupId: String) async -> Bool {
        guard let userId = AuthenticationManager.shared.currentUser?.id else {
            errorMessage = "ユーザーがサインインしていません"
            return false
        }
        
        isLoading = true
        
        do {
            // グループ情報を取得
            let group: StudyGroup = try await supabaseClient
                .from("study_groups")
                .select("*")
                .eq("id", value: groupId)
                .single()
                .execute()
                .value
            
            if group.isFull {
                errorMessage = "このグループは満員です"
                isLoading = false
                return false
            }
            
            // 既にメンバーかチェック
            let existingMembers: [GroupMember] = try await supabaseClient
                .from("group_members")
                .select("*")
                .eq("group_id", value: groupId)
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            
            if !existingMembers.isEmpty {
                errorMessage = "既にこのグループのメンバーです"
                isLoading = false
                return false
            }
            
            // メンバーとして追加
            let newMember = [
                "group_id": groupId,
                "user_id": userId.uuidString,
                "role": "member"
            ]
            
            try await supabaseClient
                .from("group_members")
                .insert(newMember)
                .execute()
            
            // グループのメンバー数を更新
            try await supabaseClient
                .from("study_groups")
                .update(["current_members": group.currentMembers + 1])
                .eq("id", value: groupId)
                .execute()
            
            await loadMyGroups()
            await loadPublicGroups()
            errorMessage = nil
            isLoading = false
            return true
        } catch {
            print("❌ グループ参加エラー: \(error)")
            errorMessage = "グループ参加に失敗しました: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    // MARK: - Invitations
    
    func loadInvitations() async {
        guard let userId = AuthenticationManager.shared.currentUser?.id else {
            errorMessage = "ユーザーがサインインしていません"
            return
        }
        
        isLoading = true
        
        do {
            let invitations: [GroupInvitation] = try await supabaseClient
                .from("group_invitations")
                .select("*, group:study_groups(*), inviter:profiles(*)")
                .eq("invitee_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            self.invitations = invitations
            errorMessage = nil
            print("✅ 招待一覧読み込み成功: \(invitations.count)個")
        } catch {
            print("❌ 招待一覧読み込みエラー: \(error)")
            errorMessage = "招待一覧の読み込みに失敗しました"
        }
        
        isLoading = false
    }
    
    func respondToInvitation(invitationId: String, accept: Bool) async -> Bool {
        guard let userId = AuthenticationManager.shared.currentUser?.id else {
            errorMessage = "ユーザーがサインインしていません"
            return false
        }
        
        isLoading = true
        
        do {
            // 招待の状態を更新
            let status = accept ? "accepted" : "rejected"
            try await supabaseClient
                .from("group_invitations")
                .update(["status": status])
                .eq("id", value: invitationId)
                .eq("invitee_id", value: userId.uuidString)
                .execute()
            
            if accept {
                // 招待を取得してグループIDを確認
                let invitation: GroupInvitation = try await supabaseClient
                    .from("group_invitations")
                    .select("*")
                    .eq("id", value: invitationId)
                    .single()
                    .execute()
                    .value
                
                // グループメンバーとして追加
                let newMember = [
                    "group_id": invitation.groupId,
                    "user_id": userId.uuidString,
                    "role": "member"
                ]
                
                try await supabaseClient
                    .from("group_members")
                    .insert(newMember)
                    .execute()
                
                // グループのメンバー数を更新
                let group: StudyGroup = try await supabaseClient
                    .from("study_groups")
                    .select("*")
                    .eq("id", value: invitation.groupId)
                    .single()
                    .execute()
                    .value
                
                try await supabaseClient
                    .from("study_groups")
                    .update(["current_members": group.currentMembers + 1])
                    .eq("id", value: invitation.groupId)
                    .execute()
                
                await loadMyGroups()
            }
            
            await loadInvitations()
            errorMessage = nil
            isLoading = false
            return true
        } catch {
            print("❌ 招待応答エラー: \(error)")
            errorMessage = "招待応答に失敗しました: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    func loadGroupDetails(groupId: String) async {
        // 一時的な実装
        await loadGroupMembers(groupId: groupId)
    }
}