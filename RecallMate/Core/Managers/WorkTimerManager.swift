import Foundation
import CoreData
import SwiftUI
import Combine

// 作業タイマーの状態管理クラス
class WorkTimerManager: ObservableObject {
    static let shared = WorkTimerManager()
    
    // タイマーの状態
    @Published var isRunning = false
    @Published var isPaused = false
    @Published var currentTag: Tag? = nil
    @Published var currentTask: SimpleTask? = nil
    @Published var startTime: Date? = nil
    @Published var elapsedTime: TimeInterval = 0
    @Published var accumulatedTime: TimeInterval = 0  // 累積時間（一時停止時も保持）
    @Published var currentSessionId: UUID? = nil
    
    // タイマー更新用
    private var timer: Timer?
    private var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
    
    private init() {
        // バックグラウンド移行時の処理
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // フォアグラウンド復帰時の処理
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // タイマー開始（新規またはセッション継続）
    func startTimer(for tag: Tag, task: SimpleTask? = nil) {
        
        // 既に実行中の場合は停止
        if isRunning {
            let context = PersistenceController.shared.container.viewContext
            stopTimer(in: context)
        }
        
        currentTag = tag
        currentTask = task
        startTime = Date()
        currentSessionId = UUID()
        isRunning = true
        isPaused = false
        elapsedTime = 0
        
        
        // タスクがある場合は、既存のセッション時間から復帰
        if let task = task, task.currentSessionSeconds > 0 {
            accumulatedTime = TimeInterval(task.currentSessionSeconds)
        } else {
            accumulatedTime = 0  // 新規セッションまたはタスクなし
        }
        
        // タイマーを開始
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateElapsedTime()
        }
        
        // RunLoopに追加してバックグラウンドでも動作するように
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
        
        // ハプティックフィードバック
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // 学習セッション同期（将来拡張用）
        
        // リアルタイム学習状態を更新
        updateStudyStatus(isStudying: true)
        
        // ハートビートを開始
        startHeartbeat()
    }
    
    // タイマー一時停止
    func pauseTimer() {
        guard isRunning && !isPaused else { return }
        
        // 現在の経過時間を累積時間に加算
        if let start = startTime {
            let currentElapsed = Date().timeIntervalSince(start)
            accumulatedTime += currentElapsed
        }
        
        // タイマーを停止
        timer?.invalidate()
        timer = nil
        
        // タスクに現在のセッション時間を保存（一時停止なので実作業時間には反映しない）
        if let currentTask = currentTask {
            saveTaskSessionTime(task: currentTask, totalSeconds: Int(accumulatedTime), finalize: false)
        }
        
        // 状態を更新
        isPaused = true
        isRunning = false
        startTime = nil
        elapsedTime = 0
        
        
        // ハプティックフィードバック
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        // 学習セッション同期（将来拡張用）
        
        // リアルタイム学習状態を更新
        updateStudyStatus(isStudying: false)
    }
    
    // タイマー再開
    func resumeTimer() {
        guard isPaused && !isRunning else { return }
        
        // 新しい開始時間を設定
        startTime = Date()
        isRunning = true
        isPaused = false
        elapsedTime = 0
        
        
        // タイマーを再開
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateElapsedTime()
        }
        
        // RunLoopに追加
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
        
        // ハプティックフィードバック
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // 学習セッション同期（将来拡張用）
        
        // リアルタイム学習状態を更新
        updateStudyStatus(isStudying: true)
    }
    
    // タイマー停止と記録保存
    func stopTimer(in context: NSManagedObjectContext) {
        guard (isRunning || isPaused),
              let tag = currentTag else {
            return
        }
        
        // タイマーを停止
        timer?.invalidate()
        timer = nil
        
        // 累積時間を計算
        var totalAccumulatedTime = accumulatedTime
        
        // 現在実行中の場合は、その時間も加算
        if isRunning, let start = startTime {
            let currentElapsed = Date().timeIntervalSince(start)
            totalAccumulatedTime += currentElapsed
        }
        
        let totalSeconds = Int(totalAccumulatedTime)
        
        // 最低1秒は記録
        let recordedSeconds = max(totalSeconds, 1)
        
        // 作業記録用のメモを作成または取得
        let workMemo = getOrCreateWorkMemo(for: tag, in: context)
        
        // LearningActivityに記録 - システムの学習時間測定に統合
        let noteText: String
        if let currentTask = currentTask {
            noteText = "作業記録: \(tag.name ?? "無題") - \(currentTask.title) - \(formatDuration(recordedSeconds))"
        } else {
            noteText = "作業記録: \(tag.name ?? "無題") - \(formatDuration(recordedSeconds))"
        }
        
        let _ = LearningActivity.recordActivityWithPrecision(
            type: .workTimer,
            durationSeconds: recordedSeconds,
            memo: workMemo,
            note: noteText,
            in: context
        )
        
        // タスクの実際の作業時間を更新
        if let currentTask = currentTask {
            // 現在のセッション時間をタスクに保存（停止時は累積時間をゼロにして実作業時間に反映）
            saveTaskSessionTime(task: currentTask, totalSeconds: recordedSeconds, finalize: true)
        }
        
        // 状態をリセット
        isRunning = false
        isPaused = false
        currentTag = nil
        currentTask = nil
        startTime = nil
        elapsedTime = 0
        accumulatedTime = 0
        currentSessionId = nil
        
        
        // バックグラウンドタスクを終了
        endBackgroundTask()
        
        // ハプティックフィードバック
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // データ更新を通知
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("RefreshActivityData"),
                object: nil
            )
        }
        
        // 学習セッション同期（将来拡張用）
        
        // リアルタイム学習状態を更新
        updateStudyStatus(isStudying: false)
    }
    
    // 経過時間を更新
    private func updateElapsedTime() {
        guard let start = startTime else { return }
        elapsedTime = Date().timeIntervalSince(start)
    }
    
    // 作業記録用のメモを取得または作成
    private func getOrCreateWorkMemo(for tag: Tag, in context: NSManagedObjectContext) -> Memo {
        // オプショナルバインディングでUUIDを安全に取り扱い
        guard let tagId = tag.id else {
            // タグIDがない場合は新規作成
            return createNewWorkMemo(for: tag, in: context)
        }
        
        // 既存の作業記録用メモを検索
        let fetchRequest: NSFetchRequest<Memo> = Memo.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "title == %@ AND ANY tags.id == %@",
            "作業記録: %@".localizedWithFormat(tag.name ?? "無題".localized),
            tagId as CVarArg // アンラップされたUUIDを使用
        )
        fetchRequest.fetchLimit = 1
        
        do {
            if let existingMemo = try context.fetch(fetchRequest).first {
                return existingMemo
            }
        } catch {
            // エラーの場合は新規作成に進む
        }
        
        // 新規作成
        return createNewWorkMemo(for: tag, in: context)
    }
    
    // 新しい作業記録用メモを作成
    private func createNewWorkMemo(for tag: Tag, in context: NSManagedObjectContext) -> Memo {
        let workMemo = Memo(context: context)
        workMemo.id = UUID()
        workMemo.title = "作業記録: %@".localizedWithFormat(tag.name ?? "無題".localized)
        workMemo.content = "この記録は作業タイマーによって自動生成されました。".localized
        workMemo.pageRange = ""
        workMemo.recallScore = 0  // 作業記録は記憶度評価なし
        workMemo.createdAt = Date()
        workMemo.lastReviewedDate = Date()
        workMemo.nextReviewDate = nil  // 復習不要
        
        // タグを関連付け
        workMemo.addTag(tag)
        
        return workMemo
    }
    
    // 時間のフォーマット
    func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        } else {
            return String(format: "%d:%02d", minutes, remainingSeconds)
        }
    }
    
    // 総経過時間（累積時間 + 現在の経過時間）
    var totalElapsedTime: TimeInterval {
        return accumulatedTime + elapsedTime
    }
    
    // フォーマットされた経過時間を取得
    var formattedElapsedTime: String {
        return formatDuration(Int(totalElapsedTime))
    }
    
    // 現在のタスクの残り時間を取得（秒単位）
    var remainingTaskTime: TimeInterval {
        guard let task = currentTask, task.estimatedMinutes > 0 else { return 0 }
        let estimatedSeconds = TimeInterval(task.estimatedMinutes * 60)
        return max(estimatedSeconds - totalElapsedTime, 0)
    }
    
    // フォーマットされた残り時間を取得
    var formattedRemainingTime: String {
        let remaining = Int(remainingTaskTime)
        return formatDuration(remaining)
    }
    
    // 現在のタスクの進捗率を取得（0.0〜1.0）
    var taskProgress: Double {
        guard let task = currentTask, task.estimatedMinutes > 0 else { return 0.0 }
        let estimatedSeconds = TimeInterval(task.estimatedMinutes * 60)
        return min(totalElapsedTime / estimatedSeconds, 1.0)
    }
    
    // タスクが予定時間を超過しているかどうか
    var isTaskOvertime: Bool {
        guard let task = currentTask, task.estimatedMinutes > 0 else { return false }
        let estimatedSeconds = TimeInterval(task.estimatedMinutes * 60)
        return totalElapsedTime > estimatedSeconds
    }
    
    // タイマーがアクティブかどうか（実行中または一時停止中）
    var isActive: Bool {
        return isRunning || isPaused
    }
    
    // バックグラウンド処理
    @objc private func appDidEnterBackground() {
        if isRunning {
            beginBackgroundTask()
        }
    }
    
    @objc private func appWillEnterForeground() {
        endBackgroundTask()
        // フォアグラウンド復帰時に経過時間を再計算
        updateElapsedTime()
    }
    
    private func beginBackgroundTask() {
        backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "WorkTimer") {
            self.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTaskId != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskId)
            backgroundTaskId = .invalid
        }
    }
    
    // タスクのセッション時間を保存
    private func saveTaskSessionTime(task: SimpleTask, totalSeconds: Int, finalize: Bool) {
        let taskManager = SimpleTaskManager.shared
        var updatedTask = task
        
        if finalize {
            // セッション終了：セッション時間を実作業時間に反映してリセット
            updatedTask.updateSessionTime(seconds: totalSeconds)
            updatedTask.finalizeCurrentSession()
        } else {
            // 一時停止：セッション時間のみ更新
            updatedTask.updateSessionTime(seconds: totalSeconds)
        }
        
        taskManager.updateTask(updatedTask)
    }
    
    // MARK: - Study Status Integration
    
    /// リアルタイム学習状態を更新
    private func updateStudyStatus(isStudying: Bool) {
        Task { @MainActor in
            await updateStudyStatusAsync(isStudying: isStudying)
        }
    }
    
    /// 非同期で学習状態を更新
    private func updateStudyStatusAsync(isStudying: Bool) async {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            print("⚠️ WorkTimerManager: ユーザーがサインインしていません")
            return
        }
        
        let studySubject = getStudySubject()
        
        do {
            let supabaseClient = SupabaseManager.shared.client
            
            // update_study_status関数を呼び出し
            struct UpdateStudyStatusParams: Codable {
                let p_user_id: String
                let p_is_studying: Bool
                let p_study_subject: String?
            }
            
            let params = UpdateStudyStatusParams(
                p_user_id: userId.uuidString,
                p_is_studying: isStudying,
                p_study_subject: studySubject
            )
            
            try await supabaseClient
                .rpc("update_study_status", params: params)
                .execute()
            
            print("✅ WorkTimerManager: 学習状態更新成功 - 学習中: \(isStudying)")
            if let subject = studySubject {
                print("   - 学習内容: \(subject)")
            }
        } catch {
            print("❌ WorkTimerManager: 学習状態更新エラー - \(error)")
        }
    }
    
    /// 現在の学習内容を取得
    private func getStudySubject() -> String? {
        if let task = currentTask {
            return task.title
        } else if let tag = currentTag {
            return tag.name
        }
        return nil
    }
    
    /// 定期的に学習状態のハートビートを送信
    private func startHeartbeat() {
        // 30秒ごとにハートビートを送信
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isRunning else { return }
            
            Task { @MainActor in
                await self.sendHeartbeat()
            }
        }
    }
    
    /// ハートビートを送信して学習状態を更新
    private func sendHeartbeat() async {
        guard let userId = SupabaseManager.shared.currentUser?.id else { return }
        
        do {
            let supabaseClient = SupabaseManager.shared.client
            
            // 現在のセッション時間を計算
            let currentMinutes = Int(totalElapsedTime / 60)
            
            // user_study_statusテーブルを直接更新
            try await supabaseClient
                .from("user_study_status")
                .update([
                    "current_session_minutes": "\(currentMinutes)",
                    "last_heartbeat": Date().ISO8601Format()
                ])
                .eq("user_id", value: userId.uuidString)
                .execute()
            
            print("🔄 WorkTimerManager: ハートビート送信完了 - セッション時間: \(currentMinutes)分")
        } catch {
            print("❌ WorkTimerManager: ハートビート送信エラー - \(error)")
        }
    }
}
