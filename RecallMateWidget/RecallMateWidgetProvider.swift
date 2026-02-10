import WidgetKit
import CoreData

struct RecallMateWidgetEntry: TimelineEntry {
    let date: Date
    let currentStreak: Int
    let remainingReviews: Int
    let topMemoTitle: String?
    let hoursUntilMidnight: Int
    let minutesUntilMidnight: Int
}

struct RecallMateWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> RecallMateWidgetEntry {
        RecallMateWidgetEntry(
            date: Date(),
            currentStreak: 7,
            remainingReviews: 3,
            topMemoTitle: "サンプル記録",
            hoursUntilMidnight: 5,
            minutesUntilMidnight: 30
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (RecallMateWidgetEntry) -> Void) {
        let entry = fetchEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RecallMateWidgetEntry>) -> Void) {
        let entry = fetchEntry()

        // 15分ごとに更新
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func fetchEntry() -> RecallMateWidgetEntry {
        let container = makeContainer()
        let context = container.viewContext

        // ストリークデータ取得
        let streakRequest = NSFetchRequest<NSManagedObject>(entityName: "StreakData")
        let currentStreak: Int
        do {
            let results = try context.fetch(streakRequest)
            currentStreak = Int(results.first?.value(forKey: "currentStreak") as? Int16 ?? 0)
        } catch {
            currentStreak = 0
        }

        // 今日の復習メモ取得
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = (calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay).addingTimeInterval(-1)

        let memoRequest = NSFetchRequest<NSManagedObject>(entityName: "Memo")
        memoRequest.predicate = NSPredicate(
            format: "(nextReviewDate >= %@ AND nextReviewDate <= %@) OR (nextReviewDate < %@)",
            startOfDay as NSDate,
            endOfDay as NSDate,
            startOfDay as NSDate
        )
        memoRequest.sortDescriptors = [NSSortDescriptor(key: "nextReviewDate", ascending: true)]

        let remainingReviews: Int
        let topMemoTitle: String?
        do {
            let memos = try context.fetch(memoRequest)
            remainingReviews = memos.count
            topMemoTitle = memos.first?.value(forKey: "title") as? String
        } catch {
            remainingReviews = 0
            topMemoTitle = nil
        }

        // カウントダウン計算
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        let diff = calendar.dateComponents([.hour, .minute], from: Date(), to: tomorrow)

        return RecallMateWidgetEntry(
            date: Date(),
            currentStreak: currentStreak,
            remainingReviews: remainingReviews,
            topMemoTitle: topMemoTitle,
            hoursUntilMidnight: diff.hour ?? 0,
            minutesUntilMidnight: diff.minute ?? 0
        )
    }

    private func makeContainer() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "RecallMate")

        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.tenten.RecallMate") {
            let storeURL = appGroupURL.appendingPathComponent("RecallMate.sqlite")
            let description = NSPersistentStoreDescription(url: storeURL)
            description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
            description.isReadOnly = true
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { _, error in
            if let error = error {
                print("Widget Core Data error: \(error)")
            }
        }

        return container
    }
}
