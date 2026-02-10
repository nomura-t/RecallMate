import CoreData

public struct PersistenceController {
    public static let shared = PersistenceController()

    /// App Group identifier for sharing data with Widget
    static let appGroupIdentifier = "group.tenten.RecallMate"

    static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext

        for i in 0..<3 {
            let newMemo = Memo(context: viewContext)
            newMemo.id = UUID()
            newMemo.title = "サンプル記録 \(i + 1)"
            newMemo.pageRange = "10-20"
            newMemo.content = "これはサンプルデータです。"
            newMemo.recallScore = Int16(arc4random_uniform(100))
            newMemo.lastReviewedDate = Date()
            newMemo.nextReviewDate = Calendar.current.date(byAdding: .day, value: i * 2, to: Date())
        }

        do {
            try viewContext.save()
        } catch {
        }

        return controller
    }()

    public let container: NSPersistentContainer

    public init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "RecallMate")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // App Groups 共有ストアへマイグレーション
            if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: PersistenceController.appGroupIdentifier) {
                let storeURL = appGroupURL.appendingPathComponent("RecallMate.sqlite")
                let description = container.persistentStoreDescriptions.first

                // 旧ストアが存在し、新ストアが未作成の場合はマイグレーション
                let oldStoreURL = description?.url
                if let oldURL = oldStoreURL,
                   FileManager.default.fileExists(atPath: oldURL.path),
                   !FileManager.default.fileExists(atPath: storeURL.path) {
                    migrateStore(from: oldURL, to: storeURL)
                }

                description?.url = storeURL
            }
        }

        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description?.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)

        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Core Data の読み込みエラー: \(error)")
            }
        }
    }

    /// 旧ストアから App Groups ストアへの一回限りのマイグレーション
    private func migrateStore(from sourceURL: URL, to destinationURL: URL) {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: container.managedObjectModel)

        do {
            let sourceStore = try coordinator.addPersistentStore(
                ofType: NSSQLiteStoreType,
                configurationName: nil,
                at: sourceURL,
                options: [
                    NSMigratePersistentStoresAutomaticallyOption: true,
                    NSInferMappingModelAutomaticallyOption: true
                ]
            )

            try coordinator.migratePersistentStore(
                sourceStore,
                to: destinationURL,
                options: nil,
                type: .sqlite
            )
        } catch {
            print("Core Data マイグレーションエラー: \(error)")
        }
    }
}
