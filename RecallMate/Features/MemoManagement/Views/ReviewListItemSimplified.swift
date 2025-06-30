// ReviewListItemSimplified.swift - モーダル管理を含まないシンプルなカードコンポーネント
import SwiftUI

struct ReviewListItemSimplified: View {
    let memo: Memo
    let selectedDate: Date
    let onStartReview: () -> Void
    let onOpenMemo: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    // 日付関連の計算プロパティ（既存と同じ）
    private var isOverdue: Bool {
        guard let reviewDate = memo.nextReviewDate else { return false }
        return Calendar.current.startOfDay(for: reviewDate) < Calendar.current.startOfDay(for: Date())
    }
    
    private var isDueToday: Bool {
        guard let reviewDate = memo.nextReviewDate else { return false }
        return Calendar.current.isDateInToday(reviewDate)
    }
    
    private var daysOverdue: Int {
        guard let reviewDate = memo.nextReviewDate, isOverdue else { return 0 }
        return Calendar.current.dateComponents([.day], from: reviewDate, to: Date()).day ?? 0
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // メインコンテンツエリア（既存と同じレイアウト）
            Button(action: onOpenMemo) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(memo.title ?? "無題".localized)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        
                        HStack {
                            if let pageRange = memo.pageRange, !pageRange.isEmpty {
                                Text("(\(pageRange))")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }

                        HStack {
                            Text(reviewDateText)
                                .font(.subheadline)
                                .foregroundColor(isOverdue ? .blue : (isDueToday ? .blue : .gray))
                            
                            if isOverdue && daysOverdue > 0 {
                                Text("(%d日経過)".localizedWithInt(daysOverdue))
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // タグ表示（既存と同じ）
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
                                                .foregroundColor(tag.swiftUIColor())
                                        }
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(tag.swiftUIColor().opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                    
                                    if memo.tagsArray.count > 3 {
                                        Text("+\(memo.tagsArray.count - 3)")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                            .padding(.horizontal, 4)
                                    }
                                }
                            }
                            .frame(height: 20)
                        }
                    }

                    Spacer()

                    VStack(spacing: 4) {
                        Text("\(memo.recallScore)%")
                            .font(.headline)
                            .foregroundColor(progressColor(for: memo.recallScore))
                        
                        Text("記憶度")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 復習ボタンエリア - モーダル管理を含まない
            HStack(spacing: 16) {
                Button(action: {
                    onStartReview()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 18))
                        Text("復習を始める")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(22)
                    .shadow(
                        color: Color.blue.opacity(0.3),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onOpenMemo) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                        .frame(width: 44, height: 44)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(22)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(backgroundColorForState)
                .shadow(
                    color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1),
                    radius: colorScheme == .dark ? 3 : 2,
                    x: 0,
                    y: colorScheme == .dark ? 2 : 1
                )
        )
    }
    
    // ヘルパーメソッド（既存と同じ）
    private var backgroundColorForState: Color {
        if isOverdue {
            return Color.blue.opacity(colorScheme == .dark ? 0.2 : 0.1)
        } else if isDueToday {
            return Color.blue.opacity(colorScheme == .dark ? 0.2 : 0.1)
        } else {
            return colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground)
        }
    }
    
    private var reviewDateText: String {
        if isOverdue {
            return "復習予定日: %@".localizedFormat(formattedDate(memo.nextReviewDate))
        } else if isDueToday {
            return "今日が復習日".localized
        } else {
            return "復習日: %@".localizedFormat(formattedDate(memo.nextReviewDate))
        }
    }

    private func progressColor(for score: Int16) -> Color {
        switch score {
        case 0..<40: return Color.red
        case 40..<70: return Color.yellow
        default: return Color.green
        }
    }

    private func formattedDate(_ date: Date?) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return date != nil ? formatter.string(from: date!) : "未定".localized
    }
}
