import Foundation
import CoreData
import SwiftUI

/// 記録のデータ状態を診断するためのユーティリティクラス
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
    
    /// 記録の全状態をログ出力
    func logMemoState(_ memo: Memo, prefix: String = "") {
        // 履歴エントリの詳細
        if !memo.historyEntriesArray.isEmpty {
            for (index, entry) in memo.historyEntriesArray.prefix(5).enumerated() {
            }
            
            // 履歴が多い場合は省略表示
            if memo.historyEntriesArray.count > 5 {
            }
        }
    }
    
    /// 記録のリストを診断
    func diagnoseMemoList(_ memos: [Memo]) {
        // 記録を復習日でソート
        let sortedMemos = memos.sorted {
            ($0.nextReviewDate ?? Date.distantFuture) < ($1.nextReviewDate ?? Date.distantFuture)
        }
        
        // 今日の日付
        let today = Calendar.current.startOfDay(for: Date())
        
        // 復習期限切れの記録をカウント
        let overdueCount = sortedMemos.filter { memo in
            guard let reviewDate = memo.nextReviewDate else { return false }
            return Calendar.current.startOfDay(for: reviewDate) < today
        }.count
        
        // 今日が復習日の記録をカウント
        let todayCount = sortedMemos.filter { memo in
            guard let reviewDate = memo.nextReviewDate else { return false }
            return Calendar.current.isDateInToday(reviewDate)
        }.count
        // 最初の5件の詳細を表示
        for (index, memo) in sortedMemos.prefix(5).enumerated() {
        }
    }
    
    /// CoreDataの状態を診断
    func diagnoseContext(_ context: NSManagedObjectContext) {
        if context.hasChanges {
        } else {
        }
    }
    
    // 日付をフォーマット
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "未設定" }
        return dateFormatter.string(from: date)
    }
}
