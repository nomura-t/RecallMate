import SwiftUI

struct ReviewListItem: View {
    let memo: Memo
    
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
            // 優先度インジケーター（円）- 状態によって色を変更
            Circle()
                .fill(priorityColor)
                .frame(width: 20, height: 20)
                .shadow(radius: 2)
                .padding(.trailing, 8)
                .overlay(
                    // 期限切れの場合は感嘆符を表示
                    Group {
                        if isOverdue {
                            Image(systemName: "exclamationmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        } else if isDueToday {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                )

            VStack(alignment: .leading, spacing: 4) {
                // タイトルとページ範囲を表示
                HStack {
                    Text(memo.title ?? "無題")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
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
                        .foregroundColor(isOverdue ? .red : (isDueToday ? .blue : .gray))
                    
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
                .shadow(radius: 1)
        )
    }
    
    // 状態に応じた背景色
    private var backgroundColorForState: Color {
        if isOverdue {
            return Color.red.opacity(0.1)
        } else if isDueToday {
            return Color.blue.opacity(0.1)
        } else {
            return Color(.systemBackground)
        }
    }
    
    // 状態に応じた優先度表示の色
    private var priorityColor: Color {
        if isOverdue {
            return .red
        } else if isDueToday {
            return .blue
        } else {
            return progressColor(for: memo.recallScore)
        }
    }
    
    // 復習日の表示テキスト
    private var reviewDateText: String {
        if isOverdue {
            return "期限切れ: \(formattedDate(memo.nextReviewDate))"
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
