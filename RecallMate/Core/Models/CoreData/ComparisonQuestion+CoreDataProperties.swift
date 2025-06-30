import Foundation
import CoreData


extension ComparisonQuestion {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ComparisonQuestion> {
        return NSFetchRequest<ComparisonQuestion>(entityName: "ComparisonQuestion")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var question: String?
    @NSManaged public var note: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var answer: String?
    @NSManaged public var memo: Memo?

}

extension ComparisonQuestion : Identifiable {

}
