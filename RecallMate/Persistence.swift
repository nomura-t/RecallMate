import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    // ✅ `preview` を追加
    static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext

        // 📝 ダミーデータを 3 つ追加
        for i in 0..<3 {
            let newMemo = Memo(context: viewContext)
            newMemo.id = UUID()
            newMemo.title = "サンプルメモ \(i + 1)"
            newMemo.pageRange = "10-20"
            newMemo.content = "これはサンプルデータです。"
            newMemo.recallScore = Int16(arc4random_uniform(100))
            newMemo.lastReviewedDate = Date()
            newMemo.nextReviewDate = Calendar.current.date(byAdding: .day, value: i * 2, to: Date())
        }

        do {
            try viewContext.save()
        } catch {
            print("❌ プレビュー用データの保存に失敗: \(error)")
        }

        return controller
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "RecallMate")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        let description = container.persistentStoreDescriptions.first
                description?.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
                description?.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)

                container.loadPersistentStores { (storeDescription, error) in
                    if let error = error as NSError? {
                        fatalError("❌ Core Data の読み込みエラー: \(error)")
                    }
                }
    }
}
