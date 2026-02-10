// CompactMemoRow.swift - コンパクトなメモ行
import SwiftUI

struct CompactMemoRow: View {
    let memo: Memo
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 色ドット（記憶度）
                Circle()
                    .fill(scoreColor)
                    .frame(width: 10, height: 10)

                // タイトル
                Text(memo.title ?? "無題".localized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer()

                // 遅延バッジ（期限超過時のみ）
                if let delay = overdueText {
                    Text(delay)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .cornerRadius(4)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Computed

    private var scoreColor: Color {
        getRetentionColor(for: memo.recallScore)
    }

    private var overdueText: String? {
        guard let date = memo.nextReviewDate else { return nil }
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        guard date < startOfToday else { return nil }
        let days = calendar.dateComponents([.day], from: date, to: Date()).day ?? 0
        guard days > 0 else { return nil }
        return String(format: "%d日遅れ".localized, days)
    }
}
