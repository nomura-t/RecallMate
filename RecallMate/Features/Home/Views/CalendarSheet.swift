// CalendarSheet.swift - カレンダーシート
import SwiftUI
import CoreData

struct CalendarSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()

    let onSelectMemo: (Memo) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DatePickerCalendarView(selectedDate: $selectedDate)
                    .padding(.vertical, 12)

                // 選択日のメモリスト
                let memos = memosForSelectedDate
                if memos.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary)
                        Text("この日の復習項目はありません".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(memos, id: \.id) { memo in
                            Button {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    onSelectMemo(memo)
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(getRetentionColor(for: memo.recallScore))
                                        .frame(width: 8, height: 8)
                                    Text(memo.title ?? "無題".localized)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text("\(memo.recallScore)%")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("カレンダー".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる".localized) {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Data

    private var memosForSelectedDate: [Memo] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = (calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay).addingTimeInterval(-1)
        let isToday = calendar.isDateInToday(selectedDate)

        let fetchRequest: NSFetchRequest<Memo> = Memo.fetchRequest()
        if isToday {
            fetchRequest.predicate = NSPredicate(
                format: "(nextReviewDate >= %@ AND nextReviewDate <= %@) OR (nextReviewDate < %@)",
                startOfDay as NSDate,
                endOfDay as NSDate,
                startOfDay as NSDate
            )
        } else {
            fetchRequest.predicate = NSPredicate(
                format: "nextReviewDate >= %@ AND nextReviewDate <= %@",
                startOfDay as NSDate,
                endOfDay as NSDate
            )
        }
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Memo.nextReviewDate, ascending: true)]

        return (try? viewContext.fetch(fetchRequest)) ?? []
    }
}
