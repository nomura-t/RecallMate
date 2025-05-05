// RecallMate/ReviewListItem.swift
import SwiftUI

struct ReviewListItem: View {
    let memo: Memo
    @Environment(\.colorScheme) var colorScheme
    
    // 日付の状態を判定するプロパティ
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
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                // タイトルとページ範囲を表示
                HStack {
                    Text(memo.title ?? "無題")
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
                    // 復習日ラベル - 状態によって表示を変更
                    Text(reviewDateText)
                        .font(.subheadline)
                        .foregroundColor(isOverdue ? .blue : (isDueToday ? .blue : .gray))
                    
                    // 遅延日数を表示（遅延の場合のみ）
                    if isOverdue && daysOverdue > 0 {
                        Text("(\(daysOverdue)日経過)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }

            Spacer()

            Text("\(memo.recallScore)%")
                .font(.headline)
                .foregroundColor(progressColor(for: memo.recallScore))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(backgroundColorForState)
                .shadow(
                    color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1),
                    radius: colorScheme == .dark ? 2 : 1,
                    x: 0,
                    y: colorScheme == .dark ? 1 : 1
                )
        )
    }
    
    // 状態に応じた背景色（ダークモード対応）
    private var backgroundColorForState: Color {
        if isOverdue {
            return Color.blue.opacity(colorScheme == .dark ? 0.2 : 0.1)
        } else if isDueToday {
            return Color.blue.opacity(colorScheme == .dark ? 0.2 : 0.1)
        } else {
            return colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground)
        }
    }
    
    // 状態に応じた優先度表示の色
    private var priorityColor: Color {
        if isOverdue {
            return .blue
        } else if isDueToday {
            return .blue
        } else {
            return progressColor(for: memo.recallScore)
        }
    }
    
    // 復習日の表示テキスト
    private var reviewDateText: String {
        if isOverdue {
            return "復習予定日: \(formattedDate(memo.nextReviewDate))"
        } else if isDueToday {
            return "今日が復習日"
        } else {
            return "復習日: \(formattedDate(memo.nextReviewDate))"
        }
    }

    // 記憶度に応じたカラー
    private func progressColor(for score: Int16) -> Color {
        switch score {
        case 0..<40:
            return Color.red
        case 40..<70:
            return Color.yellow
        default:
            return Color.green
        }
    }

    // 日付をフォーマット
    private func formattedDate(_ date: Date?) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return date != nil ? formatter.string(from: date!) : "未定"
    }
}
