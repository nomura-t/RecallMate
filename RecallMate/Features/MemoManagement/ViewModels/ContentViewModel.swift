// ContentViewModel.swift
import SwiftUI
import CoreData

class ContentViewModel: ObservableObject {
    private let viewContext: NSManagedObjectContext
    private var memo: Memo?
    
    @Published var title = ""
    @Published var pageRange = ""
    @Published var content = ""
    @Published var recallScore: Int16 = 50
    @Published var reviewDate: Date? = nil
    @Published var keywords = [String]()
    @Published var comparisonQuestions: [ComparisonQuestion] = []
    // アクティビティ関連のプロパティ
    @Published var contentChanged = false
    @Published var recordActivityOnSave = true
    @Published var savedMemo: Memo?
    @Published var currentSessionId: UUID?
    
    // UI状態管理のプロパティ
    @Published var showTitleAlert = false
    @Published var shouldFocusTitle = false
    @Published var titleFieldFocused: Bool = false
    @Published var previouslyFocused: Bool = false
    @Published var hasTitleInput: Bool = false
    @Published var contentFieldFocused: Bool = false
    @Published var triggerBottomScroll: Bool = false

    @State private var memoCreationStartTime: Date? = nil

    // 初期化メソッド - 新規記録と既存記録の両方に対応
    init(viewContext: NSManagedObjectContext, memo: Memo?) {
        self.viewContext = viewContext
        self.memo = memo
        self.savedMemo = memo
        
        // 新規記録の場合は作成時間を記録
        if memo == nil {
            self.memoCreationStartTime = Date()
        }
        
        if let memo = memo {
            // 既存記録の場合：データを読み込み、変更フラグを初期化
            loadMemoData(memo: memo)
            contentChanged = false
            recordActivityOnSave = false
        } else {
            // 新規記録の場合：フォームをリセットし、記録準備完了状態に
            resetForm()
            contentChanged = false
            recordActivityOnSave = true
        }
    }
    
    // フォーカス状態管理メソッド - UIの応答性向上のため
    func onTitleFocusChanged(isFocused: Bool) {
        previouslyFocused = isFocused
        titleFieldFocused = isFocused
    }

    func onContentFocusChanged(isFocused: Bool) {
        contentFieldFocused = isFocused
    }
        
    // 記録データの読み込み - 既存記録を編集する際に使用
    func loadMemoData(memo: Memo) {
        title = memo.title ?? ""
        pageRange = memo.pageRange ?? ""
        content = memo.content ?? ""
        recallScore = memo.recallScore
        reviewDate = memo.nextReviewDate
        
        // 保存された単語リストを復元
        if let savedKeywords = memo.keywords?.components(separatedBy: ",") {
            keywords = savedKeywords.filter { !$0.isEmpty }
        }
        
        // 関連する比較問題を読み込み
    }
    
    // 次回復習日を更新 - シンプルな通常計算のみ
    func updateNextReviewDate() {
        // テスト日機能を削除し、常に科学的根拠に基づく分散学習アルゴリズムを使用
        reviewDate = ReviewCalculator.calculateNextReviewDate(
            recallScore: recallScore,
            lastReviewedDate: Date(),
            perfectRecallCount: memo?.perfectRecallCount ?? 0,
            historyEntries: memo?.historyEntriesArray ?? []
        )
    }
    
    // 復習履歴を記録 - 学習の進捗を科学的に追跡
    func recordReviewHistory() {
        guard let memoToRecord = memo else { return }
        
        // 新しい履歴エントリーを作成
        let historyEntry = MemoHistoryEntry(context: viewContext)
        historyEntry.id = UUID()
        historyEntry.date = Date()
        historyEntry.recallScore = recallScore
        
        // 記憶定着度の科学的計算のためのデータ収集
        let previousEntries = memoToRecord.historyEntriesArray
        let reviewCount = previousEntries.count
        let highScoreCount = MemoryRetentionCalculator.countHighScores(historyEntries: previousEntries)
        let lastReviewDate = previousEntries.first?.date
        let daysSinceLastReview = MemoryRetentionCalculator.daysSinceLastReview(lastReviewDate: lastReviewDate)
        
        // エビングハウスの忘却曲線とスペーシング効果を考慮した記憶定着度を計算
        let retentionScore = MemoryRetentionCalculator.calculateEnhancedRetentionScore(
            recallScore: recallScore,
            daysSinceLastReview: daysSinceLastReview,
            reviewCount: reviewCount,
            highScoreCount: highScoreCount
        )
        
        // 計算結果を履歴エントリに保存
        historyEntry.retentionScore = retentionScore
        historyEntry.memo = memoToRecord
        
        do {
            // 履歴エントリを保存し、CoreDataの自動更新を反映
            try viewContext.save()
            viewContext.refresh(memoToRecord, mergeChanges: true)
        } catch {
            // エラーハンドリング（実際のアプリではログ出力等を行う）
        }
    }
    
    // メインの保存メソッド - 記録の作成と更新を処理
    func saveMemo(completion: @escaping () -> Void) {
        // バリデーション：タイトルは必須項目
        if title.isEmpty {
            showTitleAlert = true
            shouldFocusTitle = true
            return
        }
        
        let memoToSave: Memo
        let _ = memo == nil
        
        // 新規記録か既存記録かに応じてメモオブジェクトを準備
        if let existingMemo = memo {
            memoToSave = existingMemo
        } else {
            memoToSave = Memo(context: viewContext)
            memoToSave.id = UUID()
            memoToSave.createdAt = Date()
        }
        
        // 基本データの設定
        memoToSave.title = title
        memoToSave.pageRange = pageRange
        memoToSave.content = content
        memoToSave.recallScore = recallScore
        memoToSave.lastReviewedDate = Date()
        
        // 現在の完璧回数を取得（後で復習日計算に使用）
        let currentPerfectRecallCount = memoToSave.perfectRecallCount
        
        // 記憶度変更検出による復習日の最適化
        let hasRecallScoreChanged = memo != nil && memo?.recallScore != recallScore
        if hasRecallScoreChanged {
            // 高い記憶度（80%以上）の場合は復習間隔を適切に延長
            if recallScore >= 80 {
                let baseIntervals: [Double] = [1, 3, 7, 14, 30, 60, 120]
                let currentIndex = min(Int(currentPerfectRecallCount), baseIntervals.count - 1)
                let nextIndex = min(currentIndex + 1, baseIntervals.count - 1)
                
                // 記憶度に基づく調整係数を計算
                let scoreFactor = 0.5 + (Double(recallScore) / 100.0)
                
                // 現在のレベルと次のレベルの間隔を取得
                let currentInterval = baseIntervals[currentIndex]
                let nextInterval = baseIntervals[nextIndex]
                
                // 記憶度80%-99%の場合：段階的な間隔延長を適用
                let progressFactor = Double(recallScore - 80) / 20.0
                let blendedInterval = currentInterval + (nextInterval - currentInterval) * progressFactor
                let adjustedInterval = blendedInterval * scoreFactor
                
                // 最適化された復習日を設定
                let calendar = Calendar.current
                if let adjustedDate = calendar.date(byAdding: .day, value: Int(adjustedInterval), to: Date()) {
                    memoToSave.nextReviewDate = adjustedDate
                }
            }
        } else {
            // 通常の復習日計算：科学的アルゴリズムを使用
            let newReviewDate = ReviewCalculator.calculateNextReviewDate(
                recallScore: recallScore,
                lastReviewedDate: Date(),
                perfectRecallCount: currentPerfectRecallCount,
                historyEntries: memoToSave.historyEntriesArray
            )
            memoToSave.nextReviewDate = newReviewDate
        }
        
        // 単語リストを永続化形式で保存
        memoToSave.keywords = keywords.joined(separator: ",")
        
        do {
            // データベースへの保存を実行
            try viewContext.save()
            viewContext.refresh(memoToSave, mergeChanges: true)
            
            // 復習履歴を記録（学習分析のため）
            recordReviewHistory()
            
            // 履歴記録後の追加処理
            viewContext.refresh(memoToSave, mergeChanges: true)
            
            // 完璧回数が更新された場合は復習日を再計算
            let updatedPerfectRecallCount = memoToSave.perfectRecallCount
            if updatedPerfectRecallCount != currentPerfectRecallCount {
                let newReviewDate = ReviewCalculator.calculateNextReviewDate(
                    recallScore: recallScore,
                    lastReviewedDate: Date(),
                    perfectRecallCount: updatedPerfectRecallCount,
                    historyEntries: memoToSave.historyEntriesArray
                )
                memoToSave.nextReviewDate = newReviewDate
                
                // 再計算後に保存
                try viewContext.save()
            }
            
            // 一時保存された比較問題を処理
            if let tempPairs = UserDefaults.standard.array(forKey: "tempComparisonPairs") as? [[String]] {
                for pair in tempPairs {
                    if pair.count == 2 {
                        let word1 = pair[0]
                        let word2 = pair[1]
                        
                        // 比較問題を作成
                        let newQuestion = ComparisonQuestion(context: viewContext)
                        newQuestion.id = UUID()
                        newQuestion.question = "「\(word1)」と「\(word2)」の違いを比較して説明してください。それぞれの特徴、共通点、相違点について詳細に述べてください。"
                        newQuestion.createdAt = Date()
                        newQuestion.memo = memoToSave
                    }
                }
                
                // 一時データをクリア
                UserDefaults.standard.removeObject(forKey: "tempComparisonPairs")
                try viewContext.save()
            }
            
            // 学習ストリークを更新（習慣化支援のため）
            StreakTracker.shared.checkAndUpdateStreak(in: viewContext)
            
            // 最終保存
            try viewContext.save()
            
            // アプリ全体にデータ更新を通知
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("ForceRefreshMemoData"),
                    object: nil,
                    userInfo: ["memoID": memoToSave.objectID]
                )
                
                // 追加の通知で確実性を高める
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ForceRefreshMemoData"),
                        object: nil
                    )
                }
            }
            
            // 保存されたメモを保持し、フォームをリセット
            self.savedMemo = memoToSave
            resetForm(preserveTags: memo != nil)
            completion()
        } catch {
            // エラー時は完了コールバックを呼び出し
            completion()
        }
    }
    
    // 孤立した比較問題のクリーンアップ
    func cleanupOrphanedQuestions() {
        let fetchRequest: NSFetchRequest<ComparisonQuestion> = ComparisonQuestion.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "memo == nil")
        
        do {
            let orphanedQuestions = try viewContext.fetch(fetchRequest)
            if !orphanedQuestions.isEmpty {
                for question in orphanedQuestions {
                    viewContext.delete(question)
                }
                try viewContext.save()
            }
        } catch {
            // エラーハンドリング
        }
    }
    
    // フォームのリセット処理
    func resetForm(preserveTags: Bool = false) {
        title = ""
        pageRange = ""
        content = ""
        recallScore = 50
        reviewDate = nil
        keywords = []
        comparisonQuestions = []
    }

    // 日付フォーマット用ヘルパーメソッド
    func formattedDate(_ date: Date?) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return date != nil ? formatter.string(from: date!) : "未設定"
    }
}

extension ContentViewModel {
    // 学習セッションの開始処理
    func startLearningSession() {
        if let existingMemo = memo {
            // 既存記録の復習セッションを開始
            currentSessionId = ActivityTracker.shared.startTimingSession(for: existingMemo)
            contentChanged = false
        }
    }
    
    // 学習時間追跡付きの保存メソッド
    func saveMemoWithTracking(completion: @escaping () -> Void) {
        let isNewMemo = memo == nil
        
        // 新規記録の場合は自動的に記録対象とする
        if isNewMemo {
            contentChanged = true
            recordActivityOnSave = true
        }
        
        let shouldRecordActivity = contentChanged || isNewMemo
        
        saveMemo { [weak self] in
            guard let self = self else {
                completion()
                return
            }
            
            // 保存されたメモが存在し、活動記録が必要な場合
            if let memo = self.savedMemo, shouldRecordActivity && self.recordActivityOnSave {
                let activityType: ActivityType = isNewMemo ? .exercise : .review
                let context = PersistenceController.shared.container.viewContext
                
                if isNewMemo, let startTime = self.memoCreationStartTime {
                    // 実際の作業時間を計算
                    let durationSeconds = Int(Date().timeIntervalSince(startTime))
                    let adjustedDuration = max(durationSeconds, 1)
                    
                    // 学習活動を記録（戻り値は使用しないため_で受ける）
                    let noteText = "新規記録作成: \(memo.title ?? "無題")"
                    _ = LearningActivity.recordActivityWithPrecision(
                        type: activityType,
                        durationSeconds: adjustedDuration,
                        memo: memo,
                        note: noteText,
                        in: context
                    )
                }
            }
            
            // 完了時の音響フィードバック
            SoundManager.shared.playMemoryCompletedSound()

            // 状態をリセットし、レビュー管理を更新
            self.contentChanged = false
            ReviewManager.shared.incrementTaskCompletionCount()
            
            completion()
        }
    }
    
    // 通知付きの簡易保存メソッド
    func saveMemoWithNotification() {
        do {
            try viewContext.save()
            
            // データ更新を全アプリに通知
            NotificationCenter.default.post(
                name: NSNotification.Name("ForceRefreshMemoData"),
                object: nil
            )
        } catch {
            // エラーハンドリング
        }
    }
}
