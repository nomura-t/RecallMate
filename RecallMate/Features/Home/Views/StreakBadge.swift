// StreakBadge.swift - コンパクトなストリーク表示バッジ
import SwiftUI
import CoreData

struct StreakBadge: View {
    @Environment(\.managedObjectContext) private var viewContext

    @State private var currentStreak: Int16 = 0
    @State private var hasStudiedToday: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(streakColor)

            Text("\(currentStreak)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(streakColor)

            if hasStudiedToday {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(streakColor.opacity(0.12))
        )
        .onAppear { loadData() }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ForceRefreshMemoData"))) { _ in
            loadData()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshActivityData"))) { _ in
            loadData()
        }
    }

    // MARK: - Computed

    private var streakColor: Color {
        if currentStreak >= 30 { return .red }
        if currentStreak >= 7 { return .orange }
        if currentStreak >= 1 { return .blue }
        return .gray
    }

    // MARK: - Data

    private func loadData() {
        // ストリーク
        let streakRequest = NSFetchRequest<StreakData>(entityName: "StreakData")
        if let data = try? viewContext.fetch(streakRequest).first {
            currentStreak = data.currentStreak
            if let lastActive = data.lastActiveDate {
                hasStudiedToday = Calendar.current.isDateInToday(lastActive)
            }
        }

        // 今日のアクティビティがあれば学習済み
        if !hasStudiedToday {
            let calendar = Calendar.current
            let start = calendar.startOfDay(for: Date())
            let end = (calendar.date(byAdding: .day, value: 1, to: start) ?? start).addingTimeInterval(-1)
            let actRequest: NSFetchRequest<LearningActivity> = LearningActivity.fetchRequest()
            actRequest.predicate = NSPredicate(format: "date >= %@ AND date <= %@", start as NSDate, end as NSDate)
            actRequest.fetchLimit = 1
            if let results = try? viewContext.fetch(actRequest), !results.isEmpty {
                hasStudiedToday = true
            }
        }
    }
}
