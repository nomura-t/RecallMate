import Foundation

public struct MemoryRetentionCalculator {
    // 既存のシンプルな計算メソッド（互換性のため維持）
    public static func calculateRetentionScore(recallScore: Int16, perfectRecallCount: Int16) -> Int16 {
        let baseRetention = Double(recallScore) * 0.8
        let bonusRetention = Double(perfectRecallCount) * 5.0
        let retentionScore = min(100, baseRetention + bonusRetention)
        return Int16(retentionScore)
    }
    
    // 改善された科学的なアルゴリズム
    public static func calculateEnhancedRetentionScore(
        recallScore: Int16,         // 現在の自己評価 (0-100)
        daysSinceLastReview: Int,   // 前回復習からの経過日数
        reviewCount: Int,           // 復習回数
        highScoreCount: Int         // 高評価(80%以上)の回数
    ) -> Int16 {
        // 1. 基本記憶スコア
        let baseRetention = Double(recallScore)
        
        // 2. 忘却曲線による減衰
        let forgettingRate = 0.05 // 日々の忘却率（調整可能）
        let retentionMultiplier = exp(-forgettingRate * Double(daysSinceLastReview))
        
        // 3. 復習による強化効果
        // 復習回数が増えるほど忘却率が低下（最大75%まで低減）
        let reviewEffect = min(0.75, Double(reviewCount) * 0.15)
        
        // 4. 高評価による強化効果
        let stabilizationBonus = min(20.0, Double(highScoreCount) * 4.0)
        
        // 5. 総合計算：基本記憶に忘却と強化を適用
        let decayedScore = baseRetention * (retentionMultiplier + reviewEffect)
        let finalScore = min(100, decayedScore + stabilizationBonus)
        
        return Int16(max(0, finalScore))
    }
    
    // ヘルパーメソッド
    public static func countHighScores(historyEntries: [MemoHistoryEntry]) -> Int {
        return historyEntries.filter { $0.recallScore >= 80 }.count
    }
    
    public static func daysSinceLastReview(lastReviewDate: Date?) -> Int {
        guard let lastReview = lastReviewDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: lastReview, to: Date()).day ?? 0
    }
}
