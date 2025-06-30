import Foundation
import SwiftUI

// タスクの優先度
enum TaskPriority: Int, CaseIterable, Identifiable, Codable {
    case low = 0
    case medium = 1
    case high = 2
    
    var id: Int { self.rawValue }
    
    var title: String {
        switch self {
        case .low: return "低".localized
        case .medium: return "中".localized
        case .high: return "高".localized
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .gray
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    var iconName: String {
        switch self {
        case .low: return "arrow.down"
        case .medium: return "minus"
        case .high: return "arrow.up"
        }
    }
}

// シンプルなタスク構造体
struct SimpleTask: Identifiable, Codable {
    let id: UUID
    var title: String
    var taskDescription: String
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    var completedAt: Date?
    var priority: TaskPriority = .medium
    var estimatedMinutes: Int = 30
    var actualSeconds: Int = 0  // 総実作業時間（秒）
    var currentSessionSeconds: Int = 0  // 現在のセッションで蓄積された時間（秒）
    var tagId: UUID
    
    init(title: String, taskDescription: String, priority: TaskPriority, estimatedMinutes: Int, tagId: UUID) {
        self.id = UUID()
        self.title = title
        self.taskDescription = taskDescription
        self.priority = priority
        self.estimatedMinutes = estimatedMinutes
        self.tagId = tagId
    }
    
    mutating func markCompleted() {
        isCompleted = true
        completedAt = Date()
    }
    
    mutating func markIncomplete() {
        isCompleted = false
        completedAt = nil
    }
    
    var progressPercentage: Double {
        guard estimatedMinutes > 0 else { return 0.0 }
        return min(Double(totalSecondsIncludingSession) / Double(estimatedMinutes * 60), 1.0) * 100
    }
    
    // 現在のセッション時間を実作業時間に反映して、セッション時間をリセット
    mutating func finalizeCurrentSession() {
        if currentSessionSeconds > 0 {
            actualSeconds += currentSessionSeconds
            currentSessionSeconds = 0
        }
    }
    
    // セッション時間を更新（タイマー停止時）
    mutating func updateSessionTime(seconds: Int) {
        currentSessionSeconds = seconds
    }
    
    // 総経過時間（実作業時間 + 現在のセッション時間）を秒で取得
    var totalSecondsIncludingSession: Int {
        return actualSeconds + currentSessionSeconds
    }
    
    // 総経過時間を分で取得（表示用）
    var totalMinutesIncludingSession: Int {
        return Int(ceil(Double(totalSecondsIncludingSession) / 60.0))
    }
    
    // 実作業時間を分で取得（表示用）
    var actualMinutes: Int {
        return Int(ceil(Double(actualSeconds) / 60.0))
    }
}

// タスク管理クラス
class SimpleTaskManager: ObservableObject {
    static let shared = SimpleTaskManager()
    
    @Published var tasks: [SimpleTask] = []
    
    private let userDefaults = UserDefaults.standard
    private let tasksKey = "RecallMate_WorkTasks"
    
    init() {
        loadTasks()
    }
    
    // タスクを読み込み
    private func loadTasks() {
        if let data = userDefaults.data(forKey: tasksKey),
           let decodedTasks = try? JSONDecoder().decode([SimpleTask].self, from: data) {
            self.tasks = decodedTasks
        }
    }
    
    // タスクを保存
    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            userDefaults.set(encoded, forKey: tasksKey)
        }
    }
    
    // 指定されたタグのタスクを取得
    func getTasks(for tagId: UUID, includeCompleted: Bool = false) -> [SimpleTask] {
        let filteredTasks = tasks.filter { task in
            task.tagId == tagId && (includeCompleted || !task.isCompleted)
        }
        
        return filteredTasks.sorted { task1, task2 in
            // 優先度順（高→低）
            if task1.priority != task2.priority {
                return task1.priority.rawValue > task2.priority.rawValue
            }
            // 完了状態順（未完了→完了）
            if task1.isCompleted != task2.isCompleted {
                return !task1.isCompleted
            }
            // 作成日順（新→古）
            return task1.createdAt > task2.createdAt
        }
    }
    
    // 新しいタスクを追加
    func addTask(
        title: String,
        description: String = "",
        priority: TaskPriority = .medium,
        estimatedMinutes: Int = 30,
        for tagId: UUID
    ) {
        let newTask = SimpleTask(
            title: title,
            taskDescription: description,
            priority: priority,
            estimatedMinutes: estimatedMinutes,
            tagId: tagId
        )
        
        tasks.append(newTask)
        saveTasks()
    }
    
    // タスクを更新
    func updateTask(_ task: SimpleTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            saveTasks()
        }
    }
    
    // タスクを削除
    func deleteTask(_ task: SimpleTask) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }
    
    // タスクの完了状態を切り替え
    func toggleTaskCompletion(_ task: SimpleTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            if tasks[index].isCompleted {
                tasks[index].markIncomplete()
            } else {
                tasks[index].markCompleted()
            }
            saveTasks()
        }
    }
    
    // 指定されたタグのタスク統計を取得
    func getTaskStatistics(for tagId: UUID) -> (total: Int, completed: Int, pending: Int) {
        let tagTasks = tasks.filter { $0.tagId == tagId }
        let completed = tagTasks.filter { $0.isCompleted }.count
        let total = tagTasks.count
        let pending = total - completed
        
        return (total: total, completed: completed, pending: pending)
    }
    
    // 指定されたタグの高優先度タスク数を取得
    func getHighPriorityTaskCount(for tagId: UUID) -> Int {
        return tasks.filter { $0.tagId == tagId && $0.priority == .high && !$0.isCompleted }.count
    }
}