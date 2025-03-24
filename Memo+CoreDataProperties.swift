import Foundation
import CoreData


import Foundation
import CoreData

extension Memo {
    var historyEntriesArray: [MemoHistoryEntry] {
        let set = historyEntries as? Set<MemoHistoryEntry> ?? []
        return set.sorted {
            ($0.date ?? Date()) > ($1.date ?? Date())
        }
    }
    
    var perfectRecallCount: Int16 {
        let highScoreEntries = historyEntriesArray.filter { $0.recallScore >= 90 }
        return Int16(highScoreEntries.count)
    }
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Memo> {
        return NSFetchRequest<Memo>(entityName: "Memo")
    }

    @NSManaged public var content: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var keywords: String?
    @NSManaged public var lastReviewedDate: Date?
    @NSManaged public var nextReviewDate: Date?
    @NSManaged public var pageRange: String?
    @NSManaged public var recallScore: Int16
    @NSManaged public var title: String?
    @NSManaged public var trashDate: Date?
    @NSManaged public var testDate: Date?
    @NSManaged public var tags: NSSet?  // この行を追加
    @NSManaged public var comparisonQuestions: NSSet?
    @NSManaged public var historyEntries: NSSet?
}

// MARK: Generated accessors for comparisonQuestions
extension Memo {

    @objc(addComparisonQuestionsObject:)
    @NSManaged public func addToComparisonQuestions(_ value: ComparisonQuestion)

    @objc(removeComparisonQuestionsObject:)
    @NSManaged public func removeFromComparisonQuestions(_ value: ComparisonQuestion)

    @objc(addComparisonQuestions:)
    @NSManaged public func addToComparisonQuestions(_ values: NSSet)

    @objc(removeComparisonQuestions:)
    @NSManaged public func removeFromComparisonQuestions(_ values: NSSet)

}

// MARK: Generated accessors for historyEntries
extension Memo {

    @objc(addHistoryEntriesObject:)
    @NSManaged public func addToHistoryEntries(_ value: MemoHistoryEntry)

    @objc(removeHistoryEntriesObject:)
    @NSManaged public func removeFromHistoryEntries(_ value: MemoHistoryEntry)

    @objc(addHistoryEntries:)
    @NSManaged public func addToHistoryEntries(_ values: NSSet)

    @objc(removeHistoryEntries:)
    @NSManaged public func removeFromHistoryEntries(_ values: NSSet)

}


extension Memo : Identifiable {

}

// 既存の拡張に以下を追加
// タグ関連メソッドの強化
extension Memo {
    // タグの配列を取得（既存のメソッドはそのまま）
    var tagsArray: [Tag] {
        let set = tags as? Set<Tag> ?? []
        return set.sorted { ($0.name ?? "") < ($1.name ?? "") }
    }
    
    // 指定されたタグがこのメモに関連づけられているかをチェック（既存のメソッドはそのまま）
    func hasTag(with id: UUID) -> Bool {
        return tagsArray.contains { $0.id == id }
    }
    
    // タグを追加（ログ機能を追加）
    func addTag(_ tag: Tag) {
        let currentTags = self.tags?.mutableCopy() as? NSMutableSet ?? NSMutableSet()
        let oldCount = currentTags.count
        
        currentTags.add(tag)
        self.tags = currentTags
        
        // 追加後の検証
        let newCount = (self.tags as? Set<Tag> ?? Set<Tag>()).count
        print("➕ タグを追加: \(tag.name ?? "無名") (ID: \(tag.id?.uuidString.prefix(8) ?? "不明")) - タグ数: \(oldCount) → \(newCount)")
    }
    
    // タグを削除（ログ機能を追加）
    func removeTag(_ tag: Tag) {
        let currentTags = self.tags?.mutableCopy() as? NSMutableSet ?? NSMutableSet()
        let oldCount = currentTags.count
        
        currentTags.remove(tag)
        self.tags = currentTags
        
        // 削除後の検証
        let newCount = (self.tags as? Set<Tag> ?? Set<Tag>()).count
        print("➖ タグを削除: \(tag.name ?? "無名") (ID: \(tag.id?.uuidString.prefix(8) ?? "不明")) - タグ数: \(oldCount) → \(newCount)")
    }
    
    // デバッグ用のタグ情報表示（新規追加）
    func logTagsInfo() {
        let tagArray = self.tagsArray
        if tagArray.isEmpty {
            print("📌 タグ情報: なし")
        } else {
            print("📌 タグ情報: \(tagArray.count)個")
            for (index, tag) in tagArray.enumerated() {
                print("  \(index+1). \(tag.name ?? "無名") (ID: \(tag.id?.uuidString.prefix(8) ?? "不明"))")
            }
        }
    }
}

