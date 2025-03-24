//
//  StreakData+CoreDataProperties.swift
//  RecallMate
//
//  Created by 野村哲裕 on 2025/03/07.
//
//

import Foundation
import CoreData


extension StreakData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StreakData> {
        return NSFetchRequest<StreakData>(entityName: "StreakData")
    }

    @NSManaged public var currentStreak: Int16
    @NSManaged public var longestStreak: Int16
    @NSManaged public var lastActiveDate: Date?
    @NSManaged public var streakStartDate: Date?

}

extension StreakData : Identifiable {

}
