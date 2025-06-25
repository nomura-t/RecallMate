// ReviewCalculator.swift - 修正版
import Foundation

struct ReviewCalculator {
    
    // メインの計算メソッド - より直接的なアプローチに変更
    static func calculateNextReviewDate(recallScore: Int16, lastReviewedDate: Date?, perfectRecallCount: Int16) -> Date {
        // 新規学習の場合（perfectRecallCount = 0）は、シンプルな計算を使用
        if perfectRecallCount == 0 {
            return calculateInitialReviewDate(recallScore: recallScore, lastReviewedDate: lastReviewedDate)
        }
        
        // 既存の復習の場合は、段階的計算を使用
        return calculateProgressiveNextReviewDate(
            recallScore: recallScore,
            lastReviewedDate: lastReviewedDate,
            historyEntries: []
        )
    }
    
    // 新規学習専用の初回復習日計算
    private static func calculateInitialReviewDate(recallScore: Int16, lastReviewedDate: Date?) -> Date {
        let baseDate = lastReviewedDate ?? Date()
        let calendar = Calendar.current
        
        // 理解度に基づく基本間隔（日数）
        let baseDays: Double
        switch recallScore {
        case 95...100:
            baseDays = 14.0  // 2週間
        case 85...94:
            baseDays = 10.0  // 10日
        case 75...84:
            baseDays = 7.0   // 1週間
        case 65...74:
            baseDays = 5.0   // 5日
        case 55...64:
            baseDays = 3.0   // 3日
        case 45...54:
            baseDays = 2.0   // 2日
        case 35...44:
            baseDays = 1.5   // 1.5日
        default:
            baseDays = 1.0   // 1日
        }
        
        // 理解度による微調整
        let scoreFactor: Double
        switch recallScore {
        case 90...100:
            scoreFactor = 1.2  // 20%延長
        case 80...89:
            scoreFactor = 1.1  // 10%延長
        case 70...79:
            scoreFactor = 1.0  // 基準
        case 60...69:
            scoreFactor = 0.9  // 10%短縮
        case 50...59:
            scoreFactor = 0.8  // 20%短縮
        default:
            scoreFactor = 0.7  // 30%短縮
        }
        
        let finalDays = baseDays * scoreFactor
        let daysToAdd = Int(round(finalDays))
        
        let nextDate = calendar.date(byAdding: .day, value: daysToAdd, to: baseDate) ?? baseDate
        
        return nextDate
    }
    
    // 既存の段階的計算システム（復習用）
    static func calculateProgressiveNextReviewDate(
        recallScore: Int16,
        lastReviewedDate: Date?,
        historyEntries: [MemoHistoryEntry]
    ) -> Date {
        // 既存の実装をそのまま維持
        let masteryLevel = calculateMasteryLevel(
            currentScore: recallScore,
            historyEntries: historyEntries
        )
        
        let baseInterval = getBaseIntervalForMasteryLevel(masteryLevel: masteryLevel)
        let scoreAdjustment = getScoreBasedAdjustment(recallScore: recallScore)
        let patternAdjustment = getLearningPatternAdjustment(
            currentScore: recallScore,
            historyEntries: historyEntries
        )
        
        let rawInterval = baseInterval * scoreAdjustment * patternAdjustment
        let finalInterval = applyReasonableConstraints(interval: rawInterval)
        let daysToAdd = Int(round(finalInterval))
        
        let calendar = Calendar.current
        let nextDate = calendar.date(
            byAdding: .day,
            value: daysToAdd,
            to: lastReviewedDate ?? Date()
        ) ?? Date()
        
        return nextDate
    }
    
    // 既存のヘルパーメソッドは変更なし
    private static func calculateMasteryLevel(
        currentScore: Int16,
        historyEntries: [MemoHistoryEntry]
    ) -> Int {
        var masteryPoints = 0
        
        switch currentScore {
        case 90...100:
            masteryPoints += 8
        case 80...89:
            masteryPoints += 6
        case 70...79:
            masteryPoints += 4
        case 60...69:
            masteryPoints += 2
        case 50...59:
            masteryPoints += 1
        default:
            masteryPoints += 0
        }
        
        if !historyEntries.isEmpty {
            let historicalPoints = calculateHistoricalProgress(historyEntries: historyEntries)
            masteryPoints += historicalPoints
            
            let consistencyPoints = calculateConsistencyPoints(historyEntries: historyEntries)
            masteryPoints += consistencyPoints
            
            let improvementPoints = calculateImprovementPoints(
                currentScore: currentScore,
                historyEntries: historyEntries
            )
            masteryPoints += improvementPoints
        }
        
        let masteryLevel = max(0, min(12, masteryPoints))
        return masteryLevel
    }
    
    // 残りのヘルパーメソッドは既存のまま保持
    private static func calculateHistoricalProgress(historyEntries: [MemoHistoryEntry]) -> Int {
        var points = 0
        
        let excellentCount = historyEntries.filter { $0.recallScore >= 85 }.count
        let goodCount = historyEntries.filter { $0.recallScore >= 70 }.count
        let fairCount = historyEntries.filter { $0.recallScore >= 55 }.count
        
        points += excellentCount * 2
        points += goodCount * 1
        points += fairCount / 2
        
        return min(points, 6)
    }
    
    private static func calculateConsistencyPoints(historyEntries: [MemoHistoryEntry]) -> Int {
        guard historyEntries.count >= 3 else { return 0 }
        
        let recentScores = Array(historyEntries.prefix(5).map { $0.recallScore })
        let average = Double(recentScores.reduce(0, +)) / Double(recentScores.count)
        
        if average >= 70 {
            return 2
        } else if average >= 55 {
            return 1
        } else {
            return 0
        }
    }
    
    private static func calculateImprovementPoints(
        currentScore: Int16,
        historyEntries: [MemoHistoryEntry]
    ) -> Int {
        guard historyEntries.count >= 2 else { return 0 }
        
        let recentEntries = Array(historyEntries.prefix(3))
        let recentAverage = Double(recentEntries.reduce(0) { $0 + Int($1.recallScore) }) / Double(recentEntries.count)
        let improvement = Double(currentScore) - recentAverage
        
        switch improvement {
        case 10...:
            return 3
        case 5...9:
            return 2
        case 0...4:
            return 1
        default:
            return 0
        }
    }
    
    private static func getBaseIntervalForMasteryLevel(masteryLevel: Int) -> Double {
        let masteryIntervals: [Double] = [
            1.0, 1.5, 2.5, 4.0, 6.0, 9.0, 13.0, 20.0, 30.0, 45.0, 65.0, 90.0, 120.0
        ]
        
        let safeLevel = max(0, min(masteryLevel, masteryIntervals.count - 1))
        return masteryIntervals[safeLevel]
    }
    
    private static func getScoreBasedAdjustment(recallScore: Int16) -> Double {
        switch recallScore {
        case 95...100: return 1.3
        case 85...94:  return 1.2
        case 75...84:  return 1.1
        case 65...74:  return 1.05
        case 55...64:  return 1.0
        case 45...54:  return 0.95
        case 35...44:  return 0.9
        default:       return 0.8
        }
    }
    
    private static func getLearningPatternAdjustment(
        currentScore: Int16,
        historyEntries: [MemoHistoryEntry]
    ) -> Double {
        guard !historyEntries.isEmpty else { return 1.0 }
        
        let recentEntries = Array(historyEntries.prefix(3))
        
        if recentEntries.allSatisfy({ $0.recallScore >= 65 }) {
            return 1.1
        } else if recentEntries.count >= 2 && recentEntries.allSatisfy({ $0.recallScore >= 50 }) {
            return 1.05
        } else {
            return 1.0
        }
    }
    
    private static func applyReasonableConstraints(interval: Double) -> Double {
        return max(1.0, min(365.0, interval))
    }
}
