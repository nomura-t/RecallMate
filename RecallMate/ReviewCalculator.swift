import Foundation

struct ReviewCalculator {
    static func calculateNextReviewDate(recallScore: Int16, lastReviewedDate: Date?, perfectRecallCount: Int16) -> Date {
        let baseIntervals: [Double] = [1, 3, 7, 14, 30, 60, 120]
        
        // 修正1: scoreFactorの計算を逆転
        // 記憶度が高いほど係数を大きくする (0.5〜1.5の範囲)
        let scoreFactor = 0.5 + (Double(recallScore) / 100.0)
        
        // 復習係数は完璧回数に基づく
        let reviewMultiplier = max(1.0, Double(perfectRecallCount))
        let daysUntilNextReview: Double
        
        if perfectRecallCount < baseIntervals.count {
            // 基本間隔を使用
            let baseInterval = baseIntervals[Int(perfectRecallCount)]
            daysUntilNextReview = baseInterval * scoreFactor
        } else {
            // 修正2: 完璧回数が多い場合は週単位で増加
            let baseInterval = max(30.0, Double(perfectRecallCount) * 7.0)
            daysUntilNextReview = baseInterval * scoreFactor
        }
        
        let calendar = Calendar.current
        let nextDate = calendar.date(byAdding: .day, value: Int(daysUntilNextReview), to: lastReviewedDate ?? Date())!
        
        // 計算結果をログ出力
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return nextDate
    }
}
