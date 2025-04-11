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
    
    // テスト日関連のプロパティ
    @Published var testDate: Date? = nil
    @Published var shouldUseTestDate: Bool = false
    @Published var showTestDatePicker: Bool = false
    @Published var selectedTags: [Tag] = []
    // アクティビティ関連
    @Published var contentChanged = false
    @Published var recordActivityOnSave = true
    @Published var savedMemo: Memo?  // var で宣言して変更可能に
    @Published var currentSessionId: UUID?
    
    @Published var showTitleAlert = false
    @Published var shouldFocusTitle = false
    @Published var showTitleInputGuide: Bool = false
    
    @Published var showQuestionCardGuide: Bool = false

    @Published var titleFieldFocused: Bool = false
    @Published var previouslyFocused: Bool = false
    @Published var hasTitleInput: Bool = false
    
    @Published var showMemoContentGuide: Bool = false


    // 初期化メソッドでの設定
    init(viewContext: NSManagedObjectContext, memo: Memo?) {
        self.viewContext = viewContext
        self.memo = memo
        self.savedMemo = memo
        
        if let memo = memo {
            loadMemoData(memo: memo)
            contentChanged = false
            recordActivityOnSave = false
            showTitleInputGuide = false
        } else {
            // 新規メモの場合
            resetForm()
            contentChanged = false
            recordActivityOnSave = true
            
            // 初回メモ作成時のみガイドを表示
            let hasCreatedFirstMemo = UserDefaults.standard.bool(forKey: "hasCreatedFirstMemo")
            showTitleInputGuide = !hasCreatedFirstMemo
        }
        // 初回メモ作成時のみガイドを表示
        if memo == nil {
            let hasCreatedFirstMemo = UserDefaults.standard.bool(forKey: "hasCreatedFirstMemo")
            showTitleInputGuide = !hasCreatedFirstMemo
        } else {
            showTitleInputGuide = false
        }
    }
    // タイトルフィールドのフォーカス状態変更を監視するメソッド
    func onTitleFocusChanged(isFocused: Bool) {
        // フォーカスが外れた時の処理
        if previouslyFocused && !isFocused {
            // タイトルが入力されている場合
            if !title.isEmpty && !hasTitleInput {
                hasTitleInput = true
                
                // タイトル入力ガイドが表示されていなければ問題カードガイドを表示
                if !showTitleInputGuide {
                    let hasSeenQuestionCardGuide = UserDefaults.standard.bool(forKey: "hasSeenQuestionCardGuide")
                    if !hasSeenQuestionCardGuide {
                        // 少し遅延させてから表示（自然な流れにするため）
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.showQuestionCardGuide = true
                        }
                    }
                }
            }
        }
        
        // 現在の状態を保存
        previouslyFocused = isFocused
        titleFieldFocused = isFocused
    }

    // ガイドを閉じる関数を追加
    func dismissTitleInputGuide() {
        showTitleInputGuide = false
        UserDefaults.standard.set(true, forKey: "hasCreatedFirstMemo")
    }
    
    func dismissQuestionCardGuide() {
        showQuestionCardGuide = false
        UserDefaults.standard.set(true, forKey: "hasSeenQuestionCardGuide")
        
        // 問題カードガイド後に内容ガイドを表示（初回のみ）
        let hasSeenMemoContentGuide = UserDefaults.standard.bool(forKey: "hasSeenMemoContentGuide")
        if !hasSeenMemoContentGuide {
            // 少し遅延させて表示（自然な遷移のため）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showMemoContentGuide = true
            }
        }
    }
    // 内容ガイドを閉じるメソッド
    func dismissMemoContentGuide() {
        showMemoContentGuide = false
        UserDefaults.standard.set(true, forKey: "hasSeenMemoContentGuide")
    }
    // loadMemoData関数内で次回復習日を確実に設定
    func loadMemoData(memo: Memo) {
        title = memo.title ?? ""
        pageRange = memo.pageRange ?? ""
        content = memo.content ?? ""
        recallScore = memo.recallScore
        reviewDate = memo.nextReviewDate // この行を確実に設定
        
        // テスト日の読み込み
        testDate = memo.testDate
        shouldUseTestDate = memo.testDate != nil
        
        // 保存された単語リストを読み込む
        if let savedKeywords = memo.keywords?.components(separatedBy: ",") {
            keywords = savedKeywords.filter { !$0.isEmpty }
        }
        
        // 比較問題を直接読み込む
        loadComparisonQuestions(for: memo)
        // タグを読み込む
        selectedTags = memo.tagsArray
    }
    // 次回復習日を更新するメソッド
    func updateNextReviewDate() {
        if shouldUseTestDate, let testDate = testDate {
            let reviewDates = calculateReviewScheduleBasedOnTestDate()
            if let firstReviewDate = reviewDates.first {
                reviewDate = firstReviewDate
            } else {
                // テスト日ベースの計算ができない場合は通常計算
                reviewDate = ReviewCalculator.calculateNextReviewDate(
                    recallScore: recallScore,
                    lastReviewedDate: Date(),
                    perfectRecallCount: memo?.perfectRecallCount ?? 0
                )
            }
        } else {
            // 通常の復習日計算
            reviewDate = ReviewCalculator.calculateNextReviewDate(
                recallScore: recallScore,
                lastReviewedDate: Date(),
                perfectRecallCount: memo?.perfectRecallCount ?? 0
            )
        }
    }
    
    func loadComparisonQuestions(for memo: Memo) {
        let fetchRequest: NSFetchRequest<ComparisonQuestion> = ComparisonQuestion.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "memo == %@", memo)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ComparisonQuestion.createdAt, ascending: true)]
        
        do {
            let fetchedQuestions = try viewContext.fetch(fetchRequest)
            comparisonQuestions = fetchedQuestions
        } catch {
            comparisonQuestions = []
        }
    }
    
    // テスト日に基づく復習スケジュールの計算
    func calculateReviewScheduleBasedOnTestDate() -> [Date] {
        guard let targetDate = testDate, shouldUseTestDate else {
            return [] // テスト日が設定されていない、または使用しない場合は空の配列を返す
        }
        
        return TestDateReviewer.calculateOptimalReviewSchedule(
            targetDate: targetDate,
            currentRecallScore: recallScore,
            lastReviewedDate: Date(),
            perfectRecallCount: memo?.perfectRecallCount ?? 0
        )
    }
    
    // 復習履歴を記録するメソッド
    func recordReviewHistory() {
        guard let memoToRecord = memo else { return }
        
        // 新しい履歴エントリーを作成
        let historyEntry = MemoHistoryEntry(context: viewContext)
        historyEntry.id = UUID()
        historyEntry.date = Date()
        historyEntry.recallScore = recallScore
        
        // 記憶定着度の計算に必要なデータを収集
        let previousEntries = memoToRecord.historyEntriesArray
        let reviewCount = previousEntries.count
        let highScoreCount = MemoryRetentionCalculator.countHighScores(historyEntries: previousEntries)
        let lastReviewDate = previousEntries.first?.date
        let daysSinceLastReview = MemoryRetentionCalculator.daysSinceLastReview(lastReviewDate: lastReviewDate)
        
        // 新しい記憶定着度を計算
        let retentionScore = MemoryRetentionCalculator.calculateEnhancedRetentionScore(
            recallScore: recallScore,
            daysSinceLastReview: daysSinceLastReview,
            reviewCount: reviewCount,
            highScoreCount: highScoreCount
        )
        
        // 計算結果を保存
        historyEntry.retentionScore = retentionScore
        historyEntry.memo = memoToRecord
        
        // 保存前の完璧回数を保持
        let oldPerfectRecallCount = memoToRecord.perfectRecallCount
        
        do {
            // まず履歴エントリを保存
            try viewContext.save()
            
            // 保存後の完璧回数をチェック（CoreDataによる自動更新を検出）
            viewContext.refresh(memoToRecord, mergeChanges: true)
        } catch {
        }
    }
    
    // テスト日を考慮した次回復習日の計算
    func getNextReviewDateWithTestDate() -> Date {
        if shouldUseTestDate, let testDate = testDate {
            let reviewDates = calculateReviewScheduleBasedOnTestDate()
            if let firstReviewDate = reviewDates.first {
                return firstReviewDate
            }
        }
        
        // デフォルトの復習日計算
        return reviewDate ?? ReviewCalculator.calculateNextReviewDate(
            recallScore: recallScore,
            lastReviewedDate: Date(),
            perfectRecallCount: memo?.perfectRecallCount ?? 0
        )
    }
    
    // タグの更新処理
    private func updateTags(for memo: Memo) {
        // 現在のタグを一旦全て削除
        let currentTags = memo.tags as? Set<Tag> ?? []
        for tag in currentTags {
            memo.removeTag(tag)
        }
        
        // 選択されたタグを追加
        for tag in selectedTags {
            memo.addTag(tag)
        }
    }
    
    // 既存の saveMemo メソッドを修正
    func saveMemo(completion: @escaping () -> Void) {
        // タイトルのみ必須にする（ページ範囲は任意）
        if title.isEmpty {
            showTitleAlert = true
            shouldFocusTitle = true
            return
        }
        
        let memoToSave: Memo
        let isNewMemo = memo == nil
        
        if let existingMemo = memo {
            memoToSave = existingMemo
        } else {
            memoToSave = Memo(context: viewContext)
            memoToSave.id = UUID()
            memoToSave.createdAt = Date()
        }
        
        memoToSave.title = title
        memoToSave.pageRange = pageRange // 空でも保存可能
        memoToSave.content = content
        memoToSave.recallScore = recallScore
        memoToSave.lastReviewedDate = Date()
        
        // perfectRecallCountは計算プロパティなので直接変更せず、現在の値を読み取る
        let currentPerfectRecallCount = memoToSave.perfectRecallCount
        
        // テスト日の保存
        memoToSave.testDate = shouldUseTestDate ? testDate : nil
        
        // テスト日に基づく復習日の設定
        let oldDate = memoToSave.nextReviewDate
        // 記憶度変更検出
        let hasRecallScoreChanged = memo != nil && memo?.recallScore != recallScore
        if hasRecallScoreChanged {
            // 記憶度が80%以上だが100%未満の場合も、復習日延長の恩恵を受けられるようにする
            if recallScore >= 80 {
                // 記憶度に基づいて次のレベルの間隔を計算
                let baseIntervals: [Double] = [1, 3, 7, 14, 30, 60, 120]
                let currentIndex = min(Int(currentPerfectRecallCount), baseIntervals.count - 1)
                let nextIndex = min(currentIndex + 1, baseIntervals.count - 1)
                
                // 記憶度と完璧回数に基づく係数を計算
                let scoreFactor = 0.5 + (Double(recallScore) / 100.0)
                
                // 現在の基本間隔と次のレベルの基本間隔を取得
                let currentInterval = baseIntervals[currentIndex]
                let nextInterval = baseIntervals[nextIndex]
                
                // 記憶度80%〜99%では、現在の間隔と次の間隔の間の値を使用
                let progressFactor = Double(recallScore - 80) / 20.0  // 80%→0.0, 100%→1.0
                let blendedInterval = currentInterval + (nextInterval - currentInterval) * progressFactor
                let adjustedInterval = blendedInterval * scoreFactor
                
                // 修正された復習日を設定（テスト日処理より前に設定）
                let calendar = Calendar.current
                let adjustedDate = calendar.date(byAdding: .day, value: Int(adjustedInterval), to: Date())!
                
                // 後続のテスト日処理で上書きされる可能性があるため、ここでは変数に保持するだけ
                let calculatedReviewDate = adjustedDate
                
                // テスト日がなく、かつ記憶度80%以上の場合のみ採用（テスト日処理を無効化）
                if !(shouldUseTestDate && testDate != nil) {
                    memoToSave.nextReviewDate = calculatedReviewDate
                }
            }
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        if shouldUseTestDate, let testDate = testDate {
            let reviewDates = calculateReviewScheduleBasedOnTestDate()
            if let firstReviewDate = reviewDates.first {
                memoToSave.nextReviewDate = firstReviewDate
            } else {
                let newReviewDate = ReviewCalculator.calculateNextReviewDate(
                    recallScore: recallScore,
                    lastReviewedDate: Date(),
                    perfectRecallCount: currentPerfectRecallCount
                )
                
                memoToSave.nextReviewDate = newReviewDate
            }
        } else {
            // 通常の復習日計算
            let newReviewDate = ReviewCalculator.calculateNextReviewDate(
                recallScore: recallScore,
                lastReviewedDate: Date(),
                perfectRecallCount: currentPerfectRecallCount
            )
            // 新しい復習日を設定
            memoToSave.nextReviewDate = newReviewDate
        }
        
        // 単語リストをカンマ区切りで保存
        memoToSave.keywords = keywords.joined(separator: ",")
        
        // タグを保存 - 明示的に更新処理を実行
        updateTags(for: memoToSave)
        do {
            // 変更を保存
            try viewContext.save()
            
            viewContext.refresh(memoToSave, mergeChanges: true)
            
            // 記憶履歴を記録
            recordReviewHistory()
            
            // 履歴記録後
            viewContext.refresh(memoToSave, mergeChanges: true)
            
            // 💫 追加：履歴記録（perfectRecallCount更新）後に復習日を再計算
            let updatedPerfectRecallCount = memoToSave.perfectRecallCount
            if updatedPerfectRecallCount != currentPerfectRecallCount {
                // テスト日に基づくか通常の計算かを判断
                if shouldUseTestDate, let testDate = testDate {
                    let reviewDates = calculateReviewScheduleBasedOnTestDate()
                    if let firstReviewDate = reviewDates.first {
                        let oldDate = memoToSave.nextReviewDate
                        memoToSave.nextReviewDate = firstReviewDate
                    }
                } else {
                    // 通常の復習日再計算
                    let oldDate = memoToSave.nextReviewDate
                    let newReviewDate = ReviewCalculator.calculateNextReviewDate(
                        recallScore: recallScore,
                        lastReviewedDate: Date(),
                        perfectRecallCount: updatedPerfectRecallCount  // 更新された完璧回数を使用
                    )
                    memoToSave.nextReviewDate = newReviewDate
                }
                
                // 再計算後に保存
                try viewContext.save()
            }
            
            // 一時保存された比較ペアがあれば、それらの比較問題を作成
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
            
            // ストリークを更新
            StreakTracker.shared.checkAndUpdateStreak(in: viewContext)
            
            // 変更を確実に保存（最終）
            try viewContext.save()
            
            // メインスレッドで通知を送信
            DispatchQueue.main.async {
                // 全アプリに通知を送信して強制的にデータをリロード
                NotificationCenter.default.post(
                    name: NSNotification.Name("ForceRefreshMemoData"),
                    object: nil,
                    userInfo: ["memoID": memoToSave.objectID]
                )
                
                // 少し遅延させて2回目の通知も送信
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ForceRefreshMemoData"),
                        object: nil
                    )
                }
            }
            
            // memo ではなく savedMemo に保存
            self.savedMemo = memoToSave
            resetForm(preserveTags: memo != nil)
            completion()
        } catch {
            completion()
        }
    }
    
    func cleanupOrphanedQuestions() {
        // memo == nil の問題を検索して削除（孤立した問題）
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
        }
    }
    
    func resetForm(preserveTags: Bool = false) {
        title = ""
        pageRange = ""
        content = ""
        recallScore = 50
        reviewDate = nil
        keywords = []
        comparisonQuestions = []
        
        // テスト日関連のリセット
        testDate = nil
        shouldUseTestDate = false
        showTestDatePicker = false
        
        // タグのリセットは条件付きに
        if !preserveTags {
            selectedTags = []
        }
    }
    
    func formattedDate(_ date: Date?) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return date != nil ? formatter.string(from: date!) : "未設定"
    }
    
    // タグを即時更新し保存するメソッド
    func updateAndSaveTags() {
        guard let memoToUpdate = memo else {
            return
        }
        
        // 待機中の他の変更を先に保存
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
            }
        }
        
        // 現在のタグを一旦全て削除
        let currentTags = memoToUpdate.tags as? Set<Tag> ?? []
        for tag in currentTags {
            memoToUpdate.removeTag(tag)
        }
        
        // 選択されたタグを追加
        for tag in selectedTags {
            memoToUpdate.addTag(tag)
        }
        
        // 変更を保存
        do {
            try viewContext.save()
            viewContext.refresh(memoToUpdate, mergeChanges: true)
            
            // 強制的に通知を送信して更新を促す
            NotificationCenter.default.post(
                name: NSNotification.Name("ForceRefreshMemoData"),
                object: nil,
                userInfo: ["memoID": memoToUpdate.objectID]
            )
        } catch {
        }
    }

    // タグデータをリフレッシュするための新メソッド
    func refreshTags() {
        guard let memoToRefresh = memo else { return }
        
        // メモを再読み込みしてタグを更新
        viewContext.refresh(memoToRefresh, mergeChanges: true)
        
        // 選択されたタグを更新
        let refreshedTags = memoToRefresh.tagsArray
        selectedTags = refreshedTags
    }
}

extension ContentViewModel {
    // 初期化時に呼び出して時間計測を開始する
    func startLearningSession() {
        if let existingMemo = memo {
            // 既存メモの場合のみセッション開始
            currentSessionId = ActivityTracker.shared.startTimingSession(for: existingMemo)
            
            // 内容変更フラグを初期化
            contentChanged = false
        }
    }
    
    // メモの保存時に自動記録を行う - 実時間測定版
    func saveMemoWithTracking(completion: @escaping () -> Void) {
        let isNewMemo = memo == nil
        
        // 新規メモの場合は強制的に記録フラグをON
        if isNewMemo {
            contentChanged = true
            recordActivityOnSave = true
        }
        
        // 内容が変更されたか、新規メモの場合のみアクティビティ記録対象
        let shouldRecordActivity = contentChanged || isNewMemo
        
        saveMemo { [weak self] in
            guard let self = self else {
                completion()
                return
            }
            
            // savedMemo が保存されたか確認
            if let memo = self.savedMemo {
                // 内容が変更された場合のみ記録
                if shouldRecordActivity && self.recordActivityOnSave {
                    // アクティビティタイプの決定
                    let activityType: ActivityType = isNewMemo ? .exercise : .review
                    let context = PersistenceController.shared.container.viewContext
                    
                    if isNewMemo {
                        // 新規作成用の明示的な注釈
                        let noteText = "新規メモ作成: \(memo.title ?? "無題")"
                        
                        // 新規メモ作成アクティビティを記録
                        LearningActivity.recordActivityWithHabitChallenge(
                            type: .exercise, // 新規メモ作成は exercise タイプ
                            durationMinutes: 5, // 最小時間（適宜調整）
                            memo: memo,
                            note: noteText,
                            in: context
                        )
                    }
                }
            }
            
            // 状態をリセット
            self.contentChanged = false
            ReviewManager.shared.incrementTaskCompletionCount()
            
            completion()
        }
    }
    
    func saveMemoWithNotification() {
        do {
            try viewContext.save()
            
            // 全アプリに通知を送信して強制的にデータをリロード
            NotificationCenter.default.post(
                name: NSNotification.Name("ForceRefreshMemoData"),
                object: nil
            )
        } catch {
        }
    }
}
