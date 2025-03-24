// TestDateSection.swift
import SwiftUI

struct TestDateSection: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                // トグルスイッチ - オンにするとドラムロールを表示
                Toggle("テスト日までに覚える", isOn: $viewModel.shouldUseTestDate)
                    .onChange(of: viewModel.shouldUseTestDate) { value in
                        if value {
                            // テスト日が未設定の場合、デフォルトで2週間後に設定
                            if viewModel.testDate == nil {
                                viewModel.testDate = Date()
                            }
                            // ドラムロールを自動的に表示
                            viewModel.showTestDatePicker = true
                        } else {
                            // トグルをオフにしたらドラムロールを非表示
                            viewModel.showTestDatePicker = false
                        }
                    }
                
                if viewModel.shouldUseTestDate {
                    // 日付表示 - カレンダーアイコンなし
                    HStack {
                        Text(viewModel.testDate != nil ? viewModel.formattedDate(viewModel.testDate) : "未設定")
                        Spacer()
                    }
                    
                    // カスタムピッカーを中央に表示
                    if viewModel.showTestDatePicker {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            
                            HStack {
                                Spacer()
                                NumericDatePicker(
                                    date: Binding(
                                        get: { viewModel.testDate ?? Date() },
                                        set: { viewModel.testDate = $0 }
                                    )
                                )
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        } header: {
            Text("テスト日の設定")
        }
    }
}

// 数字のみ表示のカスタム日付ピッカー
struct NumericDatePicker: View {
    @Binding var selectedDate: Date
    
    // 表示用の年、月、日
    @State private var year: Int
    @State private var month: Int
    @State private var day: Int
    
    // 有効な年、月、日の範囲
    private let years: [Int]
    private let months: [Int] = Array(1...12)
    private let calendar = Calendar.current
    
    init(date: Binding<Date>) {
        self._selectedDate = date
        
        // 現在の年を取得
        let currentYear = Calendar.current.component(.year, from: Date())
        // 今年から10年後までの範囲を生成
        self.years = Array(currentYear...(currentYear + 10))
        
        // 初期値を設定
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date.wrappedValue)
        self._year = State(initialValue: components.year ?? currentYear)
        self._month = State(initialValue: components.month ?? 1)
        self._day = State(initialValue: components.day ?? 1)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 年ピッカー - カンマなし
            Picker("", selection: $year) {
                ForEach(years, id: \.self) { yearValue in
                    // カンマなしの文字列として表示
                    Text(String(yearValue))
                        .font(.system(size: 18))
                        .tag(yearValue)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 80)
            .clipped()
            .onChange(of: year) { _ in updateDate() }
            
            // 月ピッカー
            Picker("", selection: $month) {
                ForEach(months, id: \.self) { monthValue in
                    Text(String(monthValue))
                        .font(.system(size: 18))
                        .tag(monthValue)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 50)
            .clipped()
            .onChange(of: month) { _ in updateDate() }
            
            // 日ピッカー
            Picker("", selection: $day) {
                ForEach(daysInSelectedMonth(), id: \.self) { dayValue in
                    Text(String(dayValue))
                        .font(.system(size: 18))
                        .tag(dayValue)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 50)
            .clipped()
            .onChange(of: day) { _ in updateDate() }
        }
        .frame(maxWidth: .infinity)
        .onChange(of: selectedDate) { newDate in
            let components = calendar.dateComponents([.year, .month, .day], from: newDate)
            year = components.year ?? year
            month = components.month ?? month
            day = min(components.day ?? day, daysInSelectedMonth().last ?? 31)
        }
    }
    
    // 選択された年月の日数を計算
    private func daysInSelectedMonth() -> [Int] {
        var components = DateComponents()
        components.year = year
        components.month = month
        
        if let date = calendar.date(from: components),
           let range = calendar.range(of: .day, in: .month, for: date) {
            return Array(range)
        }
        
        return Array(1...31)
    }
    
    // 選択された年月日から日付を更新
    private func updateDate() {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = min(day, daysInSelectedMonth().last ?? 31)
        
        if let date = calendar.date(from: components) {
            selectedDate = date
        }
    }
}
