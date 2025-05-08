// ActivityProgressView.swift のローカライズ対応版

import SwiftUI
import CoreData

struct ActivityProgressView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // 現在選択されているタブ
    @State private var selectedTab: Int = 0
    
    // タグフィルタリング用
    @State private var selectedTag: Tag? = nil
    
    // 年の選択
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    
    // タグのFetchRequest
    @FetchRequest(
        entity: Tag.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)],
        animation: .default)
    private var allTags: FetchedResults<Tag>
    
    // 初期化時に今年と今月を設定
    init() {
        let calendar = Calendar.current
        let date = Date()
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        
        _selectedYear = State(initialValue: year)
        _selectedMonth = State(initialValue: month)
    }
    
    // 選択されたタブに応じた日付範囲を計算
    private var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now)!
        
        switch selectedTab {
        case 0: // 日間
            let startOfDay = calendar.startOfDay(for: now)
            return (startOfDay, endOfDay)
            
        case 1: // 週間
            guard let weekStart = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) else {
                return (now, now)
            }
            return (weekStart, endOfDay)
            
        case 2: // 月間
            guard let monthStart = calendar.date(byAdding: .day, value: -29, to: calendar.startOfDay(for: now)) else {
                return (now, now)
            }
            return (monthStart, endOfDay)
            
        case 3: // 年間
            guard let yearStart = calendar.date(byAdding: .day, value: -364, to: calendar.startOfDay(for: now)) else {
                return (now, now)
            }
            return (yearStart, endOfDay)
            
        default:
            let startOfDay = calendar.startOfDay(for: now)
            return (startOfDay, endOfDay)
        }
    }
    
    // 期間表示用のテキスト
    private var periodText: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        let (start, end) = dateRange
        
        switch selectedTab {
        case 0: // 日間
            return "今日 (%@)".localizedFormat(dateFormatter.string(from: start))
        case 1: // 週間
            return "%@ - %@".localizedFormat(dateFormatter.string(from: start), dateFormatter.string(from: end))
        case 2: // 月間
            return "過去30日".localized
        case 3: // 年間
            return "過去365日".localized
        default:
            return ""
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // タグリスト（水平スクロール）
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // 「すべて」ボタン
                        Button(action: {
                            selectedTag = nil
                        }) {
                            Text("すべて".localized)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedTag == nil ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(selectedTag == nil ? .white : .primary)
                                .cornerRadius(16)
                        }
                        
                        // タグボタン
                        ForEach(allTags) { tag in
                            Button(action: {
                                if selectedTag?.id == tag.id {
                                    // 同じタグをタップしたらフィルターを解除
                                    selectedTag = nil
                                } else {
                                    // タグを選択
                                    selectedTag = tag
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(tag.swiftUIColor())
                                        .frame(width: 8, height: 8)
                                    
                                    Text(tag.name ?? "")
                                        .font(.subheadline)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedTag?.id == tag.id ? tag.swiftUIColor().opacity(0.2) : Color.gray.opacity(0.15))
                                .foregroundColor(selectedTag?.id == tag.id ? tag.swiftUIColor() : .primary)
                                .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                // 期間セレクター
                Picker("表示期間".localized, selection: $selectedTab) {
                    Text("日".localized).tag(0)
                    Text("週".localized).tag(1)
                    Text("月".localized).tag(2)
                    Text("年".localized).tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 統計サマリーカード - 期間とタグフィルターを渡す
                        StatisticsCardWithPeriod(
                            dateRange: dateRange,
                            periodText: periodText,
                            selectedTag: selectedTag
                        )
                        
                        // ヒートマップ
                        VStack(alignment: .leading, spacing: 8) {
                            ActivityHeatmapView()
                                .frame(height: 220)
                        }
                        .padding(.vertical)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        // 学習時間グラフを追加
                        StudyTimeChartView(
                            dateRange: dateRange,
                            periodText: periodText,
                            selectedTab: selectedTab,
                            selectedTag: selectedTag
                        )
                        
                        // アクティビティリスト - 期間とタグフィルターを渡す
                        ActivityListWithPeriod(
                            dateRange: dateRange,
                            selectedTag: selectedTag
                        )
                    }
                    .padding()
                }
                .refreshable {
                    // Pull to refreshで表示を更新
                    refreshData()
                }
            }
            .navigationTitle("")
            .background(Color(.systemGroupedBackground))
            .onAppear {
                // 画面表示時にデータを更新
                refreshData()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: refreshData) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshActivityData"))) { _ in
            refreshData()
        }
    }
    
    // データをリフレッシュするメソッド - デバッグ情報付き
    private func refreshData() {
        // ViewContextをリフレッシュ
        viewContext.refreshAllObjects()
        
        // StatisticsCardのFetchRequestとRecentActivityListViewのFetchRequestを診断
        let fetchRequest: NSFetchRequest<LearningActivity> = LearningActivity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \LearningActivity.date, ascending: false)]
        
        do {
            let activities = try viewContext.fetch(fetchRequest)
            if activities.isEmpty {
                // Empty activities
            } else {
                // 最新のアクティビティを表示
                if let latest = activities.first, let date = latest.date {
                    // Latest activity
                }
            }
        } catch {
            // Error handling
        }
        
        // 非同期で更新を反映（SwiftUIの更新サイクルを考慮）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Async update
        }
    }
}

// 統計サマリーカード（期間指定対応版）
struct StatisticsCardWithPeriod: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // 日付範囲
    let dateRange: (start: Date, end: Date)
    let periodText: String
    
    // タグフィルタリング用
    var selectedTag: Tag?
    
    // フィルタリングされたアクティビティ配列を取得
    private var periodActivities: [LearningActivity] {
        let fetchRequest: NSFetchRequest<LearningActivity> = LearningActivity.fetchRequest()
        
        // 日付によるフィルタリング
        fetchRequest.predicate = NSPredicate(
            format: "date >= %@ AND date <= %@",
            dateRange.start as NSDate,
            dateRange.end as NSDate
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \LearningActivity.date, ascending: false)]
        
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
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                if let selectedTag = selectedTag {
                    HStack {
                        Text("学習統計 (%@)".localizedFormat(periodText))
                            .font(.headline)
                        
                        Circle()
                            .fill(selectedTag.swiftUIColor())
                            .frame(width: 8, height: 8)
                        
                        Text(selectedTag.name ?? "")
                            .font(.subheadline)
                            .foregroundColor(selectedTag.swiftUIColor())
                    }
                } else {
                    Text("学習統計 (%@)".localizedFormat(periodText))
                        .font(.headline)
                }
                
                Spacer()
            }
            
            HStack(spacing: 20) {
                StatItem(
                    value: "\(periodActivities.count)",
                    label: "学習セッション".localized,
                    icon: "book.fill",
                    color: .blue
                )
                
                StatItem(
                    value: "\(totalDuration)分".localized,
                    label: "合計学習時間".localized,
                    icon: "clock.fill",
                    color: .green
                )
                
                StatItem(
                    value: "\(streakDays)日".localized,
                    label: "連続学習".localized,
                    icon: "flame.fill",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // 合計学習時間（分）
    private var totalDuration: Int {
        periodActivities.reduce(0) { $0 + Int($1.durationMinutes) }
    }
    
    // 学習ストリーク（日数）- 簡易実装
    private var streakDays: Int {
        // 実際の実装ではStreakTrackerを使用
        let calendar = Calendar.current
        var currentDate = Date()
        var streakCount = 0
        
        while true {
            let startOfDay = calendar.startOfDay(for: currentDate)
            guard let endOfDay = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay) else {
                break
            }
            
            let dailyActivities = periodActivities.filter { activity in
                if let activityDate = activity.date {
                    return activityDate >= startOfDay && activityDate <= endOfDay
                }
                return false
            }
            
            if dailyActivities.isEmpty {
                break
            }
            
            streakCount += 1
            if let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) {
                currentDate = previousDay
            } else {
                break
            }
        }
        
        return streakCount
    }
}

// アクティビティリスト（期間指定対応版）
struct ActivityListWithPeriod: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // 日付範囲
    let dateRange: (start: Date, end: Date)
    
    // タグフィルタリング用
    var selectedTag: Tag?
    
    // フィルタリングされたアクティビティ配列を取得
    private var periodActivities: [LearningActivity] {
        let fetchRequest: NSFetchRequest<LearningActivity> = LearningActivity.fetchRequest()
        
        // 日付によるフィルタリング
        fetchRequest.predicate = NSPredicate(
            format: "date >= %@ AND date <= %@",
            dateRange.start as NSDate,
            dateRange.end as NSDate
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \LearningActivity.date, ascending: false)]
        
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let selectedTag = selectedTag {
                    HStack {
                        Text("アクティビティ".localized)
                            .font(.headline)
                        
                        Circle()
                            .fill(selectedTag.swiftUIColor())
                            .frame(width: 8, height: 8)
                        
                        Text(selectedTag.name ?? "")
                            .font(.subheadline)
                            .foregroundColor(selectedTag.swiftUIColor())
                    }
                } else {
                    Text("アクティビティ".localized)
                        .font(.headline)
                }
                
                Spacer()
                
                // 件数表示
                Text("%d件".localizedWithInt(periodActivities.count))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            
            if periodActivities.isEmpty {
                Text("この期間のアクティビティはありません".localized)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                // アクティビティをグループ化して表示
                ForEach(groupActivitiesByDate(), id: \.key) { dateGroup in
                    VStack(alignment: .leading, spacing: 4) {
                        // 日付ヘッダー
                        Text(formattedDate(dateGroup.key))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        // その日のアクティビティ
                        ForEach(dateGroup.value, id: \.id) { activity in
                            ActivityRow(activity: activity)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        deleteActivity(activity)
                                    } label: {
                                        Label("削除".localized, systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // Activity の削除メソッド
    private func deleteActivity(_ activity: LearningActivity) {
        // CoreDataからアクティビティを削除
        viewContext.delete(activity)
        
        // 変更を保存
        do {
            try viewContext.save()
        } catch {
            // Error handling
        }
    }
    
    // アクティビティを日付でグループ化
    private func groupActivitiesByDate() -> [(key: Date, value: [LearningActivity])] {
        let groupedActivities = Dictionary(grouping: periodActivities) { activity in
            // 日付の時間部分を切り捨てる
            if let date = activity.date {
                return Calendar.current.startOfDay(for: date)
            }
            return Date()
        }
        
        // 日付順にソート（最新の日付が最初）
        return groupedActivities.sorted { $0.key > $1.key }
    }
    
    // 日付のフォーマット
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// アクティビティ行
struct ActivityRow: View {
    let activity: LearningActivity
    
    var body: some View {
        HStack(spacing: 12) {
            // アクティビティタイプのアイコン
            Image(systemName: iconForActivityType(activity.type ?? ""))
                .font(.system(size: 18))
                .foregroundColor(colorForActivityType(activity.type ?? ""))
                .frame(width: 36, height: 36)
                .background(colorForActivityType(activity.type ?? "").opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 3) {
                // アクティビティのタイトル
                HStack(spacing: 4) {
                    // メモのタイトル
                    Text(activity.memo?.title ?? "無題".localized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    // アクティビティタイプを示すラベル（新規作成と復習を区別）
                    Text(activityLabel(activity))
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(colorForActivityType(activity.type ?? "").opacity(0.2))
                        .foregroundColor(colorForActivityType(activity.type ?? ""))
                        .cornerRadius(4)
                }
                
                // アクティビティの詳細
                HStack {
                    Text(activityTypeString(activity.type ?? ""))
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("%d分".localizedWithInt(Int(activity.durationMinutes)))
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if let note = activity.note, !note.isEmpty {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(note)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // 時間表示
            if let date = activity.date {
                Text(formattedTime(date))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
    }
    
    private func activityLabel(_ activity: LearningActivity) -> String {
        if activity.type == "exercise" {
            return "新規作成".localized
        } else if activity.type == "review" {
            return "復習".localized
        } else {
            return activityTypeString(activity.type ?? "")
        }
    }
    
    // アクティビティタイプに応じたアイコンを返す
    private func iconForActivityType(_ type: String) -> String {
        switch type {
        case "読書", "reading":
            return "book.fill"
        case "問題演習", "exercise":
            // 新規メモ作成用の明確に異なるアイコン
            return "doc.badge.plus"
        case "講義視聴", "lecture":
            return "tv.fill"
        case "テスト", "test":
            return "checkmark.square.fill"
        case "プロジェクト", "project":
            return "folder.fill"
        case "実験/実習", "experiment":
            return "atom"
        case "復習", "review":
            // 復習用のアイコンを確認
            return "arrow.counterclockwise"
        default:
            // 新規メモと復習を特定できる場合（注釈を活用）
            if let note = activity.note {
                if note.contains("新規メモ作成".localized) {
                    return "doc.badge.plus"
                } else if note.contains("復習".localized) {
                    return "arrow.counterclockwise"
                }
            }
            return "ellipsis.circle.fill"
        }
    }
    
    // アクティビティタイプに応じた色を返す
    private func colorForActivityType(_ type: String) -> Color {
        switch type {
        case "読書", "reading": return .blue
        case "問題演習", "exercise": return .green // 新規作成は緑色
        case "講義視聴", "lecture": return .purple
        case "テスト", "test": return .red
        case "プロジェクト", "project": return .orange
        case "実験/実習", "experiment": return .teal
        case "復習", "review": return .cyan
        default: return .gray
        }
    }
    
    // アクティビティタイプの文字列表現
    private func activityTypeString(_ type: String) -> String {
        switch type {
        case "reading": return "読書".localized
        case "exercise": return "新規メモ作成".localized // 表示名を変更
        case "lecture": return "講義視聴".localized
        case "test": return "テスト".localized
        case "project": return "プロジェクト".localized
        case "experiment": return "実験/実習".localized
        case "review": return "復習".localized
        default: return type.isEmpty ? "その他".localized : type
        }
    }
    
    // 時間のフォーマット
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

// 統計アイテム - エラーを修正するために追加
struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
