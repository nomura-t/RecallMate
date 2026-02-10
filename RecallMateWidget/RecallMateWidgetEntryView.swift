import SwiftUI
import WidgetKit

struct RecallMateWidgetEntryView: View {
    var entry: RecallMateWidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }

    // MARK: - Small Widget

    private var smallWidget: some View {
        VStack(spacing: 8) {
            // ストリーク数
            Text("\(entry.currentStreak)")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("日連続")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))

            Spacer()

            // 残り件数
            HStack(spacing: 4) {
                Image(systemName: entry.remainingReviews > 0 ? "book.fill" : "checkmark.seal.fill")
                    .font(.caption2)
                if entry.remainingReviews > 0 {
                    Text("残り\(entry.remainingReviews)件")
                        .font(.caption2)
                        .fontWeight(.semibold)
                } else {
                    Text("完了！")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(.white.opacity(0.9))
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(streakGradient)
        .widgetURL(URL(string: "recallmate://review"))
    }

    // MARK: - Medium Widget

    private var mediumWidget: some View {
        HStack(spacing: 16) {
            // 左: ストリーク
            VStack(spacing: 4) {
                Text("\(entry.currentStreak)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("日連続")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(width: 80)

            // 右: 情報
            VStack(alignment: .leading, spacing: 8) {
                // 残り件数
                HStack(spacing: 6) {
                    Image(systemName: entry.remainingReviews > 0 ? "book.fill" : "checkmark.seal.fill")
                        .font(.caption)
                    if entry.remainingReviews > 0 {
                        Text("残り\(entry.remainingReviews)件の復習")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    } else {
                        Text("本日の復習完了！")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
                .foregroundColor(.white)

                // 最優先メモ
                if let title = entry.topMemoTitle, entry.remainingReviews > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        Text(title)
                            .font(.caption)
                            .lineLimit(1)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }

                Spacer()

                // カウントダウン
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("残り\(entry.hoursUntilMidnight)時間\(entry.minutesUntilMidnight)分")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(entry.hoursUntilMidnight < 2 ? .red : .white.opacity(0.7))
            }

            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(streakGradient)
        .widgetURL(URL(string: "recallmate://review"))
    }

    // MARK: - Helper

    private var streakGradient: LinearGradient {
        let color: Color = {
            if entry.currentStreak >= 30 { return .orange }
            if entry.currentStreak >= 7 { return .red }
            if entry.currentStreak >= 1 { return .blue }
            return .gray
        }()

        return LinearGradient(
            colors: [color, color.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
