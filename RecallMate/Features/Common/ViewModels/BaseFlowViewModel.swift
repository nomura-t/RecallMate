import Foundation
import SwiftUI
import CoreData

/// フロー共通のベースViewModel
/// 復習フローと新規学習フローの共通機能を提供
class BaseFlowViewModel: ObservableObject {
    // MARK: - Published Properties（UI状態）
    @Published var showingFlow = false
    @Published var currentStep: Int = 0
    @Published var isSaving = false
    @Published var saveSuccess = false
    @Published var elapsedTime: TimeInterval = 0
    
    // MARK: - Properties（内部状態）
    var sessionStartTime = Date()
    var activeStartTime = Date()
    private var timer: Timer?
    let viewContext: NSManagedObjectContext
    
    // MARK: - Initialization
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    // MARK: - Public Methods（外部インターフェース）
    
    /// フローを開始する
    func startFlow() {
        resetFlowState()
        showingFlow = true
    }
    
    /// フローを終了する
    func closeFlow() {
        stopTimer()
        resetFlowState()
        showingFlow = false
    }
    
    /// 次のステップに進む
    func proceedToNextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep += 1
        }
    }
    
    /// 特定のステップにジャンプする
    func jumpToStep(_ step: Int) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = step
        }
    }
    
    // MARK: - Timer Management（タイマー管理）
    
    /// タイマーを開始する
    func startTimer() {
        activeStartTime = Date()
        elapsedTime = 0
        
        stopTimer()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateElapsedTime()
        }
        
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    /// タイマーを停止する
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Protected Methods（サブクラス用）
    
    /// フロー状態をリセットする（サブクラスでオーバーライド可能）
    func resetFlowState() {
        currentStep = 0
        elapsedTime = 0
        isSaving = false
        saveSuccess = false
        sessionStartTime = Date()
    }
    
    /// 経過時間を更新する
    private func updateElapsedTime() {
        elapsedTime = Date().timeIntervalSince(activeStartTime)
    }
    
    /// セッション時間を計算する
    func calculateSessionDuration() -> Int {
        return Int(Date().timeIntervalSince(sessionStartTime))
    }
}