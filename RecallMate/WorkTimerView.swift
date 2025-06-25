import SwiftUI
import CoreData

struct WorkTimerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var timerManager = WorkTimerManager.shared
    
    // タグ編集用の状態管理
    @State private var showingTagEditor = false
    @State private var showingNewTagCreator = false
    @State private var editingTag: Tag? = nil
    
    // タスク管理用の状態管理
    @State private var taskManagementTag: Tag? = nil
    @State private var selectedTag: Tag? = nil
    @State private var showingTaskSelector = false
    
    // データ更新用のトリガー
    @State private var refreshTrigger = UUID()
    
    // 全タグを取得するFetchRequest - 使用頻度順でソート
    @FetchRequest(
        entity: Tag.entity(),
        sortDescriptors: [], // 動的にソートするため空にしておく
        animation: .default)
    private var allTagsRaw: FetchedResults<Tag>
    
    // 使用頻度順にソートされたタグリスト
    private var sortedTags: [Tag] {
        let tagUsageMap = calculateTagUsageFrequency()
        
        return Array(allTagsRaw).sorted { tag1, tag2 in
            let usage1 = tagUsageMap[tag1.id ?? UUID()] ?? 0
            let usage2 = tagUsageMap[tag2.id ?? UUID()] ?? 0
            
            // 使用頻度が同じ場合は名前順でソート
            if usage1 == usage2 {
                return (tag1.name ?? "") < (tag2.name ?? "")
            }
            return usage1 > usage2
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ヘッダーセクション - 現在のタイマー状態を表示
                if timerManager.isActive {
                    CurrentTimerHeaderView(
                        timerManager: timerManager,
                        onStop: { stopCurrentTimer() },
                        onPause: { pauseCurrentTimer() },
                        onResume: { resumeCurrentTimer() }
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Rectangle()
                            .fill(Color.blue.opacity(0.1))
                            .shadow(
                                color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1),
                                radius: 2,
                                x: 0,
                                y: 1
                            )
                    )
                }
                
                // タイマーリストセクション
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // 新規タグ作成ボタン
                        CreateNewTagButton {
                            showingNewTagCreator = true
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        
                        // タグ別タイマーカード
                        ForEach(sortedTags, id: \.id) { tag in
                            WorkTimerCard(
                                tag: tag,
                                isCurrentlyRunning: timerManager.currentTag?.id == tag.id && timerManager.isRunning,
                                isPaused: timerManager.currentTag?.id == tag.id && timerManager.isPaused,
                                onStartTimer: { startTimer(for: tag) },
                                onStopTimer: { stopCurrentTimer() },
                                onPauseTimer: { pauseCurrentTimer() },
                                onResumeTimer: { resumeCurrentTimer() },
                                onEditTag: { editTag(tag) },
                                onManageTasks: { showTaskManagement(for: tag) }
                            )
                            .padding(.horizontal, 16)
                        }
                        
                        // タグが存在しない場合のメッセージ
                        if sortedTags.isEmpty {
                            EmptyStateMessage()
                                .padding(.horizontal, 16)
                                .padding(.vertical, 40)
                        }
                    }
                    .padding(.bottom, 100) // フローティングボタンとの重複回避
                }
                .refreshable {
                    // Pull-to-refreshでデータを更新
                    refreshData()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
        }
        .onAppear {
            refreshData()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshActivityData"))) { _ in
            refreshData()
        }
        // タグ編集モーダル
        .sheet(item: $editingTag) { tag in
            TagEditModalView(
                tag: tag,
                onSave: { updatedTag in
                    editingTag = nil
                    refreshData()
                },
                onCancel: { editingTag = nil }
            )
        }
        // 新規タグ作成モーダル
        .sheet(isPresented: $showingNewTagCreator) {
            NewTagCreatorView(
                onSave: { newTag in
                    showingNewTagCreator = false
                    refreshData()
                },
                onCancel: { showingNewTagCreator = false }
            )
        }
        // タスク管理モーダル
        .sheet(item: $taskManagementTag) { tag in
            TaskManagementModal(
                tag: tag,
                timerManager: timerManager,
                onSave: {
                    taskManagementTag = nil
                    refreshData()
                }
            )
        }
        // タスク選択モーダル
        .sheet(isPresented: $showingTaskSelector) {
            if let selectedTag = selectedTag {
                TaskSelectorModal(
                    tag: selectedTag,
                    onSelectTask: { task in
                        showingTaskSelector = false
                        timerManager.startTimer(for: selectedTag, task: task)
                        refreshData()
                    },
                    onStartWithoutTask: {
                        showingTaskSelector = false
                        timerManager.startTimer(for: selectedTag)
                        refreshData()
                    },
                    onCancel: {
                        showingTaskSelector = false
                    }
                )
            }
        }
    }
    
    // MARK: - タイマー操作メソッド
    
    /// 指定されたタグでタイマーを開始します
    /// すでに実行中のタイマーがある場合は自動的に停止してから新しいタイマーを開始します
    private func startTimer(for tag: Tag) {
        // 現在実行中のタイマーがあれば停止して保存
        if timerManager.isRunning {
            timerManager.stopTimer(in: viewContext)
        }
        
        // タグに未完了タスクがある場合はタスク選択を表示
        guard let tagId = tag.id else {
            timerManager.startTimer(for: tag)
            return
        }
        
        let pendingTasks = SimpleTaskManager.shared.getTasks(for: tagId, includeCompleted: false)
        if !pendingTasks.isEmpty {
            selectedTag = tag
            showingTaskSelector = true
        } else {
            // タスクがない場合は通常のタイマーを開始
            timerManager.startTimer(for: tag)
        }
    }
    
    /// 現在のタイマーを停止し、作業記録を保存します
    private func stopCurrentTimer() {
        timerManager.stopTimer(in: viewContext)
        refreshData()
    }
    
    /// 現在のタイマーを一時停止します
    private func pauseCurrentTimer() {
        timerManager.pauseTimer()
    }
    
    /// 現在のタイマーを再開します
    private func resumeCurrentTimer() {
        timerManager.resumeTimer()
    }
    
    // MARK: - タグ管理メソッド
    
    /// タグの編集画面を表示します
    private func editTag(_ tag: Tag) {
        editingTag = tag
    }
    
    /// タスク管理画面を表示します
    private func showTaskManagement(for tag: Tag) {
        taskManagementTag = tag
    }
    
    // MARK: - データ管理メソッド
    
    /// データを最新の状態に更新します
    /// 使用頻度の再計算も含まれます
    private func refreshData() {
        viewContext.refreshAllObjects()
        refreshTrigger = UUID()
    }
    
    /// 各タグの作業記録での使用頻度を計算します
    /// 過去30日間のデータを基準にして、最近の使用パターンを反映します
    private func calculateTagUsageFrequency() -> [UUID: Int] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let activities = LearningActivity.fetchWorkTimerActivities(
            from: thirtyDaysAgo,
            to: Date(),
            in: viewContext
        )
        
        var usageCount: [UUID: Int] = [:]
        
        // 各活動からタグを抽出して使用回数をカウント
        for activity in activities {
            if let memo = activity.memo,
               let tags = memo.tags as? Set<Tag> {
                for tag in tags {
                    if let tagId = tag.id {
                        usageCount[tagId, default: 0] += 1
                    }
                }
            }
        }
        
        return usageCount
    }
}

// MARK: - サポートビューコンポーネント

/// 現在実行中のタイマーの状態を表示するヘッダービュー
struct CurrentTimerHeaderView: View {
    @ObservedObject var timerManager: WorkTimerManager
    let onStop: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // タイマー情報
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(timerManager.currentTag?.swiftUIColor() ?? .blue)
                        .frame(width: 12, height: 12)
                    
                    Text(timerManager.currentTag?.name ?? "作業中")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    // 状態インジケーター
                    if timerManager.isPaused {
                        HStack(spacing: 4) {
                            Image(systemName: "pause.circle.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 14))
                            Text("一時停止中")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .fontWeight(.semibold)
                        }
                    } else {
                        Image(systemName: "timer")
                            .foregroundColor(.blue)
                            .font(.system(size: 14))
                    }
                }
                
                // 現在のタスク情報
                if let currentTask = timerManager.currentTask {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.square")
                            .foregroundColor(currentTask.priority.color)
                            .font(.system(size: 12))
                        
                        Text(currentTask.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                    
                    // 経過時間表示
                    Text("経過時間: \(timerManager.formattedElapsedTime)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("経過時間: \(timerManager.formattedElapsedTime)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // コントロールボタン
            HStack(spacing: 8) {
                // 一時停止/再開ボタン
                if timerManager.isPaused {
                    Button(action: onResume) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 14))
                            Text("再開")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .cornerRadius(20)
                    }
                } else {
                    Button(action: onPause) {
                        HStack(spacing: 6) {
                            Image(systemName: "pause.fill")
                                .font(.system(size: 14))
                            Text("一時停止")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.orange)
                        .cornerRadius(20)
                    }
                }
                
                // 停止ボタン
                Button(action: onStop) {
                    HStack(spacing: 6) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 14))
                        Text("停止")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red)
                    .cornerRadius(20)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

/// 個別のタグ用タイマーカード
struct WorkTimerCard: View {
    let tag: Tag
    let isCurrentlyRunning: Bool
    let isPaused: Bool
    let onStartTimer: () -> Void
    let onStopTimer: () -> Void
    let onPauseTimer: () -> Void
    let onResumeTimer: () -> Void
    let onEditTag: () -> Void
    let onManageTasks: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            // タグ情報セクション
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(tag.swiftUIColor())
                        .frame(width: 16, height: 16)
                    
                    Text(tag.name ?? "無名のタグ")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    if isCurrentlyRunning {
                        Image(systemName: "timer")
                            .foregroundColor(.blue)
                            .font(.system(size: 14))
                    } else if isPaused {
                        HStack(spacing: 4) {
                            Image(systemName: "pause.circle.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 14))
                            Text("一時停止")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .fontWeight(.semibold)
                        }
                    }
                }
                
                // 今日の作業時間とタスク数表示
                HStack(spacing: 12) {
                    Text("今日: \(getTodayWorkTime(for: tag))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // タスク数表示
                    let taskCount = getPendingTaskCount(for: tag)
                    let ongoingSessionCount = getOngoingSessionCount(for: tag)
                    
                    if taskCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "checklist")
                                .font(.system(size: 12))
                            Text("\(taskCount)個のタスク")
                                .font(.caption)
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(4)
                    }
                    
                    // 継続中セッション表示
                    if ongoingSessionCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.badge.exclamationmark")
                                .font(.system(size: 12))
                            Text("\(ongoingSessionCount)継続中")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
            
            // アクションボタンセクション
            HStack(spacing: 12) {
                // タスク管理ボタン
                Button(action: onManageTasks) {
                    Image(systemName: "checklist")
                        .font(.system(size: 16))
                        .foregroundColor(.purple)
                        .frame(width: 36, height: 36)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(18)
                }
                
                // 編集ボタン
                Button(action: onEditTag) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                        .frame(width: 36, height: 36)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(18)
                }
                
                // タイマーコントロールボタン
                HStack(spacing: 8) {
                    if isCurrentlyRunning || isPaused {
                        // 一時停止/再開ボタン
                        Button(action: {
                            if isCurrentlyRunning {
                                onPauseTimer()
                            } else if isPaused {
                                onResumeTimer()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                                    .font(.system(size: 12))
                                Text(isPaused ? "再開" : "一時停止")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isPaused ? Color.green : Color.orange)
                            .cornerRadius(16)
                        }
                        
                        // 停止ボタン
                        Button(action: onStopTimer) {
                            HStack(spacing: 4) {
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 12))
                                Text("停止")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red)
                            .cornerRadius(16)
                        }
                    } else {
                        // 開始ボタン
                        Button(action: onStartTimer) {
                            HStack(spacing: 6) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 14))
                                Text("開始")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(tag.swiftUIColor())
                            .cornerRadius(20)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(
                    color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1),
                    radius: colorScheme == .dark ? 3 : 2,
                    x: 0,
                    y: colorScheme == .dark ? 2 : 1
                )
        )
    }
    
    /// 指定されたタグの今日の作業時間を計算します
    private func getTodayWorkTime(for tag: Tag) -> String {
        guard let tagId = tag.id else { return "0:00" }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-1)
        
        let activities = LearningActivity.fetchWorkTimerActivities(
            from: startOfDay,
            to: endOfDay,
            tagId: tagId,
            in: PersistenceController.shared.container.viewContext
        )
        
        let totalSeconds = activities.reduce(0) { $0 + Int($1.durationInSeconds) }
        
        return WorkTimerManager.shared.formatDuration(totalSeconds)
    }
    
    /// 指定されたタグの未完了タスク数を取得します
    private func getPendingTaskCount(for tag: Tag) -> Int {
        guard let tagId = tag.id else { return 0 }
        return SimpleTaskManager.shared.getTasks(for: tagId, includeCompleted: false).count
    }
    
    /// 指定されたタグの継続中セッション数を取得します
    private func getOngoingSessionCount(for tag: Tag) -> Int {
        guard let tagId = tag.id else { return 0 }
        let tasks = SimpleTaskManager.shared.getTasks(for: tagId, includeCompleted: false)
        return tasks.filter { $0.currentSessionSeconds > 0 }.count
    }
}

/// 新規タグ作成ボタン
struct CreateNewTagButton: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("新しい作業を追加")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("数学、英語、プログラミングなど")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.green.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// タグが存在しない場合のメッセージ
struct EmptyStateMessage: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "timer")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("作業記録を始めましょう")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("「新しい作業を追加」から\n作業内容を登録して時間管理を始めることができます")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
