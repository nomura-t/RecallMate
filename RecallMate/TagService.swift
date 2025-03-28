import Foundation
import CoreData
import SwiftUI

class TagService {
    static let shared = TagService()
    
    private init() {}
    
    // 利用可能な色のリスト - すべて小文字に統一
    let availableColors = [
        // 基本色
        "red", "orange", "yellow", "green", "blue", "purple", "pink",
        
        // 追加色 - 明るい色
        "lightblue", "lightgreen", "lightpink", "lightpurple", "cyan", "teal",
        
        // 追加色 - 暗い色
        "darkblue", "darkgreen", "darkred", "brown", "navy", "indigo",
        
        // 追加色 - グレースケール
        "black", "gray", "lightgray"
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
        // 色を小文字に統一して保存
        newTag.color = color.lowercased()
        newTag.createdAt = Date()
        
        do {
            try context.save()
            return newTag
        } catch {
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
            return false
        }
    }
    
    // タグを編集するメソッド（throwsなし）
    func editTag(
        _ tag: Tag,
        newName: String? = nil,
        newColor: String? = nil,
        in context: NSManagedObjectContext
    ) -> Bool {
        var modified = false
        do {
            // 名前の変更がある場合
            if let newName = newName, !newName.isEmpty {
                let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // 同じ名前のタグが既に存在するかチェック（自分自身を除く）
                if let tagId = tag.id {
                    let fetchRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "name ==[c] %@ AND id != %@", trimmedName, tagId as CVarArg)
                    
                    let existingTags = try context.fetch(fetchRequest)
                    guard existingTags.isEmpty else {
                        // 同じ名前のタグが既に存在する
                        return false
                    }
                }
                
                // 名前を更新
                if tag.name != trimmedName {
                    tag.name = trimmedName
                    modified = true
                }
            }
            
            // 色を更新（指定されている場合）
            if let newColor = newColor, !newColor.isEmpty {
                // 比較用に小文字に変換
                let normalizedNewColor = newColor.lowercased()
                let normalizedOldColor = tag.color?.lowercased() ?? ""
                
                // 色が実際に変更されている場合のみ更新
                if normalizedOldColor != normalizedNewColor {
                    // 色が有効か確認 - 無効な場合はデフォルト色を使用
                    if availableColors.contains(where: { $0.lowercased() == normalizedNewColor }) {
                        tag.color = normalizedNewColor
                        modified = true
                    } else {
                        // 無効な色の場合はデフォルト色を使用
                        tag.color = "blue"
                        modified = true
                    }
                }
            }
            
            // 変更があった場合のみ保存
            if modified {
                try context.save()
            } else {
            }
            
            return true
        } catch {
            context.rollback()
            return false
        }
    }
    
    // 色文字列からSwiftUI Colorに変換（throwsなし）
    func colorFromString(_ colorName: String) -> Color {
        let lowerName = colorName.lowercased()
        
        switch lowerName {
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
        default:
            return .blue
        }
    }
}
