import Foundation

struct ReviewCalculator {
    
    // メインの計算メソッド - perfectRecallCountシステムを完全に削除
    static func calculateNextReviewDate(recallScore: Int16, lastReviewedDate: Date?, perfectRecallCount: Int16) -> Date {
        // perfectRecallCountパラメータは後方互換性のためだけに保持し、実際は使用しない
        return calculateProgressiveNextReviewDate(
            recallScore: recallScore,
            lastReviewedDate: lastReviewedDate,
            historyEntries: [] // 履歴が利用できない場合の基本計算
        )
    }
    
    // 新しい段階的計算システムのメインメソッド
    static func calculateProgressiveNextReviewDate(
        recallScore: Int16,
        lastReviewedDate: Date?,
        historyEntries: [MemoHistoryEntry]
    ) -> Date {
        print("🎯 段階的復習計算システムを開始")
        print("   現在の記憶度: \(recallScore)%")
        print("   履歴エントリ数: \(historyEntries.count)")
        
        // ステップ1: 学習熟達レベルの計算
        // これは従来のperfectRecallCountに代わる、より柔軟な進歩指標です
        let masteryLevel = calculateMasteryLevel(
            currentScore: recallScore,
            historyEntries: historyEntries
        )
        
        print("   計算された熟達レベル: \(masteryLevel)")
        
        // ステップ2: 熟達レベルに基づく基本間隔の決定
        let baseInterval = getBaseIntervalForMasteryLevel(masteryLevel: masteryLevel)
        print("   基本復習間隔: \(baseInterval)日")
        
        // ステップ3: 現在の記憶度による微調整
        let scoreAdjustment = getScoreBasedAdjustment(recallScore: recallScore)
        print("   記憶度による調整係数: \(scoreAdjustment)")
        
        // ステップ4: 学習パターンによる追加調整
        let patternAdjustment = getLearningPatternAdjustment(
            currentScore: recallScore,
            historyEntries: historyEntries
        )
        print("   学習パターン調整係数: \(patternAdjustment)")
        
        // ステップ5: 最終計算と制約適用
        let rawInterval = baseInterval * scoreAdjustment * patternAdjustment
        let finalInterval = applyReasonableConstraints(interval: rawInterval)
        let daysToAdd = Int(round(finalInterval)) // 四捨五入で正確な日数を決定
        
        print("   最終計算: \(baseInterval) × \(scoreAdjustment) × \(patternAdjustment) = \(rawInterval)")
        print("   制約適用後: \(finalInterval)日")
        print("   実際の追加日数: \(daysToAdd)日")
        
        // ステップ6: 次回復習日の算出
        let calendar = Calendar.current
        let nextDate = calendar.date(
            byAdding: .day,
            value: daysToAdd,
            to: lastReviewedDate ?? Date()
        ) ?? Date()
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        print("   次回復習日: \(formatter.string(from: nextDate))")
        
        return nextDate
    }
    
    // 学習熟達レベルの計算 - perfectRecallCountの完全な代替
    // この関数は学習者の成長を段階的に評価し、小さな進歩も適切に認識します
    private static func calculateMasteryLevel(
        currentScore: Int16,
        historyEntries: [MemoHistoryEntry]
    ) -> Int {
        var masteryPoints = 0
        
        // 現在の記憶度に基づく基礎ポイント
        // この段階的な評価により、73%のような成績も適切に価値付けされます
        switch currentScore {
        case 90...100:
            masteryPoints += 8  // 優秀レベル
        case 80...89:
            masteryPoints += 6  // 良好レベル
        case 70...79:
            masteryPoints += 4  // 及第レベル（73%はここに該当）
        case 60...69:
            masteryPoints += 2  // 基本レベル
        case 50...59:
            masteryPoints += 1  // 入門レベル
        default:
            masteryPoints += 0  // 要努力レベル
        }
        
        // 履歴がある場合の追加評価
        if !historyEntries.isEmpty {
            // 過去の成績による累積ポイント
            let historicalPoints = calculateHistoricalProgress(historyEntries: historyEntries)
            masteryPoints += historicalPoints
            
            // 一貫性による追加ポイント
            let consistencyPoints = calculateConsistencyPoints(historyEntries: historyEntries)
            masteryPoints += consistencyPoints
            
            // 改善傾向による追加ポイント
            let improvementPoints = calculateImprovementPoints(
                currentScore: currentScore,
                historyEntries: historyEntries
            )
            masteryPoints += improvementPoints
        }
        
        // 熟達レベルの決定（0-12の範囲）
        let masteryLevel = max(0, min(12, masteryPoints))
        
        print("     熟達レベル詳細:")
        print("       現在スコアポイント: \(masteryPoints)")
        print("       最終熟達レベル: \(masteryLevel)")
        
        return masteryLevel
    }
    
    // 過去の成績による累積進歩の評価
    private static func calculateHistoricalProgress(historyEntries: [MemoHistoryEntry]) -> Int {
        var points = 0
        
        // 各成績レベルでの学習経験を評価
        let excellentCount = historyEntries.filter { $0.recallScore >= 85 }.count
        let goodCount = historyEntries.filter { $0.recallScore >= 70 }.count
        let fairCount = historyEntries.filter { $0.recallScore >= 55 }.count
        
        // 段階的なポイント付与
        points += excellentCount * 2  // 優秀な成績は高く評価
        points += goodCount * 1       // 良好な成績も適切に評価
        points += fairCount / 2       // 及第点の成績も無視しない
        
        return min(points, 6) // 最大6ポイントに制限
    }
    
    // 学習の一貫性による追加ポイント
    private static func calculateConsistencyPoints(historyEntries: [MemoHistoryEntry]) -> Int {
        guard historyEntries.count >= 3 else { return 0 }
        
        let recentScores = Array(historyEntries.prefix(5).map { $0.recallScore })
        let average = Double(recentScores.reduce(0, +)) / Double(recentScores.count)
        
        // 一貫して良好な成績を維持している場合のボーナス
        if average >= 70 {
            return 2
        } else if average >= 55 {
            return 1
        } else {
            return 0
        }
    }
    
    // 改善傾向による追加ポイント
    private static func calculateImprovementPoints(
        currentScore: Int16,
        historyEntries: [MemoHistoryEntry]
    ) -> Int {
        guard historyEntries.count >= 2 else { return 0 }
        
        // 最近3回の平均と現在のスコアを比較
        let recentEntries = Array(historyEntries.prefix(3))
        let recentAverage = Double(recentEntries.reduce(0) { $0 + Int($1.recallScore) }) / Double(recentEntries.count)
        let improvement = Double(currentScore) - recentAverage
        
        // 改善度に応じたポイント付与
        switch improvement {
        case 10...:
            return 3  // 大幅改善
        case 5...9:
            return 2  // 明確な改善
        case 0...4:
            return 1  // 維持・軽微改善
        default:
            return 0  // 改善なしまたは低下
        }
    }
    
    // 熟達レベルに基づく基本間隔の決定
    // この関数は学習の段階に応じて、科学的根拠に基づいた復習間隔を提供します
    private static func getBaseIntervalForMasteryLevel(masteryLevel: Int) -> Double {
        // 段階的な間隔システム - 従来のbaseIntervalsよりも柔軟
        let masteryIntervals: [Double] = [
            1.0,   // レベル0: 1日（初心者）
            1.5,   // レベル1: 1.5日
            2.5,   // レベル2: 2.5日
            4.0,   // レベル3: 4日
            6.0,   // レベル4: 6日
            9.0,   // レベル5: 9日
            13.0,  // レベル6: 13日
            20.0,  // レベル7: 20日
            30.0,  // レベル8: 30日
            45.0,  // レベル9: 45日
            65.0,  // レベル10: 65日
            90.0,  // レベル11: 90日
            120.0  // レベル12: 120日（マスターレベル）
        ]
        
        let safeLevel = max(0, min(masteryLevel, masteryIntervals.count - 1))
        return masteryIntervals[safeLevel]
    }
    
    // 現在の記憶度による微調整
    private static func getScoreBasedAdjustment(recallScore: Int16) -> Double {
        // より細かい調整により、記憶度の微細な違いも反映
        switch recallScore {
        case 95...100: return 1.3
        case 85...94:  return 1.2
        case 75...84:  return 1.1  // 73%もここで適切に評価される
        case 65...74:  return 1.05
        case 55...64:  return 1.0
        case 45...54:  return 0.95
        case 35...44:  return 0.9
        default:       return 0.8
        }
    }
    
    // 学習パターンの分析による調整
    private static func getLearningPatternAdjustment(
        currentScore: Int16,
        historyEntries: [MemoHistoryEntry]
    ) -> Double {
        guard !historyEntries.isEmpty else { return 1.0 }
        
        // 最近の学習頻度を分析
        let recentEntries = Array(historyEntries.prefix(3))
        
        // 安定した成績パターンにボーナスを提供
        if recentEntries.allSatisfy({ $0.recallScore >= 65 }) {
            return 1.1  // 安定した良好な成績
        } else if recentEntries.count >= 2 && recentEntries.allSatisfy({ $0.recallScore >= 50 }) {
            return 1.05 // 安定した基本的な成績
        } else {
            return 1.0  // 標準的な調整
        }
    }
    
    // 実用的な制約の適用
    private static func applyReasonableConstraints(interval: Double) -> Double {
        // 学習効果を最大化するための実用的な制約
        return max(1.0, min(365.0, interval))
    }
}
