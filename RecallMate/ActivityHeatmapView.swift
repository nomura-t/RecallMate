import SwiftUI
import CoreData

struct ActivityHeatmapView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: LearningActivity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \LearningActivity.date, ascending: false)],
        animation: .default)
    private var activities: FetchedResults<LearningActivity>
    
    // 表示する年
    @State private var selectedYear: Int
    
    // 初期化時に現在の年を設定
    init() {
        let currentYear = Calendar.current.component(.year, from: Date())
        _selectedYear = State(initialValue: currentYear)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 年選択コントロール
            HStack {
                Spacer()
                
                Button(action: {
                    selectedYear -= 1
                }) {
                    Image(systemName: "chevron.left")
                        .frame(width: 44, height: 22)  // タップ領域を拡大
                        .contentShape(Rectangle())     // タップ可能な領域を明確に
                }
                .buttonStyle(PlainButtonStyle())       // ボタンスタイルを明示的に設定
                
                Text("\(selectedYear)年".localized)
                    .font(.subheadline)
                    .frame(width:.infinity)  // 幅を広げる
                
                Button(action: {
                    // 制限を緩和（例：現在の年から10年先まで許可）
                    let maxAllowedYear = Calendar.current.component(.year, from: Date()) + 10
                    selectedYear = min(maxAllowedYear, selectedYear + 1)
                }) {
                    Image(systemName: "chevron.right")
                        .frame(width: 44, height: 22)  // タップ領域を拡大
                        .contentShape(Rectangle())     // タップ可能な領域を明確に
                }
                .buttonStyle(PlainButtonStyle())       // ボタンスタイルを明示的に設定
            }
            .padding(.horizontal)
            
            // ヒートマップ
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 4) {
                    // 月ラベル
                    MonthLabelsView()
                    
                    // 曜日ラベルと日付マス目
                    HStack(alignment: .top, spacing: 4) {
                        // 曜日ラベル
                        WeekdayLabelsView()
                        
                        // 日付マス目
                        HeatmapGridView(year: selectedYear, activities: activities)
                    }
                }
                .padding()
            }
            
            // 凡例
            HStack(spacing: 12) {
                Spacer()
                
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 12, height: 12)
                    Text("1〜2件".localized)
                        .font(.caption)
                }
                
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.green.opacity(0.4))
                        .frame(width: 12, height: 12)
                    Text("3〜5件".localized)
                        .font(.caption)
                }
                
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.green.opacity(0.7))
                        .frame(width: 12, height: 12)
                    Text("6〜8件".localized)
                        .font(.caption)
                }
                
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                    Text("9件以上".localized)
                        .font(.caption)
                }
                
                Spacer()
            }
            .padding(.horizontal)
        }
        .onAppear {
            calculateActivityCounts()
        }
    }
    
    // アクティビティ数の計算
    private func calculateActivityCounts() {
        // ここでアクティビティのカウントを計算
        // 実装は省略（LearningActivityサービスを使用）
    }
}

// 月ラベルを表示するビュー
struct MonthLabelsView: View {
    // 日本語の月名を使用
    private let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // 曜日ラベル用の余白
            Rectangle()
                .fill(Color.clear)
                .frame(width: 30, height: 20)
            
            // 月ラベルを横に並べる
            HStack(spacing: 22) { // 間隔を調整
                ForEach(0..<12, id: \.self) { monthIndex in
                    Text(months[monthIndex])
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(width: 50, alignment: .leading) // 幅を最小限に
                }
            }
            .padding(.leading, 0) // 左の余白を削除
        }
    }
}

// 曜日ラベルを表示するビュー
struct WeekdayLabelsView: View {
    private let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            ForEach(weekdays, id: \.self) { weekday in
                Text(weekday)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(height: 12)
            }
        }
        .frame(width: 30)
    }
}

// ヒートマップのグリッドを表示するビュー
struct HeatmapGridView: View {
    let year: Int
    let activities: FetchedResults<LearningActivity>
    
    // カラーマップ
    private let colorMap: [Color] = [
        Color.green.opacity(0.1),  // 1-2件
        Color.green.opacity(0.4),  // 3-5件
        Color.green.opacity(0.7),  // 6-8件
        Color.green                 // 9件以上
    ]
    
    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            ForEach(0..<53, id: \.self) { weekIndex in
                VStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { dayIndex in
                        let date = getDate(weekIndex: weekIndex, dayIndex: dayIndex)
                        
                        if let date = date, isDateInSelectedYear(date) {
                            let count = getActivityCount(for: date)
                            Rectangle()
                                .fill(getColor(for: count))
                                .frame(width: 12, height: 12)
                                .cornerRadius(2)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 2)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                                )
                                .tooltip("\(formattedDate(date)): \(count)件")
                        } else {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(width: 12, height: 12)
                        }
                    }
                }
            }
        }
    }
    
    // 日付を取得する関数
    private func getDate(weekIndex: Int, dayIndex: Int) -> Date? {
        let calendar = Calendar.current
        
        // 年の最初の日を取得
        var components = DateComponents()
        components.year = year
        components.month = 1
        components.day = 1
        
        guard let firstDayOfYear = calendar.date(from: components) else {
            return nil
        }
        
        // 年の最初の日の曜日を取得（0=日曜日, 1=月曜日, ...）
        let firstDayWeekday = calendar.component(.weekday, from: firstDayOfYear)
        
        // 月曜日を基準に調整（月曜日を0とする）
        let adjustedFirstDayWeekday = (firstDayWeekday + 5) % 7
        
        // 目的の日の日数を計算
        let dayOffset = weekIndex * 7 + dayIndex - adjustedFirstDayWeekday
        
        // 年の最初の日から日数を加算
        return calendar.date(byAdding: .day, value: dayOffset, to: firstDayOfYear)
    }
    
    // 日付が選択された年に含まれるかをチェック
    private func isDateInSelectedYear(_ date: Date) -> Bool {
        return Calendar.current.component(.year, from: date) == year
    }
    
    // 指定日のアクティビティ数を取得
    private func getActivityCount(for date: Date) -> Int {
        let calendar = Calendar.current
        
        // 日付の開始と終了を取得
        let startOfDay = calendar.startOfDay(for: date)
        var components = DateComponents()
        components.day = 1
        components.second = -1
        let endOfDay = calendar.date(byAdding: components, to: startOfDay)!
        
        // その日のアクティビティをフィルタリング
        let dailyActivities = activities.filter { activity in
            if let activityDate = activity.date {
                return activityDate >= startOfDay && activityDate <= endOfDay
            }
            return false
        }
        
        return dailyActivities.count
    }
    
    // アクティビティ数に基づいて色を返す
    private func getColor(for count: Int) -> Color {
        if count == 0 {
            return Color.gray.opacity(0.1)
        } else if count <= 2 {
            return colorMap[0]
        } else if count <= 5 {
            return colorMap[1]
        } else if count <= 8 {
            return colorMap[2]
        } else {
            return colorMap[3]
        }
    }
    
    // 日付のフォーマット
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// ツールチップ修飾子
extension View {
    func tooltip(_ text: String) -> some View {
        return self
            .overlay(
                TooltipView(text: text, isVisible: .constant(false))
                    .opacity(0) // 実際のツールチップ機能はiOSでは限られているため、ここではデモのみ
            )
    }
}

// ツールチップビュー（実際のiOSではカスタム実装が必要）
struct TooltipView: View {
    let text: String
    @Binding var isVisible: Bool
    
    var body: some View {
        if isVisible {
            Text(text)
                .font(.caption)
                .padding(6)
                .background(Color.black.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(4)
        } else {
            EmptyView()
        }
    }
}
