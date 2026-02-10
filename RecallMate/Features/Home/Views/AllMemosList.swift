// AllMemosList.swift - 全メモリスト（nextReviewDate順）
import SwiftUI
import CoreData

struct AllMemosList: View {
    let memos: [Memo]
    let onTapMemo: (Memo) -> Void
    let onReviewMemo: (Memo) -> Void
    let onDeleteMemo: (Memo) -> Void

    var body: some View {
        if memos.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "tray")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary.opacity(0.5))
                Text("メモがありません".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        } else {
            VStack(spacing: AppTheme.Spacing.sm) {
                // ヘッダー
                HStack {
                    Text("すべてのメモ".localized)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(memos.count)" + "件".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(8)
                }
                .padding(.horizontal, 12)

                ForEach(memos, id: \.id) { memo in
                    CompactMemoRow(memo: memo, onTap: { onTapMemo(memo) })
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                onDeleteMemo(memo)
                            } label: {
                                Label("削除".localized, systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                onReviewMemo(memo)
                            } label: {
                                Label("復習".localized, systemImage: "arrow.clockwise")
                            }
                            .tint(.orange)
                        }
                }
            }
            .padding(.horizontal, 12)
        }
    }
}

// MARK: - AllMemoRow (復習日付き)

struct AllMemoRow: View {
    let memo: Memo
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 色ドット
                Circle()
                    .fill(getRetentionColor(for: memo.recallScore))
                    .frame(width: 10, height: 10)

                // タイトル
                VStack(alignment: .leading, spacing: 2) {
                    Text(memo.title ?? "無題".localized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if let date = memo.nextReviewDate {
                        Text(formatDateForDisplay(date))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // スコア
                Text("\(Int(memo.recallScore))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(getRetentionColor(for: memo.recallScore))

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
}
