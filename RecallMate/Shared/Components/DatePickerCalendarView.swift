// DatePickerCalendarView.swift - プロダクション版
import SwiftUI

struct DatePickerCalendarView: View {
    @Binding var selectedDate: Date
    @State private var currentWeekOffset: Int = 0
    
    // カレンダー設定を明示的に定義して一貫性を保つ
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale.current
        cal.timeZone = TimeZone.current
        cal.firstWeekday = 2  // 月曜日を週の始まりに設定
        return cal
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    // 現在表示する週の日付配列を計算
    // 常に今日を基準として、オフセットを適用した週を表示する
    private var weekDates: [Date] {
        let today = Date()
        let todayMondayStart = findMondayOfWeek(containing: today)
        
        // オフセットを適用してターゲット週の月曜日を計算
        guard let targetMondayStart = calendar.date(byAdding: .weekOfYear, value: currentWeekOffset, to: todayMondayStart) else {
            return []
        }
        
        // その週の7日間（月曜日から日曜日まで）を生成
        var dates: [Date] = []
        for dayOffset in 0...6 {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: targetMondayStart) {
                dates.append(date)
            }
        }
        
        return dates
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 年月表示とナビゲーションヒント
            HStack {
                Text(yearMonthText)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("← スワイプで週移動 →".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            // 曜日ヘッダー（月曜日から日曜日まで）
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            
            // 週表示（7日間の日付セル）
            HStack(spacing: 0) {
                ForEach(weekDates, id: \.self) { date in
                    WeekDateCellView(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(date),
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedDate = date
                            }
                        }
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
        }
        .background(Color(.systemBackground))
        .gesture(
            // 水平スワイプによる週ナビゲーション
            DragGesture()
                .onEnded { gestureValue in
                    let horizontalMovement = gestureValue.translation.width
                    let verticalMovement = gestureValue.translation.height
                    
                    // 水平方向のスワイプが垂直方向より大きい場合のみ反応
                    if abs(horizontalMovement) > abs(verticalMovement) {
                        let swipeThreshold: CGFloat = 50
                        
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if horizontalMovement > swipeThreshold {
                                currentWeekOffset -= 1  // 前の週へ
                            } else if horizontalMovement < -swipeThreshold {
                                currentWeekOffset += 1  // 次の週へ
                            }
                        }
                    }
                }
        )
        .onAppear {
            // 初期表示時は常に今日を含む週を表示（オフセット0）
            initializeToCurrentWeek()
        }
        .onChange(of: selectedDate) { _, newDate in
            // 選択された日付が現在表示している週の範囲外の場合のみ週を移動
            if !isDateInCurrentDisplayedWeek(newDate) {
                adjustWeekOffsetToSelectedDate()
            }
        }
    }
    
    // 年月のテキスト表示（週の中央の日付を基準に判定）
    private var yearMonthText: String {
        guard let middleDate = weekDates.count >= 4 ? weekDates[3] : weekDates.first else {
            dateFormatter.setLocalizedDateFormatFromTemplate("yyyyMMMM")
            return dateFormatter.string(from: Date())
        }
        
        dateFormatter.setLocalizedDateFormatFromTemplate("yyyyMMMM")
        return dateFormatter.string(from: middleDate)
    }
    
    // 曜日表示用のシンボル配列
    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        let weekdaySymbols = formatter.shortWeekdaySymbols ?? ["月", "火", "水", "木", "金", "土", "日"]
        
        // 月曜日から始まるように並び替え（元は日曜日が最初）
        var reorderedSymbols = Array(weekdaySymbols[1...6]) // 月-土
        reorderedSymbols.append(weekdaySymbols[0]) // 日を最後に追加
        
        return reorderedSymbols
    }
    
    // 指定された日付を含む週の月曜日を確実に計算する関数
    // この関数は数学的計算により、カレンダーシステムの複雑性に依存しない確実な結果を提供する
    private func findMondayOfWeek(containing date: Date) -> Date {
        let weekday = calendar.component(.weekday, from: date)
        
        // 月曜日（weekday = 2）からの日数差を計算
        let daysFromMonday: Int
        if weekday == 1 {  // 日曜日の場合
            daysFromMonday = 6  // 6日前が月曜日
        } else {
            daysFromMonday = weekday - 2  // 月曜日は2なので、2を引く
        }
        
        // 計算した日数分を引いて月曜日の日付を取得
        return calendar.date(byAdding: .day, value: -daysFromMonday, to: date) ?? date
    }
    
    // 指定された日付が現在表示されている週に含まれるかを判定
    private func isDateInCurrentDisplayedWeek(_ date: Date) -> Bool {
        let currentWeekDates = weekDates
        
        for weekDate in currentWeekDates {
            if calendar.isDate(date, inSameDayAs: weekDate) {
                return true
            }
        }
        
        return false
    }
    
    // 初期化時に今日を含む週を表示するように設定
    private func initializeToCurrentWeek() {
        // オフセット0で今日を含む週を表示
        // この設計により、weekDatesの計算で自動的に今日を含む週が表示される
        currentWeekOffset = 0
    }
    
    // 選択された日付を含む週にオフセットを調整
    private func adjustWeekOffsetToSelectedDate() {
        let today = Date()
        let todayMondayStart = findMondayOfWeek(containing: today)
        let selectedMondayStart = findMondayOfWeek(containing: selectedDate)
        
        // 今日を含む週から選択された日付を含む週までの差を計算
        let weekDifference = calendar.dateComponents([.weekOfYear],
                                                   from: todayMondayStart,
                                                   to: selectedMondayStart).weekOfYear ?? 0
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentWeekOffset = weekDifference
        }
    }
}

// 週内の個別日付を表示するセルビュー
struct WeekDateCellView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let action: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // 日付の数字のみを表示（曜日は上部ヘッダーで表示済み）
                Text(dayText)
                    .font(.system(size: 18, weight: isSelected ? .bold : .medium))
                    .foregroundColor(textColor)
                
                // 今日を示すインジケーター（選択されていない場合のみ）
                if isToday && !isSelected {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 4, height: 4)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .cornerRadius(25)
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 日付の数字部分のみを取得
    private var dayText: String {
        return String(calendar.component(.day, from: date))
    }
    
    // 状態に応じた背景色を計算
    private var backgroundColor: Color {
        if isSelected {
            return Color.blue
        } else if isToday {
            return Color.blue.opacity(0.1)
        } else {
            return Color.clear
        }
    }
    
    // 状態に応じたテキスト色を計算
    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return .blue
        } else {
            return .primary
        }
    }
}
