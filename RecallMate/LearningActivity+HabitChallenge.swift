import Foundation
import CoreData

// LearningActivityに習慣化チャレンジ関連の拡張を追加
extension LearningActivity {
    // 既存のrecordActivity静的メソッドを拡張
    static func recordActivityWithHabitChallenge(
        type: ActivityType,
        durationMinutes: Int,
        memo: Memo?,
        note: String? = nil,
        in context: NSManagedObjectContext
    ) -> LearningActivity {
        // 既存の実装を呼び出す
        let activity = recordActivity(
            type: type,
            durationMinutes: durationMinutes,
            memo: memo,
            note: note,
            in: context
        )
        
        // 習慣化チャレンジを更新
        HabitChallengeManager.shared.checkLearningActivity(minutes: durationMinutes, in: context)
        
        return activity
    }
    
    // 指定した日付に最低5分の学習があったかをチェック
    static func hasMinimumLearningForDate(_ date: Date, in context: NSManagedObjectContext) -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-1)
        
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
