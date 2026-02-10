import Foundation
import CoreData

// LearningActivityに習慣化チャレンジ関連の拡張を追加
extension LearningActivity {
    // 既存のrecordActivity静的メソッドを拡張
    static func recordActivityWithHabitChallengeInSeconds(
        type: ActivityType,
        durationSeconds: Int,
        memo: Memo?,
        note: String? = nil,
        in context: NSManagedObjectContext
    ) -> LearningActivity {
        // 秒単位のメソッドを直接使用
        let activity = LearningActivity.recordActivityWithPrecision(
            type: type,
            durationSeconds: durationSeconds,
            memo: memo,
            note: note,
            in: context
        )
        
        
        return activity
    }
    // 指定した日付に最低5分の学習があったかをチェック
    static func hasMinimumLearningForDate(_ date: Date, in context: NSManagedObjectContext) -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = (calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay).addingTimeInterval(-1)
        
        let request: NSFetchRequest<LearningActivity> = LearningActivity.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let activities = try context.fetch(request)
            let totalMinutes = activities.reduce(0) { $0 + Int($1.durationMinutes) }
            return totalMinutes >= 5 // 5分以上あるかチェック
        } catch {
            return false
        }
    }
}
