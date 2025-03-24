import SwiftUI
import Charts // iOS 16以降用

struct RetentionGraphView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    let memo: Memo
    @State private var selectedPeriod: TimePeriod = .month
    
    enum TimePeriod: String, CaseIterable, Identifiable {
        case week = "週間"
        case month = "月間"
        case year = "年間"
        case all = "全期間"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        VStack {
            // 期間選択セグメント
            Picker("表示期間", selection: $selectedPeriod) {
                ForEach(TimePeriod.allCases) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // iOS 16以降とそれ以前で分岐
            if #available(iOS 16.0, *) {
                chartView
            } else {
                legacyChartView
            }
            
            // 凡例
            HStack {
                Circle().fill(.blue).frame(width: 10, height: 10)
                Text("記憶定着度").font(.caption)
                
                Spacer().frame(width: 20)
                
                Circle().fill(.green).frame(width: 10, height: 10)
                Text("自己評価").font(.caption)
            }
            .padding()
            
            // 統計情報
            statisticsView
            
            Spacer()
        }
        .navigationTitle("記憶定着度の推移")
    }
    
    // iOS 16以降用グラフ
    @available(iOS 16.0, *)
    private var chartView: some View {
        Chart {
            ForEach(filteredHistory) { entry in
                LineMark(
                    x: .value("日付", entry.date ?? Date()),
                    y: .value("記憶定着度", entry.retentionScore)
                )
                .foregroundStyle(.blue)
                
                PointMark(
                    x: .value("日付", entry.date ?? Date()),
                    y: .value("記憶定着度", entry.retentionScore)
                )
                .foregroundStyle(.blue)
            }
            
            // 自己評価スコアも表示
            ForEach(filteredHistory) { entry in
                LineMark(
                    x: .value("日付", entry.date ?? Date()),
                    y: .value("自己評価", entry.recallScore)
                )
                .foregroundStyle(.green)
            }
        }
        .chartYScale(domain: 0...100)
        .frame(height: 300)
        .padding()
    }
    
    // iOS 16未満用の代替表示
    private var legacyChartView: some View {
        VStack(spacing: 20) {
            Text("記憶定着度グラフ")
                .font(.headline)
            
            // 簡易グラフ表示（バーグラフ的な表現）
            HStack(alignment: .bottom, spacing: 5) {
                ForEach(filteredHistory.prefix(7)) { entry in
                    VStack {
                        // 定着度バー
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue)
                            .frame(width: 30, height: CGFloat(entry.retentionScore) * 2)
                        
                        // 日付ラベル
                        Text(formatDate(entry.date ?? Date()))
                            .font(.caption2)
                            .rotationEffect(.degrees(-45))
                            .frame(width: 35)
                    }
                }
            }
            .frame(height: 250)
            .padding()
            
            Text("※ iOS 16以降ではより詳細なグラフが表示されます")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    // 統計情報ビュー
    private var statisticsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("統計情報").font(.headline).padding(.leading)
            
            HStack {
                StatBox(title: "平均定着度", value: String(format: "%.1f%%", averageRetentionScore))
                StatBox(title: "最高定着度", value: "\(highestRetentionScore)%")
                StatBox(title: "復習回数", value: "\(reviewCount)")
            }
            .padding(.horizontal)
        }
    }
    
    // フィルター・計算用のヘルパー
    private var filteredHistory: [MemoHistoryEntry] {
        let entries = memo.historyEntriesArray
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedPeriod {
        case .week:
            let startDate = calendar.date(byAdding: .day, value: -7, to: now)!
            return entries.filter { ($0.date ?? Date()) >= startDate }
        case .month:
            let startDate = calendar.date(byAdding: .month, value: -1, to: now)!
            return entries.filter { ($0.date ?? Date()) >= startDate }
        case .year:
            let startDate = calendar.date(byAdding: .year, value: -1, to: now)!
            return entries.filter { ($0.date ?? Date()) >= startDate }
        case .all:
            return entries
        }
    }
    
    private var averageRetentionScore: Double {
        let entries = filteredHistory
        guard !entries.isEmpty else { return 0 }
        let sum = entries.reduce(0) { $0 + Double($1.retentionScore) }
        return sum / Double(entries.count)
    }
    
    private var highestRetentionScore: Int16 {
        filteredHistory.max(by: { $0.retentionScore < $1.retentionScore })?.retentionScore ?? 0
    }
    
    private var reviewCount: Int {
        filteredHistory.count
    }
    
    // 日付フォーマット用
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}

// 統計表示用のコンポーネント
struct StatBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title).font(.caption).foregroundColor(.gray)
            Text(value).font(.title3).bold()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
    }
}

// プレビュー用
struct RetentionGraphView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let memo = Memo(context: context)
        memo.title = "プレビュー用メモ"
        memo.recallScore = 80
        
        // ダミーの履歴データを追加
        for i in 0..<5 {
            let history = MemoHistoryEntry(context: context)
            history.id = UUID()
            history.date = Calendar.current.date(byAdding: .day, value: -i, to: Date())
            history.recallScore = Int16(70 + i * 5)
            history.retentionScore = Int16(75 + i * 4)
            history.memo = memo
        }
        
        return NavigationView {
            RetentionGraphView(memo: memo)
        }
    }
}
