import Foundation
import CoreData

// MARK: - Study Stats Calculator
class StudyStatsCalculator {
    static func calculateStats() async -> UserStudyStats {
        let context = PersistenceController.shared.container.viewContext
        
        // 総学習時間を計算
        let totalMinutes = await calculateTotalStudyTime(context: context)
        
        // 今週の学習時間を計算
        let thisWeekMinutes = await calculateThisWeekStudyTime(context: context)
        
        // 連続学習日数を計算
        let streakDays = await calculateStreakDays(context: context)
        
        return UserStudyStats(
            totalMinutes: totalMinutes,
            thisWeekMinutes: thisWeekMinutes,
            streakDays: streakDays
        )
    }
    
    // MARK: - Private Methods
    
    private static func calculateTotalStudyTime(context: NSManagedObjectContext) async -> Int {
        return await withCheckedContinuation { continuation in
            context.perform {
                let request: NSFetchRequest<LearningActivity> = LearningActivity.fetchRequest()
                
                do {
                    let activities = try context.fetch(request)
                    let totalMinutes = activities.reduce(0) { total, activity in
                        return total + Int(activity.durationMinutes)
                    }
                    continuation.resume(returning: totalMinutes)
                } catch {
                    print("総学習時間計算エラー: \\(error)")
                    continuation.resume(returning: 0)
                }
            }
        }
    }
    
    private static func calculateThisWeekStudyTime(context: NSManagedObjectContext) async -> Int {
        return await withCheckedContinuation { continuation in
            context.perform {
                let request: NSFetchRequest<LearningActivity> = LearningActivity.fetchRequest()
                
                // 今週の開始日を取得
                let calendar = Calendar.current
                let now = Date()
                let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
                
                request.predicate = NSPredicate(format: "date >= %@", weekStart as NSDate)
                
                do {
                    let activities = try context.fetch(request)
                    let thisWeekMinutes = activities.reduce(0) { total, activity in
                        return total + Int(activity.durationMinutes)
                    }
                    continuation.resume(returning: thisWeekMinutes)
                } catch {
                    print("今週の学習時間計算エラー: \\(error)")
                    continuation.resume(returning: 0)
                }
            }
        }
    }
    
    private static func calculateStreakDays(context: NSManagedObjectContext) async -> Int {
        return await withCheckedContinuation { continuation in
            context.perform {
                let request: NSFetchRequest<LearningActivity> = LearningActivity.fetchRequest()
                request.sortDescriptors = [NSSortDescriptor(keyPath: \LearningActivity.date, ascending: false)]
                
                do {
                    let activities = try context.fetch(request)
                    
                    // 日付ごとに学習記録をグループ化
                    let calendar = Calendar.current
                    var studyDates: Set<Date> = []
                    
                    for activity in activities {
                        let dayStart = calendar.startOfDay(for: activity.date ?? Date())
                        studyDates.insert(dayStart)
                    }
                    
                    // 連続日数を計算
                    let sortedDates = studyDates.sorted(by: >)
                    var streakDays = 0
                    var currentDate = calendar.startOfDay(for: Date())
                    
                    for date in sortedDates {
                        if calendar.isDate(date, inSameDayAs: currentDate) {
                            streakDays += 1
                            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
                        } else if calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate) {
                            streakDays += 1
                            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
                        } else {
                            break
                        }
                    }
                    
                    continuation.resume(returning: streakDays)
                } catch {
                    print("連続学習日数計算エラー: \\(error)")
                    continuation.resume(returning: 0)
                }
            }
        }
    }
    
    // MARK: - Study Session Stats
    
    static func calculateSessionStats() async -> DailySessionStats {
        let context = PersistenceController.shared.container.viewContext
        
        return await withCheckedContinuation { continuation in
            context.perform {
                let request: NSFetchRequest<LearningActivity> = LearningActivity.fetchRequest()
                
                // 今日の学習記録を取得
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
                
                request.predicate = NSPredicate(format: "date >= %@ AND date < %@", today as NSDate, tomorrow as NSDate)
                
                do {
                    let todayActivities = try context.fetch(request)
                    
                    // 今日の統計
                    let todayReviewCount = todayActivities.count
                    let todayStudyMinutes = todayActivities.reduce(0) { total, activity in
                        return total + Int(activity.durationMinutes)
                    }
                    
                    // 今日の復習率計算
                    let memoRequest: NSFetchRequest<Memo> = Memo.fetchRequest()
                    memoRequest.predicate = NSPredicate(format: "nextReviewDate <= %@", Date() as NSDate)
                    
                    let dueMemos = try context.fetch(memoRequest)
                    let reviewRate = dueMemos.count > 0 ? Double(todayReviewCount) / Double(dueMemos.count) : 0.0
                    
                    let sessionStats = DailySessionStats(
                        todayReviewCount: todayReviewCount,
                        todayStudyMinutes: todayStudyMinutes,
                        reviewRate: reviewRate,
                        pendingReviewCount: dueMemos.count - todayReviewCount
                    )
                    
                    continuation.resume(returning: sessionStats)
                } catch {
                    print("セッション統計計算エラー: \\(error)")
                    continuation.resume(returning: DailySessionStats(
                        todayReviewCount: 0,
                        todayStudyMinutes: 0,
                        reviewRate: 0.0,
                        pendingReviewCount: 0
                    ))
                }
            }
        }
    }
    
    // MARK: - Weekly Stats
    
    static func calculateWeeklyStats() async -> WeeklyStats {
        let context = PersistenceController.shared.container.viewContext
        
        return await withCheckedContinuation { continuation in
            context.perform {
                let request: NSFetchRequest<LearningActivity> = LearningActivity.fetchRequest()
                
                let calendar = Calendar.current
                let now = Date()
                let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
                
                request.predicate = NSPredicate(format: "date >= %@", weekStart as NSDate)
                request.sortDescriptors = [NSSortDescriptor(keyPath: \LearningActivity.date, ascending: true)]
                
                do {
                    let weekActivities = try context.fetch(request)
                    
                    // 日別データを作成
                    var dailyData: [DailyStudyData] = []
                    
                    for i in 0..<7 {
                        let date = calendar.date(byAdding: .day, value: i, to: weekStart) ?? weekStart
                        let dayStart = calendar.startOfDay(for: date)
                        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
                        
                        let dayActivities = weekActivities.filter { activity in
                            guard let activityDate = activity.date else { return false }
                            return activityDate >= dayStart && activityDate < dayEnd
                        }
                        
                        let dayData = DailyStudyData(
                            date: date,
                            reviewCount: dayActivities.count,
                            studyMinutes: dayActivities.reduce(0) { total, activity in
                                return total + Int(activity.durationMinutes)
                            }
                        )
                        
                        dailyData.append(dayData)
                    }
                    
                    let totalMinutes = weekActivities.reduce(0) { total, activity in
                        return total + Int(activity.durationMinutes)
                    }
                    
                    let weeklyStats = WeeklyStats(
                        weekStart: weekStart,
                        dailyData: dailyData,
                        totalReviews: weekActivities.count,
                        totalMinutes: totalMinutes,
                        averageDaily: weekActivities.count / 7
                    )
                    
                    continuation.resume(returning: weeklyStats)
                } catch {
                    print("週次統計計算エラー: \\(error)")
                    continuation.resume(returning: WeeklyStats(
                        weekStart: weekStart,
                        dailyData: [],
                        totalReviews: 0,
                        totalMinutes: 0,
                        averageDaily: 0
                    ))
                }
            }
        }
    }
}

// MARK: - User Study Stats Model

struct UserStudyStats {
    let totalMinutes: Int
    let thisWeekMinutes: Int
    let streakDays: Int
}

// MARK: - Additional Stats Models

struct DailySessionStats {
    let todayReviewCount: Int
    let todayStudyMinutes: Int
    let reviewRate: Double
    let pendingReviewCount: Int
}

struct WeeklyStats {
    let weekStart: Date
    let dailyData: [DailyStudyData]
    let totalReviews: Int
    let totalMinutes: Int
    let averageDaily: Int
}

struct DailyStudyData {
    let date: Date
    let reviewCount: Int
    let studyMinutes: Int
}

