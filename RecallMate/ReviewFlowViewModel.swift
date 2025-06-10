// HomeView/ReviewFlowViewModel.swift
import Foundation
import SwiftUI
import CoreData

/// 復習フローの状態管理とビジネスロジックを担当するViewModel
///
/// このViewModelは復習プロセス全体を管理し、以下の責務を持ちます：
/// - 復習ステップの進行管理
/// - 記憶度評価の処理
/// - 復習データの永続化
/// - タイマー機能
class ReviewFlowViewModel: ObservableObject {
    // MARK: - Published Properties（UI状態）
    @Published var showingReviewFlow = false
    @Published var reviewStep: Int = 0
    @Published var recallScore: Int16 = 50
    @Published var selectedReviewMethod: ReviewMethod = .thorough
    @Published var selectedReviewDate: Date = Date()
    @Published var defaultReviewDate: Date = Date()
    @Published var activeReviewStep: Int = 0
    @Published var reviewElapsedTime: TimeInterval = 0
    @Published var isSavingReview = false
    @Published var reviewSaveSuccess = false
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
        recallScore = memo.recallScore
        resetFlowState()
        showingReviewFlow = true
    }
    
    /// 復習フローを終了する
    func closeReviewFlow() {
        stopReviewTimer()
        resetFlowState()
        showingReviewFlow = false
        selectedMemoForReview = nil
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
    
    /// 復習完了処理を実行する
    func executeReviewCompletion() async {
        guard let memo = selectedMemoForReview, !isSavingReview else { return }
        
        await MainActor.run {
            isSavingReview = true
        }
        
        do {
            let sessionDuration = calculateSessionDuration()
            try await performReviewDataUpdate(memo: memo, sessionDuration: sessionDuration)
            
            await MainActor.run {
                isSavingReview = false
                reviewSaveSuccess = true
            }
        } catch {
            await MainActor.run {
                isSavingReview = false
            }
            // エラーハンドリング処理
            print("復習完了処理でエラーが発生しました: \(error)")
        }
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
    
    // MARK: - Private Methods（内部処理）
    
    /// フロー状態をリセットする
    private func resetFlowState() {
        reviewStep = 0
        selectedReviewMethod = .thorough
        activeReviewStep = 0
        reviewElapsedTime = 0
        isSavingReview = false
        reviewSaveSuccess = false
        sessionStartTime = Date()
    }
    
    /// 経過時間を更新する
    private func updateElapsedTime() {
        reviewElapsedTime = Date().timeIntervalSince(activeReviewStartTime)
    }
    
    /// セッション時間を計算する
    private func calculateSessionDuration() -> Int {
        if selectedReviewMethod == .assessment {
            return Int(Date().timeIntervalSince(sessionStartTime))
        } else {
            return Int(Date().timeIntervalSince(activeReviewStartTime))
        }
    }
    
    /// 復習データの更新処理
    /// - Parameters:
    ///   - memo: 更新対象のメモ
    ///   - sessionDuration: セッション時間（秒）
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
                    
                    try self.viewContext.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// 復習ノートを作成する
    /// - Parameter memo: 対象のメモ
    /// - Returns: 作成されたノートテキスト
    private func createReviewNote(for memo: Memo) -> String {
        if selectedReviewMethod == .assessment {
            return "記憶度確認: \(memo.title ?? "無題") (記憶度: \(recallScore)%)"
        } else {
            return "アクティブリコール復習: \(memo.title ?? "無題") (\(selectedReviewMethod.rawValue), 記憶度: \(recallScore)%)"
        }
    }
    
    // MARK: - Computed Properties（計算プロパティ）
    
    /// 現在のステップタイトルを取得する
    var currentStepTitle: String {
        switch reviewStep {
        case 0: return "復習内容の確認"
        case 1: return "復習方法を選択"
        case 2:
            if selectedReviewMethod == .assessment {
                return "記憶度の評価"
            } else {
                return "アクティブリコール復習"
            }
        case 3: return "記憶度の評価"
        case 4: return "復習日の選択"
        case 5: return "復習完了"
        default: return "復習フロー"
        }
    }
    
    /// 現在のステップの色を取得する
    var currentStepColor: Color {
        switch reviewStep {
        case 0: return .blue
        case 1: return .purple
        case 2: return selectedReviewMethod.color
        case 3: return .orange
        case 4: return .indigo
        case 5: return .green
        default: return .gray
        }
    }
    
    /// 選択されているメモを取得する（読み取り専用）
    var currentMemo: Memo? {
        return selectedMemoForReview
    }
}
