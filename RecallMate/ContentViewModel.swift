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
    
    init(viewContext: NSManagedObjectContext, memo: Memo?) {
        self.viewContext = viewContext
        self.memo = memo
        self.savedMemo = memo
        
        if let memo = memo {
            loadMemoData(memo: memo)
            contentChanged = false // 初期状態はfalse
            recordActivityOnSave = false // 既存メモの場合、デフォルトでは記録しない
        } else {
            resetForm()
            contentChanged = false // 初期状態はfalse
            recordActivityOnSave = true // 新規メモの場合は記録する
        }
    }
    
    
    func loadMemoData(memo: Memo) {
        title = memo.title ?? ""
        pageRange = memo.pageRange ?? ""
        content = memo.content ?? ""
        recallScore = memo.recallScore
        reviewDate = memo.nextReviewDate
        
        // テスト日の読み込み
        testDate = memo.testDate
        shouldUseTestDate = memo.testDate != nil
        
        // 保存された単語リストを読み込む
        if let savedKeywords = memo.keywords?.components(separatedBy: ",") {
            keywords = savedKeywords.filter { !$0.isEmpty }
            print("📝 読み込まれたキーワード数: \(keywords.count)")
        }
        
        // 比較問題を直接読み込む
        loadComparisonQuestions(for: memo)
        // タグを読み込む
        selectedTags = memo.tagsArray
    }
    
    func loadComparisonQuestions(for memo: Memo) {
        let fetchRequest: NSFetchRequest<ComparisonQuestion> = ComparisonQuestion.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "memo == %@", memo)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ComparisonQuestion.createdAt, ascending: true)]
        
        do {
            let fetchedQuestions = try viewContext.fetch(fetchRequest)
            comparisonQuestions = fetchedQuestions
            print("📚 ContentView - 問題の直接読み込み: \(comparisonQuestions.count)件")
            
            // 各問題の内容を確認
            for (index, question) in comparisonQuestions.enumerated() {
                print("問題 #\(index+1): \(question.question ?? "nil")")
            }
        } catch {
            print("❌ 問題読み込みエラー: \(error)")
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
            print("✅ 記憶定着度履歴を保存しました: スコア \(recallScore) -> 定着度 \(retentionScore)")
            
            // 記憶度に基づいて完璧回数を明示的に更新
            if recallScore >= 80 {
                // CoreDataからモデルを直接操作することは避け、エンティティはそのまま残す
                print("⭐ 高記憶度(\(recallScore)%)により完璧回数増加のタイミング")
            } else if recallScore < 50 {
                // 低記憶度の場合は完璧回数を明示的にリセット
                if memoToRecord.perfectRecallCount > 0 {
                    // 注: noteプロパティがないため、ログ出力のみにする
                    print("⚠️ 低記憶度(\(recallScore)%)により完璧回数リセットのタイミング")
                }
            }
            
            // 保存後の完璧回数をチェック（CoreDataによる自動更新を検出）
            viewContext.refresh(memoToRecord, mergeChanges: true)
            let newPerfectRecallCount = memoToRecord.perfectRecallCount
            
            // 完璧回数の変更をログ出力
            if oldPerfectRecallCount != newPerfectRecallCount {
                print("🔄 履歴記録後に完璧回数が変化: \(oldPerfectRecallCount) → \(newPerfectRecallCount)")
            } else {
                print("ℹ️ 完璧回数に変化なし: \(oldPerfectRecallCount)")
            }
        } catch {
            print("❌ 記憶定着度履歴の保存に失敗しました: \(error.localizedDescription)")
        }
    }
    
    // 記憶度に基づいて復習日を強制的に再計算するメソッド
    private func forceRecalculateReviewDate(for memo: Memo, with recallScore: Int16) {
        // テスト日に基づく計算かどうかを判断
        if memo.testDate != nil {
            // テスト日に基づく復習日計算
            let reviewDates = TestDateReviewer.calculateOptimalReviewSchedule(
                targetDate: memo.testDate!,
                currentRecallScore: recallScore,
                lastReviewedDate: Date(),
                perfectRecallCount: memo.perfectRecallCount
            )
            
            if let firstReviewDate = reviewDates.first {
                let oldDate = memo.nextReviewDate
                memo.nextReviewDate = firstReviewDate
                print("🔄 記憶度に基づく復習日再計算(テスト日あり): \(formattedDate(oldDate)) → \(formattedDate(firstReviewDate))")
            }
        } else {
            // 通常の復習日計算
            let oldDate = memo.nextReviewDate
            
            // 記憶度に応じた復習日計算
            // 記憶度が80%以上の場合は、次の完璧回数レベルの間隔を先取りして計算
            let effectivePerfectCount = recallScore >= 80 ? memo.perfectRecallCount + 1 : memo.perfectRecallCount
            
            let newReviewDate = ReviewCalculator.calculateNextReviewDate(
                recallScore: recallScore,
                lastReviewedDate: Date(),
                perfectRecallCount: effectivePerfectCount  // 80%以上なら次のレベルを先取り
            )
            
            memo.nextReviewDate = newReviewDate
            print("🔄 記憶度変更(\(recallScore)%)による復習日再計算: \(formattedDate(oldDate)) → \(formattedDate(newReviewDate))")
            
            // デバッグ: 何日後に設定されたかを計算
            let days = Calendar.current.dateComponents([.day], from: Date(), to: newReviewDate).day ?? 0
            print("  - 今日から\(days)日後に設定されました")
        }
        
        // 変更を保存
        do {
            try viewContext.save()
            print("✅ 記憶度に基づく復習日の再計算を保存しました")
        } catch {
            print("❌ 復習日再計算の保存に失敗しました: \(error.localizedDescription)")
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
        
        print("✅ タグを更新しました: \(selectedTags.count)個")
    }
    
    // 既存の saveMemo メソッドを修正
    func saveMemo(completion: @escaping () -> Void) {
        // タイトルのみ必須にする（ページ範囲は任意）
        if title.isEmpty {
            print("⚠️ タイトルを入力してください！")
            showTitleAlert = true
            shouldFocusTitle = true
            return
        }
        
        let memoToSave: Memo
        let isNewMemo = memo == nil
        
        print("📝 saveMemo開始:")
        print("- タイトル: \(title)")
        print("- isNewMemo: \(isNewMemo)")
        
        if let existingMemo = memo {
            memoToSave = existingMemo
            print("- 既存メモを更新します")
            print("- 現在のperfectRecallCount: \(memoToSave.perfectRecallCount)")
        } else {
            memoToSave = Memo(context: viewContext)
            memoToSave.id = UUID()
            memoToSave.createdAt = Date()
            print("- 新規メモを作成します: ID = \(memoToSave.id?.uuidString ?? "不明")")
        }
        
        memoToSave.title = title
        memoToSave.pageRange = pageRange // 空でも保存可能
        memoToSave.content = content
        memoToSave.recallScore = recallScore
        memoToSave.lastReviewedDate = Date()
        
        // perfectRecallCountは計算プロパティなので直接変更せず、現在の値を読み取る
        let currentPerfectRecallCount = memoToSave.perfectRecallCount
        print("- 現在の完璧回数: \(currentPerfectRecallCount)（読み取り専用）")
        
        // 記憶度によって将来の完璧回数がどう変わるかログだけ出力
        if !isNewMemo {
            if recallScore >= 80 {
                print("🔄 高い記憶度（\(recallScore)%）のため、将来的に完璧回数が増加する可能性: \(currentPerfectRecallCount) → \(currentPerfectRecallCount+1)")
            } else if recallScore < 50 {
                print("⚠️ 低い記憶度（\(recallScore)%）のため、将来的に完璧回数がリセットされる可能性: \(currentPerfectRecallCount) → 0")
            } else {
                print("ℹ️ 中程度の記憶度（\(recallScore)%）のため、完璧回数は変更なし: \(currentPerfectRecallCount)")
            }
        }
        
        // テスト日の保存
        memoToSave.testDate = shouldUseTestDate ? testDate : nil
        
        // テスト日に基づく復習日の設定
        let oldDate = memoToSave.nextReviewDate
        // 記憶度変更検出
        let hasRecallScoreChanged = memo != nil && memo?.recallScore != recallScore
        if hasRecallScoreChanged {
            print("🔄 記憶度が変更されました: \(memo?.recallScore ?? 0)% → \(recallScore)%")
            
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
                
                print("⭐ 高記憶度(\(recallScore)%)による間隔調整:")
                print("  - 現在レベル間隔: \(currentInterval)日")
                print("  - 次レベル間隔: \(nextInterval)日")
                print("  - 進行度係数: \(progressFactor)")
                print("  - 調整後間隔: \(adjustedInterval)日")
                
                // 修正された復習日を設定（テスト日処理より前に設定）
                let calendar = Calendar.current
                let adjustedDate = calendar.date(byAdding: .day, value: Int(adjustedInterval), to: Date())!
                
                // 後続のテスト日処理で上書きされる可能性があるため、ここでは変数に保持するだけ
                let calculatedReviewDate = adjustedDate
                
                // テスト日がなく、かつ記憶度80%以上の場合のみ採用（テスト日処理を無効化）
                if !(shouldUseTestDate && testDate != nil) {
                    memoToSave.nextReviewDate = calculatedReviewDate
                    print("🔄 記憶度\(recallScore)%による復習日先取り: \(formattedDate(oldDate)) → \(formattedDate(calculatedReviewDate))")
                    
                    // デバッグ: 何日後に設定されたかを計算
                    let days = Calendar.current.dateComponents([.day], from: Date(), to: calculatedReviewDate).day ?? 0
                    print("  - 今日から\(days)日後に設定されました")
                }
            }
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        if shouldUseTestDate, let testDate = testDate {
            let reviewDates = calculateReviewScheduleBasedOnTestDate()
            if let firstReviewDate = reviewDates.first {
                memoToSave.nextReviewDate = firstReviewDate
                print("✅ テスト日に基づく次回復習日を設定: \(formattedDate(oldDate)) → \(formattedDate(firstReviewDate))")
                
                // デバッグ: 何日後に設定されたかを計算
                let days = Calendar.current.dateComponents([.day], from: Date(), to: firstReviewDate).day ?? 0
                print("  - 今日から\(days)日後に設定されました")
            } else {
                // 通常の復習日計算
                print("📆 ReviewCalculator呼び出し前の状態確認:")
                print("  - recallScore: \(recallScore)")
                print("  - lastReviewedDate: \(Date())")
                print("  - perfectRecallCount: \(currentPerfectRecallCount)")
                
                let newReviewDate = ReviewCalculator.calculateNextReviewDate(
                    recallScore: recallScore,
                    lastReviewedDate: Date(),
                    perfectRecallCount: currentPerfectRecallCount
                )
                
                print("🔍 ReviewCalculator返却値検証: \(dateFormatter.string(from: newReviewDate))")
                memoToSave.nextReviewDate = newReviewDate
                print("✅ 通常の復習日計算（テスト日はあるが日程なし）: \(formattedDate(oldDate)) → \(formattedDate(newReviewDate))")
                
                // デバッグ: 何日後に設定されたかを計算
                let days = Calendar.current.dateComponents([.day], from: Date(), to: newReviewDate).day ?? 0
                print("  - 今日から\(days)日後に設定されました")
            }
        } else {
            // 通常の復習日計算
            print("📆 ReviewCalculator呼び出し前の状態確認:")
            print("  - recallScore: \(recallScore)")
            print("  - lastReviewedDate: \(Date())")
            print("  - perfectRecallCount: \(currentPerfectRecallCount)")
            
            let newReviewDate = ReviewCalculator.calculateNextReviewDate(
                recallScore: recallScore,
                lastReviewedDate: Date(),
                perfectRecallCount: currentPerfectRecallCount
            )
            
            print("🔍 ReviewCalculator返却値検証: \(dateFormatter.string(from: newReviewDate))")
            
            // 復習日を更新する前にnextReviewDateの値を確認
            print("🔍 復習日更新前: \(dateFormatter.string(from: memoToSave.nextReviewDate ?? Date()))")
            
            // 新しい復習日を設定
            memoToSave.nextReviewDate = newReviewDate
            
            // 復習日計算の詳細ログを追加
            print("✅ 通常の復習日計算（perfectRecallCount: \(currentPerfectRecallCount), 記憶度: \(recallScore)%）")
            print("  - 旧復習日: \(formattedDate(oldDate))")
            print("  - 新復習日: \(formattedDate(newReviewDate))")

            // デバッグ: 何日後に設定されたかを計算
            let days = Calendar.current.dateComponents([.day], from: Date(), to: newReviewDate).day ?? 0
            print("  - 今日から\(days)日後に設定されました")
            
            // 復習日設定後の値を確認
            print("🔍 復習日設定後: \(dateFormatter.string(from: memoToSave.nextReviewDate ?? Date()))")
        }
        
        // 単語リストをカンマ区切りで保存
        memoToSave.keywords = keywords.joined(separator: ",")
        
        // タグを保存 - 明示的に更新処理を実行
        updateTags(for: memoToSave)
        print("🏷️ タグを設定: \(selectedTags.map { $0.name ?? "" }.joined(separator: ", "))")
        
        // 保存前の最終確認
        print("🔍 CoreData保存前の最終確認:")
        print("- 次回復習日: \(dateFormatter.string(from: memoToSave.nextReviewDate ?? Date()))")
        print("- perfectRecallCount: \(memoToSave.perfectRecallCount)")
        print("- タグ数: \(memoToSave.tagsArray.count)")
        
        do {
            // 保存前の診断
            print("💉 保存前の診断:")
            MemoDiagnostics.shared.logMemoState(memoToSave, prefix: "  ")
            MemoDiagnostics.shared.diagnoseContext(viewContext)
            
            // 変更を保存
            try viewContext.save()
            print("✅ 初回CoreData保存完了")
            
            // 保存後の診断
            print("💉 保存後の診断:")
            viewContext.refresh(memoToSave, mergeChanges: true)
            MemoDiagnostics.shared.logMemoState(memoToSave, prefix: "  ")
            
            // 記憶履歴を記録
            print("📝 記憶履歴を記録します...")
            recordReviewHistory()
            
            // 履歴記録後の診断
            print("💉 履歴記録後の診断:")
            viewContext.refresh(memoToSave, mergeChanges: true)
            MemoDiagnostics.shared.logMemoState(memoToSave, prefix: "  ")
            
            // 履歴記録後のタグ確認
            print("🏷️ 保存後のタグ数: \(memoToSave.tagsArray.count)")
            for tag in memoToSave.tagsArray {
                print("  - タグ: \(tag.name ?? "無名")")
            }
            
            // 💫 追加：履歴記録（perfectRecallCount更新）後に復習日を再計算
            let updatedPerfectRecallCount = memoToSave.perfectRecallCount
            if updatedPerfectRecallCount != currentPerfectRecallCount {
                print("🔄 完璧回数が更新されました: \(currentPerfectRecallCount) → \(updatedPerfectRecallCount)")
                print("🔄 完璧回数更新後に復習日を再計算します")
                
                // テスト日に基づくか通常の計算かを判断
                if shouldUseTestDate, let testDate = testDate {
                    let reviewDates = calculateReviewScheduleBasedOnTestDate()
                    if let firstReviewDate = reviewDates.first {
                        let oldDate = memoToSave.nextReviewDate
                        memoToSave.nextReviewDate = firstReviewDate
                        print("✅ テスト日に基づく次回復習日を再計算: \(formattedDate(oldDate)) → \(formattedDate(firstReviewDate))")
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
                    print("✅ 更新後の完璧回数による復習日再計算: \(formattedDate(oldDate)) → \(formattedDate(newReviewDate))")
                    
                    // デバッグ: 何日後に設定されたかを計算
                    let days = Calendar.current.dateComponents([.day], from: Date(), to: newReviewDate).day ?? 0
                    print("  - 今日から\(days)日後に設定されました")
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
                        
                        print("✅ 一時保存された比較問題を作成: '\(word1)' vs '\(word2)'")
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
            
            // 最終保存後の確認
            let finalPerfectRecallCount = memoToSave.perfectRecallCount
            print("🔍 最終保存後の確認:")
            print("- 次回復習日: \(dateFormatter.string(from: memoToSave.nextReviewDate ?? Date()))")
            print("- perfectRecallCount: \(finalPerfectRecallCount)")
            print("- タグ数: \(memoToSave.tagsArray.count)")
            
            // メインスレッドで通知を送信
            DispatchQueue.main.async {
                // 全アプリに通知を送信して強制的にデータをリロード
                print("📣 データ更新通知を送信します(メインスレッドから)")
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
            print("✅ savedMemoプロパティを更新しました: \(memoToSave.id?.uuidString ?? "不明")")
            
            resetForm(preserveTags: memo != nil)
            completion()
        } catch {
            print("❌ 保存エラー: \(error.localizedDescription)")
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
                print("🧹 孤立した問題を削除: \(orphanedQuestions.count)件")
                for question in orphanedQuestions {
                    viewContext.delete(question)
                }
                try viewContext.save()
            }
        } catch {
            print("❌ 孤立問題の検索エラー: \(error.localizedDescription)")
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
            print("⚠️ 保存するメモがありません")
            return
        }
        
        // 待機中の他の変更を先に保存
        if viewContext.hasChanges {
            do {
                try viewContext.save()
                print("✅ 既存の変更を先に保存しました")
            } catch {
                print("⚠️ 既存変更の保存に失敗: \(error.localizedDescription)")
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
        
        // 詳細なデバッグ出力
        print("🔍 タグ更新中:")
        print("- 現在のメモ: \(memoToUpdate.title ?? "無題")")
        print("- 設定するタグ数: \(selectedTags.count)個")
        
        // 変更を保存
        do {
            try viewContext.save()
            viewContext.refresh(memoToUpdate, mergeChanges: true)
            
            // 保存後の検証
            let savedTags = memoToUpdate.tagsArray
            print("✅ タグを更新して保存しました: \(selectedTags.count)個")
            print("🔍 保存後の実際のタグ数: \(savedTags.count)個")
            
            // 強制的に通知を送信して更新を促す
            NotificationCenter.default.post(
                name: NSNotification.Name("ForceRefreshMemoData"),
                object: nil,
                userInfo: ["memoID": memoToUpdate.objectID]
            )
        } catch {
            print("❌ タグ更新保存エラー: \(error.localizedDescription)")
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
        
        print("🔄 タグデータをリフレッシュしました: \(selectedTags.count)個")
    }
}

extension ContentViewModel {
    // 初期化時に呼び出して時間計測を開始する
    func startLearningSession() {
        if let existingMemo = memo {
            // 既存メモの場合のみセッション開始
            currentSessionId = ActivityTracker.shared.startTimingSession(for: existingMemo)
            print("✅ 学習セッションを開始しました: \(existingMemo.title ?? "無題")")
            
            // 内容変更フラグを初期化
            contentChanged = false
        }
    }
    
    // メモの保存時に自動記録を行う - 実時間測定版
    func saveMemoWithTracking(completion: @escaping () -> Void) {
        let isNewMemo = memo == nil
        
        // 問題診断: 状態をログ出力
        print("📊 メモ保存診断:")
        print("- isNewMemo: \(isNewMemo)")
        print("- contentChanged: \(contentChanged)")
        print("- recordActivityOnSave: \(recordActivityOnSave)")
        
        // 新規メモの場合は強制的に記録フラグをON
        if isNewMemo {
            contentChanged = true
            recordActivityOnSave = true
            print("✅ 新規メモなので強制的に記録フラグをON")
        }
        
        // 内容が変更されたか、新規メモの場合のみアクティビティ記録対象
        let shouldRecordActivity = contentChanged || isNewMemo
        print("- shouldRecordActivity: \(shouldRecordActivity)")
        
        saveMemo { [weak self] in
            guard let self = self else {
                completion()
                return
            }
            
            print("📝 saveMemo完了後の状態確認:")
            print("- savedMemo: \(self.savedMemo != nil ? "存在します" : "nilです")")
            
            // savedMemo が保存されたか確認
            if let memo = self.savedMemo {
                print("- memo.title: \(memo.title ?? "無題")")
                print("- memo.id: \(memo.id?.uuidString ?? "不明")")
                
                // 内容が変更された場合のみ記録
                if shouldRecordActivity && self.recordActivityOnSave {
                    // アクティビティタイプの決定
                    let activityType: ActivityType = isNewMemo ? .exercise : .review
                    let context = PersistenceController.shared.container.viewContext
                    
                    if isNewMemo {
                        // 新規メモの場合：適切なアクティビティを直接作成
                        print("🆕 新規メモ作成のアクティビティを記録します")
                        
                        // 新規作成用の明示的な注釈
                        let noteText = "新規メモ作成: \(memo.title ?? "無題")"
                        
                        // 新規メモ作成アクティビティを記録
                        LearningActivity.recordActivity(
                            type: .exercise, // 新規メモ作成は exercise タイプ
                            durationMinutes: 5, // 最小時間（適宜調整）
                            memo: memo,
                            note: noteText,
                            in: context
                        )
                    } else if let sessionId = self.currentSessionId,
                              ActivityTracker.shared.hasActiveSession(sessionId: sessionId) {
                        // 既存メモの編集の場合：現在進行中のセッションを維持
                        // アクティビティの記録はContentView.onDisappearで行う
                        print("✏️ 既存メモ編集のアクティビティはビュー終了時に記録します")
                    }
                    
                    print("✅ アクティビティ記録の準備が完了しました")
                } else {
                    print("ℹ️ 内容に変更がないか記録フラグがOFFのため、アクティビティは記録しません")
                }
            } else {
                print("❌ savedMemoがnilです。メモが正しく保存されていない可能性があります。")
            }
            
            // 状態をリセット
            self.contentChanged = false
            ReviewManager.shared.incrementTaskCompletionCount()
            completion()
        }
    }
    
    func saveMemoWithNotification() {
        do {
            print("📣 完了直前の最終保存を実行")
            try viewContext.save()
            
            // 全アプリに通知を送信して強制的にデータをリロード
            NotificationCenter.default.post(
                name: NSNotification.Name("ForceRefreshMemoData"),
                object: nil
            )
        } catch {
            print("❌ 最終保存エラー: \(error)")
        }
    }
}
