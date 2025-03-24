import Foundation
import CoreData

extension LearningActivity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LearningActivity> {
        return NSFetchRequest<LearningActivity>(entityName: "LearningActivity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var type: String?
    @NSManaged public var durationMinutes: Int16
    @NSManaged public var note: String?
    @NSManaged public var color: String?
    @NSManaged public var memo: Memo?
}

extension LearningActivity : Identifiable {
    // Identifiableプロトコルの要件を満たす
}
