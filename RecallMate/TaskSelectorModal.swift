import SwiftUI

struct TaskSelectorModal: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var taskManager = SimpleTaskManager.shared
    
    let tag: Tag
    let onSelectTask: (SimpleTask) -> Void
    let onStartWithoutTask: () -> Void
    let onCancel: () -> Void
    
    @State private var tasks: [SimpleTask] = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ヘッダー
                VStack(spacing: 12) {
                    HStack {
                        Circle()
                            .fill(tag.swiftUIColor())
                            .frame(width: 16, height: 16)
                        
                        Text(tag.name ?? "無名のタグ")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button("キャンセル") {
                            onCancel()
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Text("タスクを選択してタイマーを開始")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
                
                Divider()
                
                // タスクがない場合
                if tasks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "timer")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.6))
                        
                        VStack(spacing: 8) {
                            Text("タスクがありません")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            Text("タスクなしでタイマーを開始するか\nタスクを作成してください")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(2)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // タスクリスト
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(tasks, id: \.id) { task in
                                TaskSelectorRow(
                                    task: task,
                                    onSelect: { onSelectTask(task) }
                                )
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                }
                
                Spacer()
                
                // 下部ボタン
                VStack(spacing: 12) {
                    // タスクなしで開始ボタン
                    Button(action: onStartWithoutTask) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("タスクなしで開始")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.gray)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            refreshTasks()
        }
    }
    
    private func refreshTasks() {
        guard let tagId = tag.id else { return }
        tasks = taskManager.getTasks(for: tagId, includeCompleted: false)
    }
}

struct TaskSelectorRow: View {
    let task: SimpleTask
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // 優先度インジケーター
                Circle()
                    .fill(task.priority.color)
                    .frame(width: 12, height: 12)
                
                // タスク情報
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    if !task.taskDescription.isEmpty {
                        Text(task.taskDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    HStack(spacing: 12) {
                        // 優先度
                        HStack(spacing: 4) {
                            Image(systemName: task.priority.iconName)
                                .font(.system(size: 12))
                            Text(task.priority.title)
                                .font(.caption)
                        }
                        .foregroundColor(task.priority.color)
                        
                        // 予定時間
                        if task.estimatedMinutes > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 12))
                                Text("\(task.estimatedMinutes)分")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // 開始ボタン
                HStack(spacing: 6) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 12))
                    Text("開始")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(task.priority.color)
                .cornerRadius(16)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}