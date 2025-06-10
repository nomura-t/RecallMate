// HomeView/NewLearningFlowViewModel.swift
import Foundation
import SwiftUI
import CoreData

/// 新規学習フローの状態管理とビジネスロジックを担当するViewModel
///
/// 復習フローと似た構造を持ちますが、新規学習特有の処理を含みます：
/// - タグ選択管理
/// - 初期理解度評価
/// - 新規メモ作成
class NewLearningFlowViewModel: ObservableObject {
    // MARK: - Published Properties（UI状態）
    @Published var showingNewLearningFlow = false
    @Published var newLearningStep: Int = 0
    @Published var newLearningTitle = ""
    @Published var newLearningTags: [Tag] = []
    @Published var newLearningInitialScore: Int16 = 70
    @Published var selectedLearningMethod: LearningMethod = .thorough
    @Published var selectedNewLearningReviewDate: Date = Date()
    @Published var defaultNewLearningReviewDate: Date = Date()
    @Published var activeRecallStep: Int = 0
    @Published var learningElapsedTime: TimeInterval = 0
    @Published var isSavingNewLearning = false
    @Published var newLearningSaveSuccess = false
    var activeRecallStartTime = Date()
    // MARK: - Private Properties（内部状態）
    private var newLearningSessionStartTime = Date()
    
    private var learningTimer: Timer?
    private let viewContext: NSManagedObjectContext
    
    // MARK: - Initialization
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    // MARK: - Public Methods（外部インターフェース）
    
    /// 新規学習フローを開始する
    func startNewLearning() {
        resetFlowState()
        showingNewLearningFlow = true
    }
    
    /// 新規学習フローを終了する
    func closeNewLearningFlow() {
        stopLearningTimer()
        resetFlowState()
        showingNewLearningFlow = false
    }
    
    /// 次のステップに進む
    func proceedToNextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            newLearningStep += 1
        }
    }
    
    /// 特定のステップにジャンプする
    /// - Parameter step: 移動先のステップ番号
    func jumpToStep(_ step: Int) {
        withAnimation(.easeInOut(duration: 0.3)) {
            newLearningStep = step
        }
    }
    
    /// タグの選択状態をトグルする
    /// - Parameter tag: 対象のタグ
    func toggleTag(_ tag: Tag) {
        if newLearningTags.contains(where: { $0.id == tag.id }) {
            removeTag(tag)
        } else {
            newLearningTags.append(tag)
        }
    }
    
    /// タグを削除する
    /// - Parameter tag: 削除するタグ
    func removeTag(_ tag: Tag) {
        if let index = newLearningTags.firstIndex(where: { $0.id == tag.id }) {
            newLearningTags.remove(at: index)
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
            print("新規学習完了処理でエラーが発生しました: \(error)")
        }
    }
    
    // MARK: - Timer Management（タイマー管理）
    
    /// 学習タイマーを開始する
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
    
    /// 学習タイマーを停止する
    func stopLearningTimer() {
        learningTimer?.invalidate()
        learningTimer = nil
    }
    
    // MARK: - Validation（バリデーション）
    
    /// 入力内容が有効かどうかを確認する
    var isInputValid: Bool {
        return !newLearningTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Private Methods（内部処理）
    
    /// フロー状態をリセットする
    private func resetFlowState() {
        newLearningStep = 0
        newLearningTitle = ""
        newLearningTags = []
        newLearningInitialScore = 70
        selectedLearningMethod = .thorough
        activeRecallStep = 0
        learningElapsedTime = 0
        isSavingNewLearning = false
        newLearningSaveSuccess = false
        newLearningSessionStartTime = Date()
    }
    
    /// 経過時間を更新する
    private func updateElapsedTime() {
        learningElapsedTime = Date().timeIntervalSince(activeRecallStartTime)
    }
    
    /// セッション時間を計算する
    private func calculateSessionDuration() -> Int {
        if selectedLearningMethod == .recordOnly {
            return Int(Date().timeIntervalSince(newLearningSessionStartTime))
        } else {
            return Int(Date().timeIntervalSince(activeRecallStartTime))
        }
    }
    
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
    
    /// 現在のステップタイトルを取得する
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
    
    /// 現在のステップの色を取得する
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
}
