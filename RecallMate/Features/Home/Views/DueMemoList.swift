// DueMemoList.swift - 期限超過 / 今日 のセクション分割リスト
import SwiftUI

struct DueMemoList: View {
    let overdueMemos: [Memo]
    let todayMemos: [Memo]
    let onTapMemo: (Memo) -> Void
    let onReviewMemo: (Memo) -> Void
    let onDeleteMemo: (Memo) -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // 期限超過セクション
            if !overdueMemos.isEmpty {
                sectionView(
                    title: "期限超過".localized,
                    count: overdueMemos.count,
                    color: .red,
                    memos: overdueMemos
                )
            }

            // 今日セクション
            if !todayMemos.isEmpty {
                sectionView(
                    title: "今日".localized,
                    count: todayMemos.count,
                    color: .blue,
                    memos: todayMemos
                )
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    // MARK: - Section

    private func sectionView(title: String, count: Int, color: Color, memos: [Memo]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // ヘッダー
            HStack(spacing: 8) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                    .textCase(.uppercase)

                Text("\(count)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(color)
                    .cornerRadius(4)

                Spacer()
            }
            .padding(.horizontal, 4)

            // メモ行
            ForEach(memos, id: \.id) { memo in
                CompactMemoRow(memo: memo, onTap: { onTapMemo(memo) })
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button {
                            onReviewMemo(memo)
                        } label: {
                            Label("復習".localized, systemImage: "play.fill")
                        }
                        .tint(.orange)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            onDeleteMemo(memo)
                        } label: {
                            Label("削除".localized, systemImage: "trash")
                        }
                    }
            }
        }
    }
}
