// TagService.swift
import Foundation
import CoreData
import SwiftUI

class TagService {
    static let shared = TagService()
    
    private init() {}
    
    // 利用可能な色のリスト
    let availableColors = [
        // 基本色
        "red", "orange", "yellow", "green", "blue", "purple", "pink",
        
        // 追加色 - 明るい色
        "lightBlue", "lightGreen", "lightPink", "lightPurple", "cyan", "teal",
        
        // 追加色 - 暗い色
        "darkBlue", "darkGreen", "darkRed", "brown", "navy", "indigo",
        
        // 追加色 - グレースケール
        "black", "gray", "lightGray"
    ]
    
    // 新しいタグを作成
    func createTag(name: String, color: String, in context: NSManagedObjectContext) -> Tag? {
        // 同じ名前のタグがないか確認
        let existingTag = findTag(byName: name, in: context)
        if existingTag != nil {
            return existingTag
        }
        
        // 新しいタグを作成
        let newTag = Tag(context: context)
        newTag.id = UUID()
        newTag.name = name
        newTag.color = color
        newTag.createdAt = Date()
        
        do {
            try context.save()
            return newTag
        } catch {
            print("タグ作成エラー: \(error.localizedDescription)")
            return nil
        }
    }
    
    // 名前でタグを検索
    func findTag(byName name: String, in context: NSManagedObjectContext) -> Tag? {
        let request: NSFetchRequest<Tag> = Tag.fetchRequest()
        request.predicate = NSPredicate(format: "name ==[c] %@", name)
        
        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            print("タグ検索エラー: \(error.localizedDescription)")
            return nil
        }
    }
    
    // 全タグを取得
    func getAllTags(in context: NSManagedObjectContext) -> [Tag] {
        let request: NSFetchRequest<Tag> = Tag.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("タグ取得エラー: \(error.localizedDescription)")
            return []
        }
    }
    
    // タグを削除
    func deleteTag(_ tag: Tag, in context: NSManagedObjectContext) -> Bool {
        context.delete(tag)
        
        do {
            try context.save()
            return true
        } catch {
            print("タグ削除エラー: \(error.localizedDescription)")
            return false
        }
    }
    
    // 色文字列からSwiftUI Colorに変換
    func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        // 基本色
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        
        // 追加色 - 明るい色
        case "lightblue": return Color(red: 0.4, green: 0.7, blue: 1.0)
        case "lightgreen": return Color(red: 0.6, green: 0.9, blue: 0.6)
        case "lightpink": return Color(red: 1.0, green: 0.7, blue: 0.8)
        case "lightpurple": return Color(red: 0.8, green: 0.7, blue: 1.0)
        case "cyan": return Color.cyan
        case "teal": return Color.teal
        
        // 追加色 - 暗い色
        case "darkblue": return Color(red: 0.0, green: 0.2, blue: 0.6)
        case "darkgreen": return Color(red: 0.0, green: 0.5, blue: 0.0)
        case "darkred": return Color(red: 0.6, green: 0.0, blue: 0.0)
        case "brown": return Color.brown
        case "navy": return Color(red: 0.0, green: 0.0, blue: 0.5)
        case "indigo": return Color.indigo
        
        // 追加色 - グレースケール
        case "black": return Color.black
        case "gray": return Color.gray
        case "lightgray": return Color.gray.opacity(0.5)
        
        // デフォルト
        default: return .blue
        }
    }
}
