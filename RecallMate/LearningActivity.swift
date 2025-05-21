import Foundation
import CoreData
import SwiftUI


// 学習活動タイプの列挙型
// 学習活動タイプの列挙型
enum ActivityType: String, CaseIterable, Identifiable {
    case reading = "読書"
    case exercise = "問題演習"
    case lecture = "講義視聴"
    case test = "テスト"
    case project = "プロジェクト"
    case experiment = "実験/実習"
    case review = "復習"
    case other = "その他"
    
    var id: String { self.rawValue }
    
    // アイコン名
    var iconName: String {
        switch self {
        case .reading: return "book.fill"
        case .exercise: return "doc.badge.plus" // 新規記録作成用アイコンに変更
        case .lecture: return "tv.fill"
        case .test: return "checkmark.square.fill"
        case .project: return "folder.fill"
        case .experiment: return "atom"
        case .review: return "arrow.counterclockwise"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    // 活動の色
    var color: String {
        switch self {
        case .reading: return "blue"
        case .exercise: return "green"
        case .lecture: return "purple"
        case .test: return "red"
        case .project: return "orange"
        case .experiment: return "teal"
        case .review: return "lightBlue"
        case .other: return "gray"
        }
    }
}

// CoreDataの拡張：学習活動を記録するエンティティ
extension LearningActivity {    
    // 指定期間の活動を取得
    static func fetchActivities(
        from startDate: Date,
        to endDate: Date,
        in context: NSManagedObjectContext
    ) -> [LearningActivity] {
        let request: NSFetchRequest<LearningActivity> = LearningActivity.fetchRequest()
        
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.year, .month, .day], from: startDate)
        let endComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: endDate)
        
        guard let normalizedStartDate = calendar.date(from: startComponents),
              var normalizedEndDate = calendar.date(from: endComponents) else {
            return []
        }
        
        // 終日を含めるため、終了日の最後の瞬間まで含める
        normalizedEndDate = calendar.date(byAdding: .day, value: 1, to: normalizedEndDate) ?? normalizedEndDate
        
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", normalizedStartDate as NSDate, normalizedEndDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \LearningActivity.date, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }
    
    // 特定の日の活動レベルを計算
    static func calculateActivityLevel(
        for date: Date,
        in context: NSManagedObjectContext
    ) -> Int {
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.year, .month, .day], from: date)
        
        guard let startDate = calendar.date(from: startComponents),
              let endDate = calendar.date(byAdding: .day, value: 1, to: startDate) else {
            return 0
        }
        
        let activities = fetchActivities(from: startDate, to: endDate, in: context)
        
        // 累計学習時間（分）
        let totalMinutes = activities.reduce(0) { $0 + Int($1.durationMinutes) }
        
        // 活動レベルの計算（例: 0分=0, 1-30分=1, 31-60分=2, 61-120分=3, 120分超=4）
        switch totalMinutes {
        case 0:
            return 0
        case 1...30:
            return 1
        case 31...60:
            return 2
        case 61...120:
            return 3
        default:
            return 4
        }
    }
    
    // 特定の期間の活動データを取得（ヒートマップ用）
    static func getActivityHeatmapData(
        year: Int,
        in context: NSManagedObjectContext
    ) -> [Date: Int] {
        let calendar = Calendar.current
        
        guard let startDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let endDate = calendar.date(from: DateComponents(year: year, month: 12, day: 31)) else {
            return [:]
        }
        
        var result: [Date: Int] = [:]
        var currentDate = startDate
        
        while currentDate <= endDate {
            let level = calculateActivityLevel(for: currentDate, in: context)
            
            // 日付の時間部分を正規化
            let components = calendar.dateComponents([.year, .month, .day], from: currentDate)
            if let normalizedDate = calendar.date(from: components) {
                result[normalizedDate] = level
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return result
    }
    
    // 活動タイプ別の学習時間分布を取得
    static func getActivityTypeDistribution(
        from startDate: Date,
        to endDate: Date,
        in context: NSManagedObjectContext
    ) -> [(ActivityType, Double)] {
        let activities = fetchActivities(from: startDate, to: endDate, in: context)
        let totalMinutes = activities.reduce(0) { $0 + Int($1.durationMinutes) }
        
        guard totalMinutes > 0 else { return [] }
        
        var typeMinutes: [String: Int] = [:]
        
        // 各タイプの累計時間を集計
        for activity in activities {
            if let type = activity.type {
                typeMinutes[type] = (typeMinutes[type] ?? 0) + Int(activity.durationMinutes)
            }
        }
        
        // 比率に変換
        var result: [(ActivityType, Double)] = []
        for type in ActivityType.allCases {
            let minutes = typeMinutes[type.rawValue] ?? 0
            let ratio = Double(minutes) / Double(totalMinutes)
            result.append((type, ratio))
        }
        
        // 比率の降順でソート
        return result.sorted { $0.1 > $1.1 }
    }
}
