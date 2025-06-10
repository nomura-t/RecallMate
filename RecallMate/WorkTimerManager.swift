import Foundation
import CoreData
import SwiftUI
import Combine

// 作業タイマーの状態管理クラス
class WorkTimerManager: ObservableObject {
    static let shared = WorkTimerManager()
    
    // タイマーの状態
    @Published var isRunning = false
    @Published var currentTag: Tag? = nil
    @Published var startTime: Date? = nil
    @Published var elapsedTime: TimeInterval = 0
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
    
    // タイマー開始
    func startTimer(for tag: Tag) {
        // 既に実行中の場合は停止
        if isRunning {
            // 現在のコンテキストを取得して停止処理を実行
            let context = PersistenceController.shared.container.viewContext
            stopTimer(in: context)
        }
        
        currentTag = tag
        startTime = Date()
        currentSessionId = UUID()
        isRunning = true
        elapsedTime = 0
        
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
    }
    
    // タイマー停止と記録保存
    func stopTimer(in context: NSManagedObjectContext) {
        guard isRunning,
              let tag = currentTag,
              let start = startTime else {
            return
        }
        
        // タイマーを停止
        timer?.invalidate()
        timer = nil
        
        let endTime = Date()
        let totalSeconds = Int(endTime.timeIntervalSince(start))
        
        // 最低1秒は記録
        let recordedSeconds = max(totalSeconds, 1)
        
        // 作業記録用のメモを作成または取得
        let workMemo = getOrCreateWorkMemo(for: tag, in: context)
        
        // LearningActivityに記録
        let noteText = "作業記録: \(tag.name ?? "無題") - \(formatDuration(recordedSeconds))"
        let _ = LearningActivity.recordActivityWithPrecision(
            type: .workTimer,
            durationSeconds: recordedSeconds,
            memo: workMemo,
            note: noteText,
            in: context
        )
        
        // 状態をリセット
        isRunning = false
        currentTag = nil
        startTime = nil
        elapsedTime = 0
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
            "作業記録: \(tag.name ?? "無題")",
            tagId as CVarArg // アンラップされたUUIDを使用
        )
        fetchRequest.fetchLimit = 1
        
        do {
            if let existingMemo = try context.fetch(fetchRequest).first {
                return existingMemo
            }
        } catch {
            // エラーの場合は新規作成に進む
            print("作業記録メモの検索エラー: \(error)")
        }
        
        // 新規作成
        return createNewWorkMemo(for: tag, in: context)
    }
    
    // 新しい作業記録用メモを作成
    private func createNewWorkMemo(for tag: Tag, in context: NSManagedObjectContext) -> Memo {
        let workMemo = Memo(context: context)
        workMemo.id = UUID()
        workMemo.title = "作業記録: \(tag.name ?? "無題")"
        workMemo.content = "この記録は作業タイマーによって自動生成されました。"
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
    
    // フォーマットされた経過時間を取得
    var formattedElapsedTime: String {
        return formatDuration(Int(elapsedTime))
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
}
