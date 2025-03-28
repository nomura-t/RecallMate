import Foundation

struct TestDateReviewer {
    // テスト日に向けた最適な復習スケジュールを計算
    static func calculateOptimalReviewSchedule(
        targetDate: Date,      // テスト日
        currentRecallScore: Int16,  // 現在の記憶度
        lastReviewedDate: Date,     // 最後に復習した日
        perfectRecallCount: Int16   // 完璧に覚えた回数
    ) -> [Date] {
        let calendar = Calendar.current
        let daysUntilTest = calendar.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
        
        // テスト日が過去または今日の場合
        guard daysUntilTest > 0 else {
            return [Date()]
        }
        
        // 記憶の定着レベルに基づく必要な復習回数を推定
        let requiredReviews = estimateRequiredReviews(
            currentRecallScore: currentRecallScore,
            daysUntilTest: daysUntilTest,
            perfectRecallCount: perfectRecallCount
        )
        
        // 必要な復習回数がない場合
        if requiredReviews <= 0 {
            return [Date()]
        }
        
        // 最適な間隔を計算して復習日をスケジュール
        let reviewDates = scheduleReviewDates(
            requiredReviews: requiredReviews,
            daysUntilTest: daysUntilTest
        )
        
        // 結果のログ出力を追加
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        for (index, date) in reviewDates.enumerated() {
        }
        
        return reviewDates
    }
    
    // 必要な復習回数を推定
    private static func estimateRequiredReviews(
        currentRecallScore: Int16,
        daysUntilTest: Int,
        perfectRecallCount: Int16
    ) -> Int {
        // 記憶定着度が低いほど、より多くの復習が必要
        let baseReviewCount: Double
        
        if currentRecallScore >= 80 {
            // 記憶度が高い場合
            baseReviewCount = 1.0
        } else if currentRecallScore >= 50 {
            // 記憶度が中程度の場合
            baseReviewCount = 2.0
        } else {
            // 記憶度が低い場合
            baseReviewCount = 3.0
        }
        
        // 完璧に覚えた回数が多いほど、追加の復習は少なくて済む
        let experienceFactor = max(0.5, 1.0 - Double(perfectRecallCount) * 0.1)
        
        // テスト日までの日数によって調整
        let daysFactor: Double
        if daysUntilTest <= 3 {
            // テスト直前は復習回数を増やす
            daysFactor = 1.2
        } else if daysUntilTest <= 7 {
            // 1週間以内は標準
            daysFactor = 1.0
        } else {
            // 十分な時間がある場合は間隔を広げる
            daysFactor = 0.8
        }
        
        let reviewCount = baseReviewCount * experienceFactor * daysFactor
        
        // 最低1回、最大でもテスト日までの日数を超えない
        return min(daysUntilTest, max(1, Int(round(reviewCount))))
    }
    
    // 復習日のスケジュールを最適化
    private static func scheduleReviewDates(requiredReviews: Int, daysUntilTest: Int) -> [Date] {
        var reviewDates = [Date]()
        let now = Date()
        
        // 記憶の保持率が最大化されるよう、間隔を徐々に広げる（スペーシング効果）
        var intervals = calculateSpacedIntervals(reviewCount: requiredReviews, totalDays: daysUntilTest)
        
        var currentDate = now
        for interval in intervals {
            let nextReviewDate = Calendar.current.date(byAdding: .day, value: interval, to: currentDate)!
            reviewDates.append(nextReviewDate)
            currentDate = nextReviewDate
        }
        
        return reviewDates
    }
    
    // スペーシング効果を利用した間隔計算（間隔を徐々に広げる）
    private static func calculateSpacedIntervals(reviewCount: Int, totalDays: Int) -> [Int] {
        // 初期間隔を短く設定し、徐々に広げる
        // 指数関数的に間隔を広げるため、比率を計算
        let ratio = pow(Double(totalDays), 1.0 / Double(reviewCount))
        
        var intervals = [Int]()
        var cumulativeDays = 0.0
        
        for i in 0..<reviewCount {
            let nextDay = round(pow(ratio, Double(i + 1)))
            let interval = max(1, Int(nextDay - cumulativeDays))
            intervals.append(interval)
            cumulativeDays += Double(interval)
        }
        
        // 合計日数が目標日数を超えないように調整
        while intervals.reduce(0, +) > totalDays && intervals.count > 1 {
            if let maxIndex = intervals.indices.max(by: { intervals[$0] < intervals[$1] }) {
                intervals[maxIndex] -= 1
                if intervals[maxIndex] < 1 {
                    intervals.remove(at: maxIndex)
                }
            }
        }
        
        return intervals
    }
    
    // 日付フォーマット用のヘルパーメソッド
    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
