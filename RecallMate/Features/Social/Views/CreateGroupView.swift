import SwiftUI

struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var groupManager = StudyGroupManager.shared
    @State private var groupName = ""
    @State private var groupDescription = ""
    @State private var maxMembers = 10
    @State private var isPublic = true
    @State private var requireApproval = false
    @State private var studyGoals: [String] = []
    @State private var newGoal = ""
    @State private var isCreating = false
    
    var body: some View {
        NavigationView {
            Form {
                // 基本情報
                Section(header: Text("基本情報")) {
                    TextField("グループ名", text: $groupName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("説明（任意）", text: $groupDescription, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                
                // 設定
                Section(header: Text("設定")) {
                    HStack {
                        Text("最大メンバー数")
                        Spacer()
                        Stepper(value: $maxMembers, in: 2...100) {
                            Text("\(maxMembers)人")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Toggle("公開グループ", isOn: $isPublic)
                    
                    Toggle("参加申請の承認が必要", isOn: $requireApproval)
                }
                
                // 学習目標
                Section(header: Text("学習目標"), footer: Text("グループで達成したい学習目標を設定しましょう")) {
                    ForEach(studyGoals.indices, id: \.self) { index in
                        HStack {
                            Text("・\(studyGoals[index])")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Button {
                                studyGoals.remove(at: index)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    HStack {
                        TextField("新しい目標を追加", text: $newGoal)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onSubmit {
                                addGoal()
                            }
                        
                        Button("追加") {
                            addGoal()
                        }
                        .disabled(newGoal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                
                // プレビュー
                Section(header: Text("プレビュー")) {
                    GroupPreviewView(
                        name: groupName,
                        description: groupDescription,
                        maxMembers: maxMembers,
                        isPublic: isPublic,
                        requireApproval: requireApproval,
                        studyGoals: studyGoals
                    )
                }
            }
            .navigationTitle("グループを作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("作成") {
                        Task {
                            await createGroup()
                        }
                    }
                    .disabled(groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreating)
                }
            }
            .disabled(isCreating)
            .overlay(
                Group {
                    if isCreating {
                        LoadingOverlay()
                    }
                }
            )
        }
    }
    
    private func addGoal() {
        let goal = newGoal.trimmingCharacters(in: .whitespacesAndNewlines)
        if !goal.isEmpty && !studyGoals.contains(goal) {
            studyGoals.append(goal)
            newGoal = ""
        }
    }
    
    private func createGroup() async {
        isCreating = true
        
        let success = await groupManager.createGroup(
            name: groupName.trimmingCharacters(in: .whitespacesAndNewlines),
            description: groupDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : groupDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            maxMembers: maxMembers,
            isPublic: isPublic,
            requireApproval: requireApproval,
            studyGoals: studyGoals.isEmpty ? nil : studyGoals
        )
        
        isCreating = false
        
        if success {
            dismiss()
        }
    }
}

// MARK: - Group Preview View

struct GroupPreviewView: View {
    let name: String
    let description: String
    let maxMembers: Int
    let isPublic: Bool
    let requireApproval: Bool
    let studyGoals: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // グループアイコン
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.3.fill")
                            .foregroundColor(.white)
                            .font(.title3)
                    )
                    .frame(width: 50, height: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(name.isEmpty ? "グループ名" : name)
                        .font(.headline)
                        .foregroundColor(name.isEmpty ? .secondary : .primary)
                    
                    if !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    HStack {
                        Label("1/\(maxMembers)", systemImage: "person.2.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if isPublic {
                            Label("公開", systemImage: "globe")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Label("非公開", systemImage: "lock")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        
                        if requireApproval {
                            Label("承認制", systemImage: "checkmark.shield")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Spacer()
            }
            
            if !studyGoals.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("学習目標")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(studyGoals, id: \.self) { goal in
                        HStack {
                            Image(systemName: "target")
                                .foregroundColor(.blue)
                                .font(.caption)
                            
                            Text(goal)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Join Group View

struct JoinGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var groupManager = StudyGroupManager.shared
    @State private var groupCode = ""
    @State private var foundGroup: StudyGroup?
    @State private var isSearching = false
    @State private var searchMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 説明
                VStack(spacing: 16) {
                    Image(systemName: "person.3.sequence.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    VStack(spacing: 8) {
                        Text("グループに参加")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("グループコードを入力してグループに参加しましょう")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // グループコード入力
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "number")
                            .foregroundColor(.secondary)
                        
                        TextField("グループコード（例: AB12CD34）", text: $groupCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.allCharacters)
                            .disableAutocorrection(true)
                            .onSubmit {
                                Task {
                                    await searchGroup()
                                }
                            }
                        
                        if isSearching {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    
                    Text("💡 グループコードはグループ作成者から教えてもらえます")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 検索結果
                if let group = foundGroup {
                    VStack(spacing: 16) {
                        Text("グループが見つかりました！")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        GroupRowView(group: group, showRole: false) {
                            // 詳細表示
                        }
                        .padding(.horizontal)
                        
                        Button("グループに参加") {
                            Task {
                                let success = await groupManager.joinGroupByCode(groupCode.uppercased())
                                if success {
                                    dismiss()
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                } else if !searchMessage.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        
                        Text(searchMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("グループに参加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func searchGroup() async {
        guard !groupCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            foundGroup = nil
            searchMessage = ""
            return
        }
        
        isSearching = true
        searchMessage = ""
        
        let group = await groupManager.findGroupByCode(groupCode.uppercased())
        
        await MainActor.run {
            foundGroup = group
            isSearching = false
            
            if group == nil {
                searchMessage = "グループが見つかりませんでした。\nグループコードを確認してください。"
            }
        }
    }
}

// MARK: - Preview

struct CreateGroupView_Previews: PreviewProvider {
    static var previews: some View {
        CreateGroupView()
    }
}

struct JoinGroupView_Previews: PreviewProvider {
    static var previews: some View {
        JoinGroupView()
    }
}