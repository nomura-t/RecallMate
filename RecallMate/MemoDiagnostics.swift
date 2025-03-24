import Foundation
import CoreData
import SwiftUI

/// メモのデータ状態を診断するためのユーティリティクラス
class MemoDiagnostics {
    static let shared = MemoDiagnostics()
    
    private init() {}
    
    // 日付フォーマッタ
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    /// メモの全状態をログ出力
    func logMemoState(_ memo: Memo, prefix: String = "") {
        print("\(prefix)📝 メモ詳細: \(memo.title ?? "無題")")
        print("\(prefix)- ID: \(memo.id?.uuidString ?? "不明")")
        print("\(prefix)- 完璧回数: \(memo.perfectRecallCount)")
        print("\(prefix)- 記憶度: \(memo.recallScore)%")
        print("\(prefix)- 最終復習日: \(formatDate(memo.lastReviewedDate))")
        print("\(prefix)- 次回復習日: \(formatDate(memo.nextReviewDate))")
        print("\(prefix)- 履歴エントリ数: \(memo.historyEntriesArray.count)")
        
        // 履歴エントリの詳細
        if !memo.historyEntriesArray.isEmpty {
            print("\(prefix)- 履歴エントリ:")
            for (index, entry) in memo.historyEntriesArray.prefix(5).enumerated() {
                print("\(prefix)  [\(index+1)] 日時: \(formatDate(entry.date)), 記憶度: \(entry.recallScore)%, 定着度: \(entry.retentionScore)%")
            }
            
            // 履歴が多い場合は省略表示
            if memo.historyEntriesArray.count > 5 {
                print("\(prefix)  ... (他\(memo.historyEntriesArray.count - 5)件)")
            }
        }
    }
    
    /// メモのリストを診断
    func diagnoseMemoList(_ memos: [Memo]) {
        print("📊 メモ一覧診断 (\(memos.count)件)")
        print("- 現在時刻: \(dateFormatter.string(from: Date()))")
        
        // メモを復習日でソート
        let sortedMemos = memos.sorted {
            ($0.nextReviewDate ?? Date.distantFuture) < ($1.nextReviewDate ?? Date.distantFuture)
        }
        
        // 今日の日付
        let today = Calendar.current.startOfDay(for: Date())
        
        // 復習期限切れのメモをカウント
        let overdueCount = sortedMemos.filter { memo in
            guard let reviewDate = memo.nextReviewDate else { return false }
            return Calendar.current.startOfDay(for: reviewDate) < today
        }.count
        
        // 今日が復習日のメモをカウント
        let todayCount = sortedMemos.filter { memo in
            guard let reviewDate = memo.nextReviewDate else { return false }
            return Calendar.current.isDateInToday(reviewDate)
        }.count
        
        print("- 復習期限切れ: \(overdueCount)件")
        print("- 今日が復習日: \(todayCount)件")
        print("- その他: \(memos.count - overdueCount - todayCount)件")
        
        // 最初の5件の詳細を表示
        print("- 直近の復習予定メモ:")
        for (index, memo) in sortedMemos.prefix(5).enumerated() {
            print("  [\(index+1)] \(memo.title ?? "無題") - 次回復習日: \(formatDate(memo.nextReviewDate))")
        }
    }
    
    /// CoreDataの状態を診断
    func diagnoseContext(_ context: NSManagedObjectContext) {
        print("🔍 CoreData診断:")
        print("- 挿入されたオブジェクト: \(context.insertedObjects.count)")
        print("- 更新されたオブジェクト: \(context.updatedObjects.count)")
        print("- 削除されたオブジェクト: \(context.deletedObjects.count)")
        print("- 変更の合計: \(context.insertedObjects.count + context.updatedObjects.count + context.deletedObjects.count)")
        
        if context.hasChanges {
            print("⚠️ 未保存の変更があります")
        } else {
            print("✅ 未保存の変更はありません")
        }
    }
    
    // 日付をフォーマット
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "未設定" }
        return dateFormatter.string(from: date)
    }
}
