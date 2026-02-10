// StudyTimeChartView.swift
import SwiftUI
import Charts
import CoreData

struct StudyTimeChartView: View {
    let dateRange: (start: Date, end: Date)
    let periodText: String
    let selectedTab: Int
    var selectedTag: Tag?
    
    @Environment(\.managedObjectContext) private var viewContext
    
    // 日付フォーマッタ
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
    
    // 時間フォーマッタ
    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours > 0 {
            return "%d時間%d分".localizedWithFormat(hours, mins)
        } else {
            return "%d分".localizedWithInt(mins)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("学習時間推移".localized)
                    .font(.headline)
                
                Spacer()
                
                // 平均時間表示
                HStack(spacing: 4) {
                    Text("平均:".localized)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(formatMinutes(averageStudyTime))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // iOS 16以降ではChartsを使用
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(chartData, id: \.id) { item in
                        BarMark(
                            x: .value("日付", item.label),
                            y: .value("時間 (分)", item.minutes)
                        )
                        .foregroundStyle(Color.blue.gradient)
                        .cornerRadius(4)
                    }
                    
                    if !chartData.isEmpty {
                        RuleMark(y: .value("平均", averageStudyTime))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                            .foregroundStyle(Color.red)
                            .annotation(position: .top, alignment: .trailing) {
                                Text("平均: %@".localizedWithFormat(formatMinutes(averageStudyTime)))
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                    }
                }
                .frame(height: 200)
                .padding()
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            } else {
                // iOS 16未満向けの代替表示
                LegacyChartView(data: chartData, average: averageStudyTime)
                    .frame(height: 200)
                    .padding()
            }
            
            // データがない場合のメッセージ
            if chartData.isEmpty {
                Text("この期間のデータはありません".localized)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // グラフ用データモデル
    struct ChartItem: Identifiable {
        let id = UUID()
        let date: Date
        let label: String
        let minutes: Int
    }
    
    // 選択された期間に応じたチャートデータ
    private var chartData: [ChartItem] {
        // アクティビティを取得
        let activities = fetchActivities()
        
        // 期間ごとにグループ化して集計
        switch selectedTab {
        case 0: // 日間（時間帯ごと）
            return dailyChartData(activities)
        case 1: // 週間（日ごと）
            return weeklyChartData(activities)
        case 2: // 月間（日ごと）
            return monthlyChartData(activities)
        case 3: // 年間（月ごと）
            return yearlyChartData(activities)
        default:
            return []
        }
    }
    
    // 平均学習時間（分）
    private var averageStudyTime: Int {
        if chartData.isEmpty {
            return 0
        }
        
        let totalMinutes = chartData.reduce(0) { $0 + $1.minutes }
        return totalMinutes / chartData.count
    }
    
    // アクティビティデータを取得
    private func fetchActivities() -> [LearningActivity] {
        let fetchRequest: NSFetchRequest<LearningActivity> = LearningActivity.fetchRequest()
        
        // 日付によるフィルタリング
        fetchRequest.predicate = NSPredicate(
            format: "date >= %@ AND date <= %@",
            dateRange.start as NSDate,
            dateRange.end as NSDate
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \LearningActivity.date, ascending: true)]
        
        do {
            var activities = try viewContext.fetch(fetchRequest)
            
            // タグフィルタリングがある場合は追加で絞り込み
            if let selectedTag = selectedTag {
                activities = activities.filter { activity in
                    if let memo = activity.memo {
                        return memo.tagsArray.contains { $0.id == selectedTag.id }
                    }
                    return false
                }
            }
            
            return activities
        } catch {
            return []
        }
    }
    
    // 日間データ（時間帯ごと）
    private func dailyChartData(_ activities: [LearningActivity]) -> [ChartItem] {
        let calendar = Calendar.current
        
        // 3時間ごとの時間帯に分ける
        let timeSlots = [
            (start: 0, end: 3, label: "0-3h"),
            (start: 3, end: 6, label: "3-6h"),
            (start: 6, end: 9, label: "6-9h"),
            (start: 9, end: 12, label: "9-12h"),
            (start: 12, end: 15, label: "12-15h"),
            (start: 15, end: 18, label: "15-18h"),
            (start: 18, end: 21, label: "18-21h"),
            (start: 21, end: 24, label: "21-24h")
        ]
        
        // 各時間帯ごとの学習時間を集計
        var slotMinutes: [Int: Int] = [:]
        
        for activity in activities {
            guard let activityDate = activity.date else { continue }
            
            let hour = calendar.component(.hour, from: activityDate)
            
            // 該当する時間帯を特定
            for (index, slot) in timeSlots.enumerated() {
                if hour >= slot.start && hour < slot.end {
                    slotMinutes[index, default: 0] += Int(activity.durationMinutes)
                    break
                }
            }
        }
        
        // ChartItemの配列に変換
        var result: [ChartItem] = []
        
        for (index, slot) in timeSlots.enumerated() {
            let minutes = slotMinutes[index, default: 0]
            let date = calendar.date(bySettingHour: slot.start, minute: 0, second: 0, of: Date()) ?? Date()
            
            result.append(ChartItem(date: date, label: slot.label, minutes: minutes))
        }
        
        return result
    }
    
    // 週間データ（日ごと）
    private func weeklyChartData(_ activities: [LearningActivity]) -> [ChartItem] {
        let calendar = Calendar.current
        var result: [ChartItem] = []
        
        // 7日分のデータを用意
        for day in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -6 + day, to: calendar.startOfDay(for: dateRange.end)) ?? Date()
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = (calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay).addingTimeInterval(-1)
            
            // その日のアクティビティを集計
            let dayActivities = activities.filter { activity in
                guard let activityDate = activity.date else { return false }
                return activityDate >= startOfDay && activityDate <= endOfDay
            }
            
            let totalMinutes = dayActivities.reduce(0) { $0 + Int($1.durationMinutes) }
            
            // 日付だけを表示
            let dayStr = calendar.component(.day, from: date)
            let label = "%d日".localizedWithInt(dayStr)

            result.append(ChartItem(date: date, label: label, minutes: totalMinutes))
        }
        
        return result
    }
    
    // 月間データ（1日ごと）
    private func monthlyChartData(_ activities: [LearningActivity]) -> [ChartItem] {
        let calendar = Calendar.current
        var result: [ChartItem] = []
        
        // 30日分のデータを用意（1日ごと）
        for day in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -29 + day, to: calendar.startOfDay(for: dateRange.end)) ?? Date()
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = (calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay).addingTimeInterval(-1)
            
            // その日のアクティビティを集計
            let dayActivities = activities.filter { activity in
                guard let activityDate = activity.date else { return false }
                return activityDate >= startOfDay && activityDate <= endOfDay
            }
            
            let totalMinutes = dayActivities.reduce(0) { $0 + Int($1.durationMinutes) }
            
            // 日付のみをラベルとして使用
            let dayComponent = calendar.component(.day, from: date)
            let label = "\(dayComponent)日"
            
            result.append(ChartItem(date: date, label: label, minutes: totalMinutes))
        }
        
        return result
    }
    
    // 年間データ（月ごと）
    private func yearlyChartData(_ activities: [LearningActivity]) -> [ChartItem] {
        let calendar = Calendar.current
        var result: [ChartItem] = []
        
        // 12ヶ月分のデータを用意
        for month in 0..<12 {
            let date = calendar.date(byAdding: .month, value: -11 + month, to: calendar.startOfDay(for: dateRange.end)) ?? Date()
            
            // 月の初日と最終日を計算
            var components = calendar.dateComponents([.year, .month], from: date)
            guard let startOfMonth = calendar.date(from: components) else { continue }

            components.month = (components.month ?? 1) + 1
            guard let startOfNextMonth = calendar.date(from: components) else { continue }
            let endOfMonth = startOfNextMonth.addingTimeInterval(-1)
            
            // その月のアクティビティを集計
            let monthActivities = activities.filter { activity in
                guard let activityDate = activity.date else { return false }
                return activityDate >= startOfMonth && activityDate <= endOfMonth
            }
            
            let totalMinutes = monthActivities.reduce(0) { $0 + Int($1.durationMinutes) }
            
            // 月名を取得
            let monthName = calendar.monthSymbols[calendar.component(.month, from: date) - 1]
            let shortMonth = String(monthName.prefix(3))
            
            result.append(ChartItem(date: date, label: shortMonth, minutes: totalMinutes))
        }
        
        return result
    }
}

// iOS 16未満用の代替グラフ表示
struct LegacyChartView: View {
    let data: [StudyTimeChartView.ChartItem]
    let average: Int
    
    var body: some View {
        VStack(spacing: 8) {
            if data.isEmpty {
                Text("データがありません")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                // スケールを計算
                let maxValue = max(data.max(by: { $0.minutes < $1.minutes })?.minutes ?? 0, 1)
                
                HStack(alignment: .bottom, spacing: 4) {
                    // 縦軸ラベル
                    VStack(alignment: .trailing, spacing: 8) {
                        Text("\(maxValue)分")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text("\(maxValue / 2)分")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text("0分")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(width: 40)
                    
                    // バーチャート
                    HStack(alignment: .bottom, spacing: 2) {
                        ForEach(data) { item in
                            VStack {
                                // バー
                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(width: 20, height: CGFloat(item.minutes) / CGFloat(maxValue) * 150)
                                
                                // ラベル
                                Text(item.label)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .rotationEffect(.degrees(-45))
                                    .frame(width: 20)
                            }
                        }
                    }
                }
                .padding()
                
                // 平均値ライン
                HStack {
                    Text("平均: \(average)分")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    Rectangle()
                        .fill(Color.red)
                        .frame(height: 1)
                        .opacity(0.5)
                }
                .padding(.horizontal)
            }
        }
    }
}
