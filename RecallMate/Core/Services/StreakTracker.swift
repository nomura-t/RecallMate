// StreakTracker.swift
import Foundation
import CoreData

class StreakTracker {
    static let shared = StreakTracker()
    
    private init() {}
    
    func checkAndUpdateStreak(in context: NSManagedObjectContext) {
        // StreakData が存在しなければ作成
        let fetchRequest = NSFetchRequest<StreakData>(entityName: "StreakData")
        
        do {
            let results = try context.fetch(fetchRequest)
            let streakData: StreakData
            
            if let existingData = results.first {
                streakData = existingData
            } else {
                streakData = StreakData(context: context)
                streakData.currentStreak = 1
                streakData.longestStreak = 1
                streakData.lastActiveDate = Date()
                streakData.streakStartDate = Date()
                try context.save()
                return
            }
            
            // 最後のアクティブ日を取得
            guard let lastActiveDate = streakData.lastActiveDate else {
                streakData.lastActiveDate = Date()
                try context.save()
                return
            }
            
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let lastActive = calendar.startOfDay(for: lastActiveDate)
            
            // 日数差を計算
            if let dayDifference = calendar.dateComponents([.day], from: lastActive, to: today).day {
                if dayDifference == 0 {
                    // 同じ日なら何もしない
                    return
                } else if dayDifference == 1 {
                    // 連続日であれば、ストリークを増加
                    streakData.currentStreak += 1
                    // 最長ストリークを更新
                    if streakData.currentStreak > streakData.longestStreak {
                        streakData.longestStreak = streakData.currentStreak
                    }
                } else {
                    // 1日以上空いた場合、ストリークをリセット
                    streakData.currentStreak = 1
                    streakData.streakStartDate = today
                }
                
                streakData.lastActiveDate = Date()
                try context.save()
            }
        } catch {
        }
    }
}
