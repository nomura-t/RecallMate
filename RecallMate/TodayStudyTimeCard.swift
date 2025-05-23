// TodayStudyTimeCard.swift - 修正版
import SwiftUI
import CoreData

struct TodayStudyTimeCard: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    // 今日の学習時間（秒）
    @State private var todayStudySeconds: Int = 0
    @State private var lastRefreshed = Date()
    
    var body: some View {
        HStack(spacing: 8) {
            // 学習時間アイコン
            Image(systemName: "clock.fill")
                .foregroundColor(.blue)
                .font(.system(size: 14))
            
            // 今日の総学習時間を表示
            Text(formattedStudyTime)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
            
            // 学習完了インジケーター
            Circle()
                .fill(todayStudySeconds > 0 ? Color.green : Color.gray.opacity(0.5))
                .frame(width: 6, height: 6)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 2, x: 0, y: 1)
        )
        .onAppear {
            fetchTodaysStudyData()
        }
        // データ更新通知の監視
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshActivityData"))) { _ in
            fetchTodaysStudyData()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ForceRefreshMemoData"))) { _ in
            fetchTodaysStudyData()
        }
    }
    
    // 時間のフォーマット（時:分:秒）
    private var formattedStudyTime: String {
        let totalSeconds = todayStudySeconds
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        // 常に時:分:秒の形式で表示
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }
    
    // CoreDataから今日の学習データを取得（秒単位で直接取得）- 修正版
    private func fetchTodaysStudyData() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-1)
        
        let fetchRequest: NSFetchRequest<LearningActivity> = LearningActivity.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "date >= %@ AND date <= %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        
        do {
            let activities = try viewContext.fetch(fetchRequest)
            
            // 修正: durationInSecondsプロパティを使用
            todayStudySeconds = activities.reduce(0) { $0 + Int($1.durationInSeconds) }
            
            // 更新時刻を記録
            lastRefreshed = Date()
            
            print("📊 今日の学習時間を更新: \(formattedStudyTime) （\(activities.count)件のアクティビティ）")
            
            // デバッグ用：各アクティビティの詳細を出力
            for (index, activity) in activities.enumerated() {
                print("   アクティビティ\(index + 1): \(Int(activity.durationInSeconds))秒 (\(activity.type ?? "不明"))")
            }
            
        } catch {
            print("Error fetching today's study data: \(error)")
            todayStudySeconds = 0
        }
    }
}
