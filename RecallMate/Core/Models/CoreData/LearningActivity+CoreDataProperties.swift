//
//  LearningActivity+CoreDataProperties.swift
//  RecallMate
//
//  Created by 野村哲裕 on 2025/05/21.
//
//

import Foundation
import CoreData


extension LearningActivity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LearningActivity> {
        return NSFetchRequest<LearningActivity>(entityName: "LearningActivity")
    }

    @NSManaged public var color: String?
    @NSManaged public var date: Date?
    @NSManaged public var durationMinutes: Int16
    @NSManaged public var id: UUID?
    @NSManaged public var note: String?
    @NSManaged public var type: String?
    @NSManaged public var durationSeconds: Int32
    @NSManaged public var memo: Memo?

}

extension LearningActivity : Identifiable {

}
