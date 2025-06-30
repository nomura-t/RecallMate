// DayInfoHeaderView.swift
import SwiftUI

/// 選択された日付の情報を表示するヘッダーコンポーネント
///
/// このコンポーネントは以下の責務を持ちます：
/// - 日付の文脈的な表示（今日、過去、未来の適切な表現）
/// - メモ数の表示
/// - フィルター状態の表示
struct DayInfoHeaderView: View {
    /// 表示対象の日付
    let selectedDate: Date
    
    /// 該当日のメモ数
    let memoCount: Int
    
    /// 現在選択されているタグ（フィルター表示用）
    let selectedTags: [Tag]
    
    /// 日付表示用のフォーマッター
    /// 日本語ロケールを使用して適切な日付表現を提供します
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .medium
        return formatter
    }()
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                // メインタイトル：日付の文脈に応じた適切な表現
                Text(dateText)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                // サブタイトル：メモ数とフィルター状態の表示
                if !selectedTags.isEmpty || memoCount > 0 {
                    HStack(spacing: 8) {
                        // メモ数の表示
                        Text("\(memoCount)件の記録")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // フィルター状態の表示
                        if !selectedTags.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                
                                Text("フィルター適用中")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    /// 日付の文脈に応じた適切なテキストを生成
    /// カレンダーの概念を活用して、ユーザーにとって理解しやすい表現を提供します
    private var dateText: String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(selectedDate) {
            return "今日の復習"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "昨日の復習"
        } else if calendar.isDateInTomorrow(selectedDate) {
            return "明日の復習予定"
        } else {
            // より詳細な日付表現
            return dateFormatter.string(from: selectedDate) + "の復習"
        }
    }
}

