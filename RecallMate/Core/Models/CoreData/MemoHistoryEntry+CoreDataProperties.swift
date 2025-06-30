//
//  MemoHistoryEntry+CoreDataProperties.swift
//  RecallMate
//
//  Created by 野村哲裕 on 2025/03/16.
//
//

import Foundation
import CoreData


extension MemoHistoryEntry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MemoHistoryEntry> {
        return NSFetchRequest<MemoHistoryEntry>(entityName: "MemoHistoryEntry")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var recallScore: Int16
    @NSManaged public var retentionScore: Int16
    @NSManaged public var memo: Memo?

}
