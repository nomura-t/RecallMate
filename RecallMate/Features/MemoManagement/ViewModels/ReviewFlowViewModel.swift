// HomeView/ReviewFlowViewModel.swift
import Foundation
import SwiftUI
import CoreData

/// 復習フローの状態管理とビジネスロジックを担当するViewModel
///
/// アクティブリコール3ステップフロー:
/// - Step 0: 思い出しプロンプト（タイトルのみ表示 + 「答えを見る」ボタン）
/// - Step 1: 記憶度評価 + 自動日付計算
/// - Step 2: 完了フィードバック (自動保存 + 自動閉じ)
class ReviewFlowViewModel: ObservableObject {
    // MARK: - Published Properties（UI状態）
    @Published var showingReviewFlow = false
    @Published var reviewStep: Int = 0
    @Published var microStep: Int = 0 // 0=読む, 1=閉じる, 2=思い出す, 3=確認, 4=完了
    @Published var recallScore: Int16 = 50
    @Published var selectedReviewMethod: ReviewMethod = .thorough
    @Published var selectedReviewDate: Date = Date()
    @Published var defaultReviewDate: Date = Date()
    @Published var activeReviewStep: Int = 0
    @Published var reviewElapsedTime: TimeInterval = 0
    @Published var isSavingReview = false
    @Published var reviewSaveSuccess = false
    @Published var previousScore: Int16 = 50
    @Published var showDatePicker = false
    @Published var showLongTermMemoryAlert = false
    var activeReviewStartTime = Date()

    // MARK: - Private Properties（内部状態）
    private var selectedMemoForReview: Memo?
    private var sessionStartTime = Date()

    private var reviewTimer: Timer?
    private let viewContext: NSManagedObjectContext

    // MARK: - Initialization
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }

    // MARK: - Public Methods（外部インターフェース）

    /// 復習フローを開始する
    /// - Parameter memo: 復習対象のメモ
    func startReview(with memo: Memo) {
        selectedMemoForReview = memo
        previousScore = memo.recallScore
        recallScore = memo.recallScore
        resetFlowState()
        showingReviewFlow = true
        startReviewTimer()
    }

    /// 復習フローを終了する
    func closeReviewFlow() {
        stopReviewTimer()
        resetFlowState()
        showingReviewFlow = false
        selectedMemoForReview = nil

        // 完了後にデータ更新を通知
        NotificationCenter.default.post(
            name: NSNotification.Name("ForceRefreshMemoData"),
            object: nil
        )
    }

    /// 次のステップに進む
    func proceedToNextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            reviewStep += 1
        }
    }

    /// 特定のステップにジャンプする
    /// - Parameter step: 移動先のステップ番号
    func jumpToStep(_ step: Int) {
        withAnimation(.easeInOut(duration: 0.3)) {
            reviewStep = step
        }
    }

    /// 記憶度変更時に次回復習日を自動計算する
    func recalculateReviewDate() {
        guard let memo = selectedMemoForReview else { return }
        let calculatedDate = ReviewCalculator.calculateNextReviewDate(
            recallScore: recallScore,
            lastReviewedDate: Date(),
            perfectRecallCount: memo.perfectRecallCount,
            historyEntries: memo.historyEntriesArray
        )
        defaultReviewDate = calculatedDate
        if !showDatePicker {
            selectedReviewDate = calculatedDate
        }
    }

    /// 評価完了→保存→完了画面へ
    func completeReview() async {
        guard let memo = selectedMemoForReview, !isSavingReview else { return }

        // 日付を自動計算
        recalculateReviewDate()

        await MainActor.run {
            isSavingReview = true
            withAnimation(.easeInOut(duration: 0.3)) {
                reviewStep = 2
            }
        }

        do {
            let sessionDuration = calculateSessionDuration()
            try await performReviewDataUpdate(memo: memo, sessionDuration: sessionDuration)

            await MainActor.run {
                isSavingReview = false
                reviewSaveSuccess = true
                // ハプティクスフィードバック
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                // 長期記憶定着チェック
                if let m = selectedMemoForReview, m.perfectRecallCount >= 4 {
                    showLongTermMemoryAlert = true
                }
            }
        } catch {
            await MainActor.run {
                isSavingReview = false
            }
        }
    }

    /// 復習完了処理を実行する（レガシー互換）
    func executeReviewCompletion() async {
        await completeReview()
    }

    /// 長期記憶に定着したメモを削除する
    func deleteLongTermMemo() {
        guard let memo = selectedMemoForReview else { return }
        viewContext.delete(memo)
        do {
            try viewContext.save()
            NotificationCenter.default.post(
                name: NSNotification.Name("ForceRefreshMemoData"),
                object: nil
            )
        } catch {
            print("長期記憶メモの削除に失敗しました: \(error)")
        }
        closeReviewFlow()
    }

    // MARK: - Timer Management（タイマー管理）

    /// 復習タイマーを開始する
    func startReviewTimer() {
        activeReviewStartTime = Date()
        reviewElapsedTime = 0

        stopReviewTimer()

        reviewTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateElapsedTime()
        }

        if let timer = reviewTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    /// 復習タイマーを停止する
    func stopReviewTimer() {
        reviewTimer?.invalidate()
        reviewTimer = nil
    }

    // MARK: - Streak Data

    /// 現在のストリーク数を取得する
    func fetchCurrentStreak() -> Int16 {
        let fetchRequest = NSFetchRequest<StreakData>(entityName: "StreakData")
        do {
            let results = try viewContext.fetch(fetchRequest)
            return results.first?.currentStreak ?? 0
        } catch {
            return 0
        }
    }

    // MARK: - Private Methods（内部処理）

    /// フロー状態をリセットする
    private func resetFlowState() {
        reviewStep = 0
        microStep = 0
        selectedReviewMethod = .thorough
        activeReviewStep = 0
        reviewElapsedTime = 0
        isSavingReview = false
        reviewSaveSuccess = false
        showDatePicker = false
        showLongTermMemoryAlert = false
        sessionStartTime = Date()
    }

    /// 経過時間を更新する
    private func updateElapsedTime() {
        reviewElapsedTime = Date().timeIntervalSince(activeReviewStartTime)
    }

    /// セッション時間を計算する
    private func calculateSessionDuration() -> Int {
        return Int(Date().timeIntervalSince(sessionStartTime))
    }

    /// 復習データの更新処理
    private func performReviewDataUpdate(memo: Memo, sessionDuration: Int) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            viewContext.perform {
                do {
                    // メモの更新
                    memo.recallScore = self.recallScore
                    memo.lastReviewedDate = Date()
                    memo.nextReviewDate = self.selectedReviewDate

                    // 履歴エントリの作成
                    let historyEntry = MemoHistoryEntry(context: self.viewContext)
                    historyEntry.id = UUID()
                    historyEntry.date = Date()
                    historyEntry.recallScore = self.recallScore
                    historyEntry.memo = memo

                    // 学習アクティビティの記録
                    let noteText = self.createReviewNote(for: memo)
                    let actualDuration = max(sessionDuration, 1)

                    let _ = LearningActivity.recordActivityWithPrecision(
                        type: .review,
                        durationSeconds: actualDuration,
                        memo: memo,
                        note: noteText,
                        in: self.viewContext
                    )

                    // ストリーク更新
                    StreakTracker.shared.checkAndUpdateStreak(in: self.viewContext)

                    try self.viewContext.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// 復習ノートを作成する
    private func createReviewNote(for memo: Memo) -> String {
        return "復習: \(memo.title ?? "無題") (記憶度: \(recallScore)%)"
    }

    // MARK: - Computed Properties（計算プロパティ）

    /// 現在のステップタイトルを取得する
    var currentStepTitle: String {
        switch reviewStep {
        case 0: return "思い出す".localized
        case 1: return "記憶度の評価".localized
        case 2: return "復習完了".localized
        default: return "復習フロー"
        }
    }

    /// 現在のステップの色を取得する
    var currentStepColor: Color {
        switch reviewStep {
        case 0: return .purple
        case 1: return .blue
        case 2: return .green
        default: return .gray
        }
    }

    /// スコア差分テキスト
    var scoreDiffText: String {
        let diff = Int(recallScore) - Int(previousScore)
        if diff > 0 {
            return "+\(diff)%"
        } else if diff < 0 {
            return "\(diff)%"
        }
        return "±0%"
    }

    /// スコア差分の色
    var scoreDiffColor: Color {
        let diff = Int(recallScore) - Int(previousScore)
        if diff > 0 { return .green }
        if diff < 0 { return .red }
        return .secondary
    }

    /// 選択されているメモを取得する（読み取り専用）
    var currentMemo: Memo? {
        return selectedMemoForReview
    }
}
