import Foundation
import CoreData
import SwiftUI   // Colorのため
import UIKit     // UIColorのため


extension Tag {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Tag> {
        return NSFetchRequest<Tag>(entityName: "Tag")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var color: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var memos: NSSet?
    
    // タグに関連付けられた記録の配列
    var memosArray: [Memo] {
        let set = memos as? Set<Memo> ?? []
        return Array(set).sorted { ($0.title ?? "") < ($1.title ?? "") }
    }
    
    // 色のUIColor変換
    func uiColor() -> UIColor {
        switch color?.lowercased() {
        case "red": return .systemRed
        case "orange": return .systemOrange
        case "yellow": return .systemYellow
        case "green": return .systemGreen
        case "blue": return .systemBlue
        case "purple": return .systemPurple
        case "pink": return .systemPink
        default: return .systemBlue // デフォルト色
        }
    }
    
    // 色のColor変換（SwiftUI用）
    // SwiftUI Colorに変換するためのヘルパーメソッド
    func swiftUIColor() -> Color {
        if let colorName = self.color {
            return TagService.shared.colorFromString(colorName)
        }
        return .blue // デフォルト色
    }
}

// MARK: Generated accessors for memos
extension Tag {

    @objc(addMemosObject:)
    @NSManaged public func addToMemos(_ value: Memo)

    @objc(removeMemosObject:)
    @NSManaged public func removeFromMemos(_ value: Memo)

    @objc(addMemos:)
    @NSManaged public func addToMemos(_ values: NSSet)

    @objc(removeMemos:)
    @NSManaged public func removeFromMemos(_ values: NSSet)

}

extension Tag : Identifiable {

}
