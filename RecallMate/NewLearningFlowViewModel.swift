import Foundation
import SwiftUI
import CoreData

class NewLearningFlowViewModel: ObservableObject {
    // MARK: - Published Properties（UI状態）
    @Published var showingNewLearningFlow = false
    @Published var newLearningStep: Int = 0
    @Published var newLearningTitle = ""
    @Published var newLearningTags: [Tag] = []
    
    // リアルタイム計算に対応した理解度プロパティ
    @Published var newLearningInitialScore: Int16 = 70 {
        didSet {
            // 理解度が変更された瞬間に復習日を再計算
            // didSetは、プロパティの値が設定された直後に呼ばれる特別なメソッドです
            updateReviewDateBasedOnScore()
        }
    }
    
    @Published var selectedLearningMethod: LearningMethod = .thorough
    
    // リアルタイム更新される復習日プロパティ
    @Published var selectedNewLearningReviewDate: Date = Date()
    @Published var defaultNewLearningReviewDate: Date = Date()
    
    // 復習日計算の状態を追跡するプロパティ
    @Published var isCalculatingReviewDate = false
    @Published var lastCalculationTime = Date()
    
    @Published var activeRecallStep: Int = 0
    @Published var learningElapsedTime: TimeInterval = 0
    @Published var isSavingNewLearning = false
    @Published var newLearningSaveSuccess = false
    var activeRecallStartTime = Date()
    
    // MARK: - Private Properties（内部状態）
    private var newLearningSessionStartTime = Date()
    private var learningTimer: Timer?
    private let viewContext: NSManagedObjectContext
    
    // デバウンス用のタイマー（頻繁な計算を避けるため）
    private var calculationDebounceTimer: Timer?
    
    // MARK: - Initialization
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        
        // 初期化時に最初の復習日を計算
        // ViewModelが作成された時点で、適切な初期値を設定します
        updateReviewDateBasedOnScore()
    }
    
    // MARK: - Review Date Calculation Methods（復習日計算メソッド）
    
    /// 理解度に基づいて復習日をリアルタイム更新する
    /// このメソッドは理解度が変更されるたびに自動的に呼ばれます
    private func updateReviewDateBasedOnScore() {
        // デバウンス処理：短時間での連続計算を避ける
        // ユーザーがスライダーを素早く動かしても、計算負荷を最小限に抑えます
        calculationDebounceTimer?.invalidate()
        calculationDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
            self?.performReviewDateCalculation()
        }
    }
    
    /// 実際の復習日計算を実行する
    private func performReviewDateCalculation() {
        // 計算開始を通知（UIでローディング表示などに使用可能）
        isCalculatingReviewDate = true
        lastCalculationTime = Date()
        
        // 非同期で計算を実行（UIの応答性を保つため）
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // 復習日の計算を実行
            let newReviewDate = ReviewCalculator.calculateNextReviewDate(
                recallScore: self.newLearningInitialScore,
                lastReviewedDate: Date(),
                perfectRecallCount: 0 // 新規学習なので0
            )
            
            // 計算が完了したらメインスレッドでUI更新
            DispatchQueue.main.async {
                self.defaultNewLearningReviewDate = newReviewDate
                self.selectedNewLearningReviewDate = newReviewDate
                self.isCalculatingReviewDate = false
                
            }
        }
    }
    
    /// 復習日を手動で再計算する（ユーザーアクション用）
    func recalculateReviewDate() {
        performReviewDateCalculation()
    }
    
    /// 推奨復習日にリセットする
    func resetToRecommendedDate() {
        selectedNewLearningReviewDate = defaultNewLearningReviewDate
    }
    
    // MARK: - Existing Methods（既存のメソッド）
    
    func startNewLearning() {
        resetFlowState()
        showingNewLearningFlow = true
    }
    
    func closeNewLearningFlow() {
        stopLearningTimer()
        calculationDebounceTimer?.invalidate()
        resetFlowState()
        showingNewLearningFlow = false
    }
    
    func proceedToNextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            newLearningStep += 1
        }
    }
    
    func jumpToStep(_ step: Int) {
        withAnimation(.easeInOut(duration: 0.3)) {
            newLearningStep = step
        }
    }
    
    func toggleTag(_ tag: Tag) {
        if newLearningTags.contains(where: { $0.id == tag.id }) {
            removeTag(tag)
        } else {
            newLearningTags.append(tag)
        }
    }
    
    func removeTag(_ tag: Tag) {
        if let index = newLearningTags.firstIndex(where: { $0.id == tag.id }) {
            newLearningTags.remove(at: index)
        }
    }
    
    // MARK: - Timer Management（タイマー管理）
    
    func startLearningTimer() {
        activeRecallStartTime = Date()
        learningElapsedTime = 0
        
        stopLearningTimer()
        
        learningTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateElapsedTime()
        }
        
        if let timer = learningTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    func stopLearningTimer() {
        learningTimer?.invalidate()
        learningTimer = nil
    }
    
    // MARK: - Private Methods（内部処理）
    
    private func resetFlowState() {
        newLearningStep = 0
        newLearningTitle = ""
        newLearningTags = []
        newLearningInitialScore = 70 // didSetが呼ばれて復習日が再計算される
        selectedLearningMethod = .thorough
        activeRecallStep = 0
        learningElapsedTime = 0
        isSavingNewLearning = false
        newLearningSaveSuccess = false
        newLearningSessionStartTime = Date()
    }
    
    private func updateElapsedTime() {
        learningElapsedTime = Date().timeIntervalSince(activeRecallStartTime)
    }
    
    private func calculateSessionDuration() -> Int {
        if selectedLearningMethod == .recordOnly {
            return Int(Date().timeIntervalSince(newLearningSessionStartTime))
        } else {
            return Int(Date().timeIntervalSince(activeRecallStartTime))
        }
    }
    
    // MARK: - Computed Properties（計算プロパティ）
    
    var isInputValid: Bool {
        return !newLearningTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var currentStepTitle: String {
        switch newLearningStep {
        case 0: return "学習内容を入力"
        case 1: return "学習方法を選択"
        case 2:
            if selectedLearningMethod == .recordOnly {
                return "理解度の評価"
            } else {
                return "アクティブリコール学習"
            }
        case 3: return "理解度の評価"
        case 4: return "復習日の選択"
        case 5: return "学習記録完了"
        default: return "新規学習フロー"
        }
    }
    
    var currentStepColor: Color {
        switch newLearningStep {
        case 0: return .blue
        case 1: return .purple
        case 2: return selectedLearningMethod.color
        case 3: return .orange
        case 4: return .indigo
        case 5: return .green
        default: return .gray
        }
    }
    
    /// 学習完了処理を実行する
    func executeNewLearningCompletion() async {
        guard !newLearningTitle.isEmpty, !isSavingNewLearning else { return }
        
        await MainActor.run {
            isSavingNewLearning = true
        }
        
        do {
            let sessionDuration = calculateSessionDuration()
            try await performNewLearningDataSave(sessionDuration: sessionDuration)
            
            await MainActor.run {
                isSavingNewLearning = false
                newLearningSaveSuccess = true
            }
        } catch {
            await MainActor.run {
                isSavingNewLearning = false
            }
            // エラーハンドリング処理
        }
    }
    
//    // MARK: - Timer Management（タイマー管理）
//    
//    /// 学習タイマーを開始する
//    func startLearningTimer() {
//        activeRecallStartTime = Date()
//        learningElapsedTime = 0
//        
//        stopLearningTimer()
//        
//        learningTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
//            self?.updateElapsedTime()
//        }
//        
//        if let timer = learningTimer {
//            RunLoop.main.add(timer, forMode: .common)
//        }
//    }
//    
//    /// 学習タイマーを停止する
//    func stopLearningTimer() {
//        learningTimer?.invalidate()
//        learningTimer = nil
//    }
//    
//    // MARK: - Validation（バリデーション）
//    
//    /// 入力内容が有効かどうかを確認する
//    var isInputValid: Bool {
//        return !newLearningTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
//    }
//    
//    // MARK: - Private Methods（内部処理）
//    
//    /// フロー状態をリセットする
//    private func resetFlowState() {
//        newLearningStep = 0
//        newLearningTitle = ""
//        newLearningTags = []
//        newLearningInitialScore = 70
//        selectedLearningMethod = .thorough
//        activeRecallStep = 0
//        learningElapsedTime = 0
//        isSavingNewLearning = false
//        newLearningSaveSuccess = false
//        newLearningSessionStartTime = Date()
//    }
//    
//    /// 経過時間を更新する
//    private func updateElapsedTime() {
//        learningElapsedTime = Date().timeIntervalSince(activeRecallStartTime)
//    }
//    
//    /// セッション時間を計算する
//    private func calculateSessionDuration() -> Int {
//        if selectedLearningMethod == .recordOnly {
//            return Int(Date().timeIntervalSince(newLearningSessionStartTime))
//        } else {
//            return Int(Date().timeIntervalSince(activeRecallStartTime))
//        }
//    }
    
    /// 新規学習データの保存処理
    /// - Parameter sessionDuration: セッション時間（秒）
    private func performNewLearningDataSave(sessionDuration: Int) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            viewContext.perform {
                do {
                    // 新規メモの作成
                    let newMemo = Memo(context: self.viewContext)
                    newMemo.id = UUID()
                    newMemo.title = self.newLearningTitle
                    newMemo.pageRange = ""
                    newMemo.content = ""
                    newMemo.recallScore = self.newLearningInitialScore
                    newMemo.createdAt = Date()
                    newMemo.lastReviewedDate = Date()
                    newMemo.nextReviewDate = self.selectedNewLearningReviewDate
                    
                    // タグの関連付け
                    for tag in self.newLearningTags {
                        newMemo.addTag(tag)
                    }
                    
                    // 履歴エントリの作成
                    let historyEntry = MemoHistoryEntry(context: self.viewContext)
                    historyEntry.id = UUID()
                    historyEntry.date = Date()
                    historyEntry.recallScore = self.newLearningInitialScore
                    historyEntry.memo = newMemo
                    
                    // 学習アクティビティの記録
                    let noteText = self.createLearningNote()
                    let actualDuration = max(sessionDuration, 1)
                    
                    let _ = LearningActivity.recordActivityWithPrecision(
                        type: .exercise,
                        durationSeconds: actualDuration,
                        memo: newMemo,
                        note: noteText,
                        in: self.viewContext
                    )
                    
                    try self.viewContext.save()
                    
                    // データ更新通知の送信
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("ForceRefreshMemoData"),
                            object: nil
                        )
                    }
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// 学習ノートを作成する
    /// - Returns: 作成されたノートテキスト
    private func createLearningNote() -> String {
        if selectedLearningMethod == .recordOnly {
            return "学習記録: \(newLearningTitle) (理解度: \(newLearningInitialScore)%)"
        } else {
            return "アクティブリコール学習: \(newLearningTitle) (\(selectedLearningMethod.rawValue), 理解度: \(newLearningInitialScore)%)"
        }
    }
    
    // MARK: - Computed Properties（計算プロパティ）
    
//    /// 現在のステップタイトルを取得する
//    var currentStepTitle: String {
//        switch newLearningStep {
//        case 0: return "学習内容を入力"
//        case 1: return "学習方法を選択"
//        case 2:
//            if selectedLearningMethod == .recordOnly {
//                return "理解度の評価"
//            } else {
//                return "アクティブリコール学習"
//            }
//        case 3: return "理解度の評価"
//        case 4: return "復習日の選択"
//        case 5: return "学習記録完了"
//        default: return "新規学習フロー"
//        }
//    }
//    
//    /// 現在のステップの色を取得する
//    var currentStepColor: Color {
//        switch newLearningStep {
//        case 0: return .blue
//        case 1: return .purple
//        case 2: return selectedLearningMethod.color
//        case 3: return .orange
//        case 4: return .indigo
//        case 5: return .green
//        default: return .gray
//        }
//    }
}
