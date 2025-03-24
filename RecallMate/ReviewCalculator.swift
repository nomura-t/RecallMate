import Foundation

struct ReviewCalculator {
    static func calculateNextReviewDate(recallScore: Int16, lastReviewedDate: Date?, perfectRecallCount: Int16) -> Date {
        let baseIntervals: [Double] = [1, 3, 7, 14, 30, 60, 120]
        
        // 修正1: scoreFactorの計算を逆転
        // 記憶度が高いほど係数を大きくする (0.5〜1.5の範囲)
        let scoreFactor = 0.5 + (Double(recallScore) / 100.0)
        
        // 復習係数は完璧回数に基づく
        let reviewMultiplier = max(1.0, Double(perfectRecallCount))
        
        print("🧮 復習間隔計算: 記憶度=\(recallScore)%, 完璧回数=\(perfectRecallCount)")
        print("  - scoreFactor = \(scoreFactor)")
        print("  - reviewMultiplier = \(reviewMultiplier)")
        
        let daysUntilNextReview: Double
        
        if perfectRecallCount < baseIntervals.count {
            // 基本間隔を使用
            let baseInterval = baseIntervals[Int(perfectRecallCount)]
            daysUntilNextReview = baseInterval * scoreFactor
            print("  - 基本間隔: \(baseInterval)日 × 記憶度係数\(scoreFactor) = \(daysUntilNextReview)日")
        } else {
            // 修正2: 完璧回数が多い場合は週単位で増加
            let baseInterval = max(30.0, Double(perfectRecallCount) * 7.0)
            daysUntilNextReview = baseInterval * scoreFactor
            print("  - 拡張間隔: \(baseInterval)日 × 記憶度係数\(scoreFactor) = \(daysUntilNextReview)日")
        }
        
        let calendar = Calendar.current
        let nextDate = calendar.date(byAdding: .day, value: Int(daysUntilNextReview), to: lastReviewedDate ?? Date())!
        
        // 計算結果をログ出力
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        print("  - 次回復習日: \(formatter.string(from: nextDate)) (\(Int(daysUntilNextReview))日後)")
        
        return nextDate
    }
}
