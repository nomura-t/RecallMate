import SwiftUI

struct GroupChatView: View {
    let group: StudyGroup
    @Environment(\.dismiss) private var dismiss
    @StateObject private var chatManager = GroupChatManager.shared
    @StateObject private var groupManager = StudyGroupManager.shared
    @State private var messageText = ""
    @State private var showGroupDetail = false
    @State private var isTyping = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // メッセージリスト
                messagesList
                
                // タイピングインジケーター
                typingIndicator
                
                // メッセージ入力
                messageInput
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
                    Button {
                        showGroupDetail = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
            .sheet(isPresented: $showGroupDetail) {
                GroupDetailView(group: group)
            }
            .onAppear {
                Task {
                    await chatManager.joinGroupChat(group.id)
                    await chatManager.markMessagesAsRead(groupId: group.id)
                }
            }
            .onDisappear {
                Task {
                    await chatManager.leaveGroupChat(group.id)
                }
            }
        }
    }
    
    // MARK: - Messages List
    
    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(chatManager.getMessages(groupId: group.id), id: \.id) { message in
                        MessageBubbleView(
                            message: message,
                            isFromCurrentUser: message.isFromCurrentUser,
                            onEdit: { newText in
                                Task {
                                    await chatManager.editMessage(messageId: message.id, newContent: newText)
                                }
                            },
                            onDelete: {
                                Task {
                                    await chatManager.deleteMessage(messageId: message.id)
                                }
                            }
                        )
                        .id(message.id)
                    }
                }
                .padding()
            }
            .refreshable {
                await chatManager.loadMessages(groupId: group.id)
            }
            .onChange(of: chatManager.getMessages(groupId: group.id).count) {
                // 新しいメッセージが追加されたら下にスクロール
                if let lastMessage = chatManager.getMessages(groupId: group.id).last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    
    // MARK: - Typing Indicator
    
    private var typingIndicator: some View {
        Group {
            if !chatManager.getTypingUsers(groupId: group.id).isEmpty {
                HStack {
                    Text("入力中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
        }
    }
    
    // MARK: - Message Input
    
    private var messageInput: some View {
        HStack {
            TextField("メッセージを入力", text: $messageText, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(1...4)
                .onChange(of: messageText) { oldValue, newValue in
                    handleTyping(oldValue: oldValue, newValue: newValue)
                }
                .onSubmit {
                    sendMessage()
                }
            
            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : .blue)
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: -1)
    }
    
    // MARK: - Functions
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        Task {
            let success = await chatManager.sendMessage(
                groupId: group.id,
                content: messageText.trimmingCharacters(in: .whitespacesAndNewlines),
                replyToId: nil
            )
            
            if success {
                await MainActor.run {
                    messageText = ""
                }
            }
        }
    }
    
    private func handleTyping(oldValue: String, newValue: String) {
        let isNowTyping = !newValue.isEmpty
        
        if isTyping != isNowTyping {
            isTyping = isNowTyping
            
            Task {
                await chatManager.sendTypingIndicator(groupId: group.id, isTyping: isTyping)
            }
        }
    }
}

// MARK: - Message Bubble View

struct MessageBubbleView: View {
    let message: GroupMessage
    let isFromCurrentUser: Bool
    let onEdit: (String) -> Void
    let onDelete: () -> Void
    
    @State private var showActions = false
    @State private var showEditSheet = false
    @State private var editText = ""
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer()
                messageBubble
                    .contextMenu {
                        contextMenuItems
                    }
            } else {
                messageBubble
                    .contextMenu {
                        contextMenuItems
                    }
                Spacer()
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditMessageView(
                originalText: message.content,
                onSave: { newText in
                    onEdit(newText)
                }
            )
        }
    }
    
    private var messageBubble: some View {
        VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
            // 送信者名（自分のメッセージでない場合のみ）
            if !isFromCurrentUser {
                Text(message.sender?.displayName ?? "Unknown")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            
            // メッセージ内容
            Text(message.content)
                .font(.body)
                .foregroundColor(isFromCurrentUser ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    isFromCurrentUser ? Color.blue : Color.gray.opacity(0.2)
                )
                .cornerRadius(16)
            
            // 時刻と既読状態
            HStack {
                if isFromCurrentUser {
                    // 既読状態
                    if message.isRead == true {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
                
                Text(message.formattedTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: isFromCurrentUser ? .trailing : .leading)
    }
    
    
    private var contextMenuItems: some View {
        Group {
            if isFromCurrentUser {
                Button("編集") {
                    editText = message.content
                    showEditSheet = true
                }
                
                Button("削除", role: .destructive) {
                    onDelete()
                }
            }
        }
    }
}

// MARK: - Edit Message View

struct EditMessageView: View {
    let originalText: String
    let onSave: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var editText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("メッセージを編集", text: $editText, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(1...10)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("メッセージを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        onSave(editText)
                        dismiss()
                    }
                    .disabled(editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            editText = originalText
        }
    }
}

// MARK: - Group Chat List View

struct GroupChatListView: View {
    @StateObject private var groupManager = StudyGroupManager.shared
    @StateObject private var chatManager = GroupChatManager.shared
    @State private var selectedGroup: StudyGroup?
    
    var body: some View {
        NavigationView {
            List(groupManager.myGroups, id: \.id) { group in
                ChatRoomRowView(group: group, unreadCount: chatManager.getUnreadCount(groupId: group.id)) {
                    selectedGroup = group
                }
            }
            .navigationTitle("チャット")
            .refreshable {
                await groupManager.loadMyGroups()
            }
            .onAppear {
                Task {
                    await groupManager.loadMyGroups()
                }
            }
            .sheet(item: $selectedGroup) { group in
                GroupChatView(group: group)
            }
        }
    }
}

// MARK: - Chat Room Row View

struct ChatRoomRowView: View {
    let group: StudyGroup
    let unreadCount: Int
    let onTap: () -> Void
    
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
                    )
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text("最新メッセージのプレビュー")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("10:30")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if unreadCount > 0 {
                    Text("\(unreadCount)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .cornerRadius(12)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Preview

struct GroupChatView_Previews: PreviewProvider {
    static var previews: some View {
        GroupChatView(group: StudyGroup(
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
            studyGoals: ["TOEIC 800点"],
            studySchedule: nil,
            createdAt: Date(),
            updatedAt: Date()
        ))
    }
}

struct GroupChatListView_Previews: PreviewProvider {
    static var previews: some View {
        GroupChatListView()
    }
}