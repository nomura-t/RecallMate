// StreakTracker.swift
import Foundation
import CoreData

class StreakTracker {
    static let shared = StreakTracker()

    private init() {}

    /// 学習活動が実際に行われた時のみ呼び出すこと
    /// アプリ起動時には呼ばない（ストリーク水増し防止）
    func checkAndUpdateStreak(in context: NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest<StreakData>(entityName: "StreakData")

        do {
            let results = try context.fetch(fetchRequest)
            let streakData: StreakData

            if let existingData = results.first {
                streakData = existingData
            } else {
                // 初回作成: ストリーク0から開始（実際の活動で1になる）
                streakData = StreakData(context: context)
                streakData.currentStreak = 0
                streakData.longestStreak = 0
                streakData.lastActiveDate = nil
                streakData.streakStartDate = nil
                try context.save()
                // 初回作成後、この呼び出し自体が学習活動トリガーなので続行
            }

            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())

            // lastActiveDate がない場合（初めての学習活動）
            guard let lastActiveDate = streakData.lastActiveDate else {
                streakData.currentStreak = 1
                streakData.longestStreak = 1
                streakData.lastActiveDate = Date()
                streakData.streakStartDate = Date()
                try context.save()
                return
            }

            let lastActive = calendar.startOfDay(for: lastActiveDate)

            guard let dayDifference = calendar.dateComponents([.day], from: lastActive, to: today).day else {
                return
            }

            if dayDifference == 0 {
                // 同じ日: 何もしない（既にカウント済み）
                return
            } else if dayDifference == 1 {
                // 連続日: ストリーク増加
                streakData.currentStreak += 1
                if streakData.currentStreak > streakData.longestStreak {
                    streakData.longestStreak = streakData.currentStreak
                }
            } else {
                // 2日以上空いた: リセットして1から
                streakData.currentStreak = 1
                streakData.streakStartDate = today
            }

            streakData.lastActiveDate = Date()
            try context.save()
        } catch {
            print("StreakTracker: ストリーク更新に失敗 - \(error)")
        }
    }
}
