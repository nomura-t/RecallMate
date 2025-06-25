import SwiftUI
import CoreData

// 秒数を時:分:秒または分:秒の形式でフォーマット
func formatTimeFromSeconds(_ seconds: Int) -> String {
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    let remainingSeconds = seconds % 60
    
    if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
    } else if minutes > 0 {
        return String(format: "%d:%02d", minutes, remainingSeconds)
    } else {
        let secondUnit = "秒".localized
        return "\(remainingSeconds)" + secondUnit
    }
}

// タイマー状態を独立して管理するための構造体
struct TimerState {
    let currentTask: SimpleTask?
    let isRunning: Bool
    let isPaused: Bool
    
    static func from(_ timerManager: WorkTimerManager) -> TimerState {
        return TimerState(
            currentTask: timerManager.currentTask,
            isRunning: timerManager.isRunning,
            isPaused: timerManager.isPaused
        )
    }
}

struct TaskManagementModal: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var taskManager = SimpleTaskManager.shared
    
    // タイマー状態は初期化時に取得し、手動で更新
    let initialTimerState: TimerState
    
    let tag: Tag
    let onSave: () -> Void
    
    @State private var showingAddTask = false
    @State private var editingTask: SimpleTask?
    @State private var tasks: [SimpleTask] = []
    @State private var isLoading = true
    
    // タイマー状態の独立した管理
    @State private var currentTimerTask: SimpleTask? = nil
    @State private var isTimerRunning: Bool = false
    @State private var isTimerPaused: Bool = false
    
    // 定期更新用のタイマー
    @State private var refreshTimer: Timer?
    
    // レスポンシブデザイン用の計算プロパティ
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    
    private var adaptivePadding: CGFloat {
        isCompact ? 16 : 32
    }
    
    private var contentMaxWidth: CGFloat {
        isCompact ? .infinity : 700
    }
    
    private var buttonHeight: CGFloat {
        isCompact ? 32 : 44
    }
    
    private var smallButtonSize: CGFloat {
        isCompact ? 28 : 36
    }
    
    init(tag: Tag, timerManager: WorkTimerManager, onSave: @escaping () -> Void) {
        self.tag = tag
        self.initialTimerState = TimerState.from(timerManager)
        self.onSave = onSave
        
        // 初期化時は空のタスクリストとローディング状態をfalseに設定
        self._tasks = State(initialValue: [])
        self._isLoading = State(initialValue: false)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ヘッダー
                VStack(spacing: isCompact ? 12 : 16) {
                    HStack {
                        Circle()
                            .fill(tag.swiftUIColor())
                            .frame(width: 16, height: 16)
                        
                        Text(tag.name ?? "無名のタグ".localized)
                            .font(isCompact ? .headline : .title2)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button("完了".localized) {
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                    
                    // 統計情報
                    let stats = taskManager.getTaskStatistics(for: tag.id ?? UUID())
                    let completedCount = stats.completed
                    let totalCount = stats.total
                    
                    HStack(spacing: isCompact ? 16 : 32) {
                        VStack(spacing: 4) {
                            Text("\(totalCount)")
                                .font(isCompact ? .title2 : .title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            Text("総タスク数".localized)
                                .font(isCompact ? .caption : .footnote)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 4) {
                            Text("\(completedCount)")
                                .font(isCompact ? .title2 : .title)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text("完了済み".localized)
                                .font(isCompact ? .caption : .footnote)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 4) {
                            Text("\(totalCount - completedCount)")
                                .font(isCompact ? .title2 : .title)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                            Text("未完了".localized)
                                .font(isCompact ? .caption : .footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal, adaptivePadding)
                .padding(.vertical, isCompact ? 16 : 24)
                .background(Color(.systemBackground))
                
                Divider()
                
                // タスクリスト
                if tasks.isEmpty {
                    // 空の状態
                    VStack(spacing: isCompact ? 24 : 32) {
                        Image(systemName: "checklist")
                            .font(.system(size: isCompact ? 50 : 70))
                            .foregroundColor(.gray.opacity(0.6))
                        
                        VStack(spacing: isCompact ? 12 : 16) {
                            Text("タスクを追加して始めましょう".localized)
                                .font(isCompact ? .title2 : .title)
                                .fontWeight(.semibold)
                            
                            Text("作業を細かく分けて効率的に進めることができます".localized)
                                .font(isCompact ? .subheadline : .headline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: isCompact ? 8 : 12) {
                            // 実行中・一時停止中のタスクを最初に表示
                            ForEach(activeTasks, id: \.id) { task in
                                SimpleTaskRowView(
                                    task: task,
                                    tag: tag,
                                    onToggleComplete: { toggleTaskCompletion(task) },
                                    onEdit: { editingTask = task },
                                    onStartTask: { startTaskTimer(task) }
                                )
                            }
                            
                            // 区切り線（アクティブタスクがある場合のみ）
                            if !activeTasks.isEmpty && !inactiveTasks.isEmpty {
                                Divider()
                                    .padding(.vertical, 8)
                            }
                            
                            // その他のタスク
                            ForEach(inactiveTasks, id: \.id) { task in
                                SimpleTaskRowView(
                                    task: task,
                                    tag: tag,
                                    onToggleComplete: { toggleTaskCompletion(task) },
                                    onEdit: { editingTask = task },
                                    onStartTask: { startTaskTimer(task) }
                                )
                            }
                        }
                        .padding(.horizontal, adaptivePadding)
                        .padding(.bottom, isCompact ? 100 : 120)
                    }
                }
                
                Spacer()
                
                // 新しいタスクを追加ボタン
                VStack(spacing: 0) {
                    Divider()
                    
                    Button(action: { showingAddTask = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                            Text("新しいタスクを追加".localized)
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(tag.swiftUIColor())
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, adaptivePadding)
                    .padding(.vertical, isCompact ? 16 : 20)
                    .background(Color(.systemBackground))
                }
            }
            .navigationBarHidden(true)
            .frame(maxWidth: contentMaxWidth)
        }
        .onAppear {
            // 最初にタスクを読み込み
            refreshTasks()
            startPeriodicRefresh()
        }
        .onDisappear {
            stopPeriodicRefresh()
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskModal(
                tag: tag,
                onSave: { title, description, priority, estimatedMinutes in
                    addNewTask(title: title, description: description, priority: priority, estimatedMinutes: estimatedMinutes)
                    showingAddTask = false
                },
                onCancel: { showingAddTask = false }
            )
        }
        .sheet(item: $editingTask) { task in
            EditTaskModal(
                task: task,
                onSave: { updatedTask in
                    taskManager.updateTask(updatedTask)
                    refreshTasks()
                    editingTask = nil
                },
                onCancel: { editingTask = nil }
            )
        }
    }
    
    
    // アクティブなタスク（実行中、一時停止中、継続中のセッションがあるタスク）
    private var activeTasks: [SimpleTask] {
        guard !isLoading else { return [] }
        
        return tasks.filter { task in
            !task.isCompleted && task.currentSessionSeconds > 0
        }.sorted { task1, task2 in
            return task1.priority.rawValue > task2.priority.rawValue
        }
    }
    
    // 非アクティブなタスク
    private var inactiveTasks: [SimpleTask] {
        guard !isLoading else { return [] }
        
        let activeTaskIds = activeTasks.map { $0.id }
        return tasks.filter { task in
            !activeTaskIds.contains(task.id)
        }.sorted { task1, task2 in
            // 完了状態順（未完了→完了）
            if task1.isCompleted != task2.isCompleted {
                return !task1.isCompleted
            }
            // 優先度順（高→低）
            if task1.priority != task2.priority {
                return task1.priority.rawValue > task2.priority.rawValue
            }
            // 作成日順（新→古）
            return task1.createdAt > task2.createdAt
        }
    }
    
    // タスクリストを更新
    private func refreshTasks() {
        guard let tagId = tag.id else { 
            DispatchQueue.main.async {
                self.tasks = []
                self.isLoading = false
            }
            return 
        }
        
        let newTasks = taskManager.getTasks(for: tagId, includeCompleted: true)
        
        DispatchQueue.main.async {
            self.tasks = newTasks
            self.isLoading = false
        }
    }
    
    // タスクの完了状態を切り替え
    private func toggleTaskCompletion(_ task: SimpleTask) {
        withAnimation(.easeInOut(duration: 0.3)) {
            taskManager.toggleTaskCompletion(task)
            refreshTasks()
        }
    }
    
    // 新しいタスクを追加
    private func addNewTask(title: String, description: String, priority: TaskPriority, estimatedMinutes: Int) {
        guard let tagId = tag.id else { return }
        taskManager.addTask(
            title: title,
            description: description,
            priority: priority,
            estimatedMinutes: estimatedMinutes,
            for: tagId
        )
        refreshTasks()
        onSave()
    }
    
    // タスクを削除
    private func deleteTasks(offsets: IndexSet) {
        withAnimation {
            let tasksToDelete = offsets.map { tasks[$0] }
            for task in tasksToDelete {
                taskManager.deleteTask(task)
            }
            refreshTasks()
            onSave()
        }
    }
    
    // タスクのタイマーを開始
    private func startTaskTimer(_ task: SimpleTask) {
        WorkTimerManager.shared.startTimer(for: tag, task: task)
    }
    
    // 定期更新を開始
    private func startPeriodicRefresh() {
        // 既存のタイマーを停止
        stopPeriodicRefresh()
        
        // 2秒間隔でタスクデータを更新
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            refreshTasksQuietly()
        }
    }
    
    // 定期更新を停止
    private func stopPeriodicRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    // ログ出力なしでタスクリストを更新
    private func refreshTasksQuietly() {
        guard let tagId = tag.id else { return }
        
        let newTasks = taskManager.getTasks(for: tagId, includeCompleted: true)
        
        // タスクデータが実際に変更された場合のみ更新
        if !tasksAreEqual(tasks, newTasks) {
            tasks = newTasks
        }
    }
    
    // タスク配列の比較（currentSessionSecondsの変更を検知）
    private func tasksAreEqual(_ tasks1: [SimpleTask], _ tasks2: [SimpleTask]) -> Bool {
        guard tasks1.count == tasks2.count else { return false }
        
        for i in 0..<tasks1.count {
            let task1 = tasks1[i]
            let task2 = tasks2[i]
            
            if task1.id != task2.id ||
               task1.currentSessionSeconds != task2.currentSessionSeconds ||
               task1.isCompleted != task2.isCompleted ||
               task1.actualMinutes != task2.actualMinutes {
                return false
            }
        }
        
        return true
    }
}

// 簡素化されたタスク行ビュー（タイマー状態表示あり）
struct SimpleTaskRowView: View {
    let task: SimpleTask
    let tag: Tag
    let onToggleComplete: () -> Void
    let onEdit: () -> Void
    let onStartTask: () -> Void
    
    // タイマーマネージャーを監視
    @ObservedObject private var timerManager = WorkTimerManager.shared
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    
    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: isCompact ? 12 : 16) {
                // 完了チェックボックス
                Button(action: onToggleComplete) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: isCompact ? 22 : 26))
                        .foregroundColor(task.isCompleted ? .green : .gray)
                }
                .buttonStyle(.plain)
                
                // タスク情報
                VStack(alignment: .leading, spacing: 8) {
                    // タイトル行
                    HStack(spacing: 8) {
                        Text(task.title)
                            .font(isCompact ? .headline : .title3)
                            .strikethrough(task.isCompleted)
                            .foregroundColor(task.isCompleted ? .secondary : .primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // タイマー状態の表示
                        if isCurrentlyActiveTask {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(currentTimerColor)
                                    .frame(width: 8, height: 8)
                                Text(currentTimerStatusText)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(currentTimerColor)
                            }
                        } else if task.currentSessionSeconds > 0 {
                            // セッション継続中（タイマー停止中）の表示
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width: 8, height: 8)
                                Text("セッション継続中".localized)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    // 時間進捗の表示
                    HStack(spacing: 8) {
                        let actualTime = formatTimeFromSeconds(task.totalSecondsIncludingSession)
                        let estimatedTime = task.estimatedMinutes > 0 ? "\(task.estimatedMinutes)" + "分".localized : actualTime
                        let timeText = "\(actualTime)/\(estimatedTime)"
                        
                        Text(timeText)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        if isCurrentlyActiveTask {
                            Text("(\(currentTimerTimeText))")
                                .font(.caption)
                                .foregroundColor(currentTimerColor)
                        }
                        
                        Spacer()
                    }
                    
                    // 進捗バー
                    if task.estimatedMinutes > 0 {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // 背景バー（灰色）
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 6)
                                    .cornerRadius(3)
                                
                                // 進捗バー（色付き）
                                Rectangle()
                                    .fill(progressBarColor)
                                    .frame(width: geometry.size.width * CGFloat(min(progressRatio, 1.0)), height: 6)
                                    .cornerRadius(3)
                                    .animation(.easeInOut(duration: 0.3), value: progressRatio)
                            }
                        }
                        .frame(height: 6)
                    }
                    
                    // 説明文と優先度（コンパクトに）
                    HStack(spacing: 12) {
                        // 優先度
                        HStack(spacing: 4) {
                            Image(systemName: task.priority.iconName)
                                .font(.system(size: 10))
                            Text(task.priority.title)
                                .font(.caption)
                        }
                        .foregroundColor(task.priority.color)
                        
                        // 説明文（短縮）
                        if !task.taskDescription.isEmpty {
                            Text(task.taskDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                    }
                }
                
                // タイマーコントロールボタン
                if !task.isCompleted {
                    if isCurrentlyActiveTask {
                        // 実行中または一時停止中のタスクの場合
                        HStack(spacing: 8) {
                            // 一時停止/再開ボタン
                            Button(action: {
                                if timerManager.isRunning {
                                    timerManager.pauseTimer()
                                } else if timerManager.isPaused {
                                    timerManager.resumeTimer()
                                }
                            }) {
                                let buttonSize: CGFloat = isCompact ? 28 : 36
                                Image(systemName: timerManager.isPaused ? "play.fill" : "pause.fill")
                                    .font(.system(size: isCompact ? 10 : 12))
                                    .foregroundColor(.white)
                                    .frame(width: buttonSize, height: buttonSize)
                                    .background(timerManager.isPaused ? Color.green : Color.orange)
                                    .cornerRadius(buttonSize / 2)
                            }
                            .buttonStyle(.plain)
                            
                            // 停止ボタン
                            Button(action: {
                                timerManager.stopTimer(in: viewContext)
                            }) {
                                let buttonSize: CGFloat = isCompact ? 28 : 36
                                Image(systemName: "stop.fill")
                                    .font(.system(size: isCompact ? 10 : 12))
                                    .foregroundColor(.white)
                                    .frame(width: buttonSize, height: buttonSize)
                                    .background(Color.red)
                                    .cornerRadius(buttonSize / 2)
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        // 停止中のタスクの場合
                        Button(action: {
                            timerManager.startTimer(for: tag, task: task)
                        }) {
                            let buttonSize: CGFloat = isCompact ? 32 : 40
                            Image(systemName: "play.fill")
                                .font(.system(size: isCompact ? 12 : 14))
                                .foregroundColor(.white)
                                .frame(width: buttonSize, height: buttonSize)
                                .background(task.priority.color)
                                .cornerRadius(buttonSize / 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    // 現在アクティブなタスクかどうか
    private var isCurrentlyActiveTask: Bool {
        guard let currentTask = timerManager.currentTask else { return false }
        return currentTask.id == task.id && (timerManager.isRunning || timerManager.isPaused)
    }
    
    // タイマー状態に応じた色
    private var currentTimerColor: Color {
        if timerManager.isRunning {
            return .green
        } else if timerManager.isPaused {
            return .orange
        } else {
            return .gray
        }
    }
    
    // タイマー状態のテキスト
    private var currentTimerStatusText: String {
        if timerManager.isRunning {
            return "実行中".localized
        } else if timerManager.isPaused {
            return "一時停止中".localized
        } else {
            return "停止中".localized
        }
    }
    
    // タイマー時間のテキスト
    private var currentTimerTimeText: String {
        if timerManager.isRunning || timerManager.isPaused {
            let totalTime = timerManager.accumulatedTime + timerManager.elapsedTime
            let minutes = Int(totalTime) / 60
            let seconds = Int(totalTime) % 60
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            let sessionMinutes = Int(ceil(Double(task.currentSessionSeconds) / 60.0))
            return "\(sessionMinutes)分"
        }
    }
    
    // 進捗率の計算
    private var progressRatio: Double {
        guard task.estimatedMinutes > 0 else { return 0.0 }
        return Double(task.totalSecondsIncludingSession) / Double(task.estimatedMinutes * 60)
    }
    
    // 進捗バーの色
    private var progressBarColor: Color {
        let ratio = progressRatio
        if ratio >= 1.0 {
            // 完了または超過
            return ratio > 1.0 ? Color.red : Color.green
        } else if ratio >= 0.8 {
            // 80%以上
            return Color.orange
        } else {
            // 80%未満
            return task.priority.color
        }
    }
}

// 新しいタスク追加モーダル
struct AddTaskModal: View {
    @State private var title = ""
    @State private var description = ""
    @State private var priority = TaskPriority.medium
    @State private var estimatedMinutes = 30
    
    let tag: Tag
    let onSave: (String, String, TaskPriority, Int) -> Void
    let onCancel: () -> Void
    
    // 時間選択用の配列（5分刻みで15分～180分）
    private let timeOptions: [Int] = Array(stride(from: 15, through: 180, by: 15))
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // ヘッダー
                VStack(spacing: 8) {
                    Text("新しいタスクを追加".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("タスクを細かく分けて効率的に作業しましょう".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                VStack(spacing: 24) {
                    // タスク名
                    VStack(alignment: .leading, spacing: 8) {
                        Text("タスク名".localized)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextField("例: 数学の宿題、レポート作成".localized, text: $title)
                            .textFieldStyle(.roundedBorder)
                            .font(.body)
                    }
                    
                    // 説明（オプション）
                    VStack(alignment: .leading, spacing: 8) {
                        Text("説明（任意）".localized)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextField("詳細や注意点があれば入力".localized, text: $description, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(2...4)
                    }
                    
                    // 優先度
                    VStack(alignment: .leading, spacing: 12) {
                        Text("優先度".localized)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 12) {
                            ForEach(TaskPriority.allCases, id: \.self) { taskPriority in
                                Button(action: {
                                    priority = taskPriority
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: taskPriority.iconName)
                                            .font(.system(size: 16))
                                        Text(taskPriority.title)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(priority == taskPriority ? .white : taskPriority.color)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(priority == taskPriority ? taskPriority.color : taskPriority.color.opacity(0.1))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(taskPriority.color, lineWidth: priority == taskPriority ? 0 : 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // 予定時間
                    VStack(alignment: .leading, spacing: 12) {
                        Text("予定時間".localized)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 8) {
                            let timeText = "\(estimatedMinutes)" + "分".localized
                            Text(timeText)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(priority.color)
                            
                            Picker("予定時間".localized, selection: $estimatedMinutes) {
                                ForEach(timeOptions, id: \.self) { minutes in
                                    let minuteText = "\(minutes)" + "分".localized
                                    Text(minuteText)
                                        .tag(minutes)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 120)
                            .clipped()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // ボタン
                VStack(spacing: 12) {
                    Button(action: {
                        onSave(title, description, priority, estimatedMinutes)
                    }) {
                        Text("タスクを追加".localized)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(title.isEmpty ? Color.gray : priority.color)
                            .cornerRadius(12)
                    }
                    .disabled(title.isEmpty)
                    
                    Button("キャンセル".localized, action: onCancel)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

// タスク編集モーダル
struct EditTaskModal: View {
    @State private var title: String
    @State private var description: String
    @State private var priority: TaskPriority
    @State private var estimatedMinutes: Int
    
    let task: SimpleTask
    let onSave: (SimpleTask) -> Void
    let onCancel: () -> Void
    
    init(task: SimpleTask, onSave: @escaping (SimpleTask) -> Void, onCancel: @escaping () -> Void) {
        self.task = task
        self.onSave = onSave
        self.onCancel = onCancel
        
        self._title = State(initialValue: task.title)
        self._description = State(initialValue: task.taskDescription)
        self._priority = State(initialValue: task.priority)
        self._estimatedMinutes = State(initialValue: task.estimatedMinutes)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                taskInfoSection
                taskSettingsSection
                workTimeSection
                if task.isCompleted {
                    completionSection
                }
            }
            .navigationTitle("タスクを編集".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル".localized, action: onCancel)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存".localized) {
                        var updatedTask = task
                        updatedTask.title = title
                        updatedTask.taskDescription = description
                        updatedTask.priority = priority
                        updatedTask.estimatedMinutes = estimatedMinutes
                        onSave(updatedTask)
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    // MARK: - View Sections
    
    private var taskInfoSection: some View {
        Section("タスク情報".localized) {
            TextField("タスク名".localized, text: $title)
            TextField("説明（任意）".localized, text: $description, axis: .vertical)
                .lineLimit(3...6)
        }
    }
    
    private var taskSettingsSection: some View {
        Section("設定".localized) {
            Picker("優先度".localized, selection: $priority) {
                ForEach(TaskPriority.allCases) { priority in
                    HStack {
                        Image(systemName: priority.iconName)
                            .foregroundColor(priority.color)
                        Text(priority.title)
                    }
                    .tag(priority)
                }
            }
            
            HStack {
                Text("予定時間".localized)
                Spacer()
                TextField("分".localized, value: $estimatedMinutes, format: .number)
                    .keyboardType(.numberPad)
                    .frame(width: 60)
                    .textFieldStyle(.roundedBorder)
                Text("分".localized)
            }
        }
    }
    
    private var workTimeSection: some View {
        Section("作業時間記録".localized) {
            HStack {
                Text("完了した作業時間".localized)
                Spacer()
                Text(formatTimeFromSeconds(task.actualSeconds))
                    .foregroundColor(task.actualSeconds > task.estimatedMinutes * 60 ? .red : .green)
                    .fontWeight(.semibold)
            }
            
            if task.currentSessionSeconds > 0 {
                HStack {
                    Text("進行中のセッション".localized)
                    Spacer()
                    Text(formatTimeFromSeconds(task.currentSessionSeconds))
                        .foregroundColor(.orange)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("合計作業時間".localized)
                    Spacer()
                    Text(formatTimeFromSeconds(task.totalSecondsIncludingSession))
                        .foregroundColor(task.totalSecondsIncludingSession > task.estimatedMinutes * 60 ? .red : .blue)
                        .fontWeight(.bold)
                }
            }
            
            if task.estimatedMinutes > 0 {
                progressView
            }
        }
    }
    
    private var progressView: some View {
        let progress = min(Double(task.totalSecondsIncludingSession) / Double(task.estimatedMinutes * 60), 2.0)
        
        return VStack(alignment: .leading, spacing: 4) {
            let progressText = "進捗".localized + ": \(Int(progress * 100))%"
            Text(progressText)
                .font(.caption)
                .foregroundColor(.secondary)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(progress > 1.0 ? Color.red : priority.color)
                        .frame(width: geometry.size.width * CGFloat(min(progress, 1.0)), height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
    }
    
    private var completionSection: some View {
        Section("完了情報".localized) {
            if let completedAt = task.completedAt {
                HStack {
                    Text("完了日時".localized + ":")
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(completedAt, style: .date)
                        Text(completedAt, style: .time)
                    }
                }
                .foregroundColor(.secondary)
            }
        }
    }
}