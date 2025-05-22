// SharedComponents.swift
import SwiftUI
import CoreData

// MARK: - 復習ステータス列挙型（アプリ全体で使用）
enum ReviewStatus {
    case overdue    // 期限切れ
    case dueToday   // 今日が復習日
    case scheduled  // 予定済み
    
    var color: Color {
        switch self {
        case .overdue: return .red
        case .dueToday: return .blue
        case .scheduled: return .green
        }
    }
    
    var description: String {
        switch self {
        case .overdue: return "復習期限切れ"
        case .dueToday: return "今日が復習日"
        case .scheduled: return "復習予定"
        }
    }
}

// MARK: - 日付情報ヘッダー（共通コンポーネント）
struct DayInfoHeader: View {
    let selectedDate: Date
    let memoCount: Int
    let selectedTags: [Tag]
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    // 日付表示
                    Text(dayText)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    // 記録数とフィルター状態の表示
                    HStack(spacing: 8) {
                        if memoCount > 0 {
                            Text("復習予定: \(memoCount)件")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        } else {
                            Text(selectedTags.isEmpty ? "復習予定はありません" : "条件に一致する記録はありません")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // タグフィルター適用中の表示
                        if !selectedTags.isEmpty {
                            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Spacer()
                
                // 今日かどうかのインジケーター
                if Calendar.current.isDateInToday(selectedDate) {
                    Text("今日")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    private var dayText: String {
        dateFormatter.dateFormat = "M月d日 (E)"
        return dateFormatter.string(from: selectedDate)
    }
}

// MARK: - 空の状態ビュー（共通コンポーネント）
struct EmptyStateView: View {
    let selectedDate: Date
    let hasTagFilter: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // アイコン表示
            Image(systemName: hasTagFilter ? "line.3.horizontal.decrease.circle" : "calendar.badge.checkmark")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            // メインメッセージ
            Text(emptyMessage)
                .font(.headline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            // サブメッセージ
            Text(subMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var emptyMessage: String {
        if hasTagFilter {
            return "条件に一致する記録はありません"
        } else if Calendar.current.isDateInToday(selectedDate) {
            return "今日の復習予定はありません"
        } else {
            return "この日の復習予定はありません"
        }
    }
    
    private var subMessage: String {
        if hasTagFilter {
            return "タグフィルターを変更するか、新しい記録を追加してみましょう"
        } else {
            return "新しい記録を追加して学習を始めましょう"
        }
    }
}

// MARK: - 拡張された復習アイテム（共通コンポーネント）
struct EnhancedReviewListItem: View {
    let memo: Memo
    let selectedDate: Date
    @Environment(\.colorScheme) var colorScheme
    
    // 復習ステータスの判定
    private var reviewStatus: ReviewStatus {
        guard let reviewDate = memo.nextReviewDate else { return .scheduled }
        
        let calendar = Calendar.current
        let selectedDay = calendar.startOfDay(for: selectedDate)
        let reviewDay = calendar.startOfDay(for: reviewDate)
        
        if reviewDay < selectedDay {
            return .overdue
        } else if calendar.isDate(reviewDay, inSameDayAs: selectedDay) {
            return .dueToday
        } else {
            return .scheduled
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // ステータスインジケーター
            Circle()
                .fill(reviewStatus.color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                // タイトル
                Text(memo.title ?? "無題")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                // 詳細情報行
                HStack(spacing: 8) {
                    // ページ範囲（存在する場合）
                    if let pageRange = memo.pageRange, !pageRange.isEmpty {
                        Text(pageRange)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // 復習ステータス
                    Text(reviewStatus.description)
                        .font(.caption)
                        .foregroundColor(reviewStatus.color)
                        .fontWeight(.medium)
                    
                    // 期限切れの場合は日数も表示
                    if reviewStatus == .overdue, let reviewDate = memo.nextReviewDate {
                        let days = Calendar.current.dateComponents([.day], from: reviewDate, to: Date()).day ?? 0
                        Text("(\(days)日経過)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                // タグ表示（最大3つまで）
                if !memo.tagsArray.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(memo.tagsArray.prefix(3), id: \.id) { tag in
                                HStack(spacing: 2) {
                                    Circle()
                                        .fill(tag.swiftUIColor())
                                        .frame(width: 6, height: 6)
                                    
                                    Text(tag.name ?? "")
                                        .font(.caption2)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(tag.swiftUIColor().opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            // 3つ以上のタグがある場合の省略表示
                            if memo.tagsArray.count > 3 {
                                Text("+\(memo.tagsArray.count - 3)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            // 記憶度スコア表示
            VStack(spacing: 2) {
                Text("\(memo.recallScore)%")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.retentionColor(for: memo.recallScore))
                
                Text("記憶度")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(
                    color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.05),
                    radius: 2,
                    x: 0,
                    y: 1
                )
        )
    }
}

// MARK: - フローティング追加ボタン（共通コンポーネント）
struct FloatingAddButton: View {
    @Binding var isAddingMemo: Bool
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    isAddingMemo = true
                }) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 8)
                }
                .padding(.trailing, 16)
                .padding(.bottom, 32)
            }
        }
    }
}
