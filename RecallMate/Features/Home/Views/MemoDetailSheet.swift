// MemoDetailSheet.swift - メモ詳細ハーフシート
import SwiftUI

struct MemoDetailSheet: View {
    let memo: Memo
    let onReview: () -> Void
    let onEdit: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // タイトル
                    Text(memo.title ?? "無題".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    // スコアリング
                    HStack(spacing: 16) {
                        scoreCard(
                            label: "記憶度".localized,
                            value: "\(memo.recallScore)%",
                            color: getRetentionColor(for: memo.recallScore)
                        )

                        if let lastReview = memo.lastReviewedDate {
                            scoreCard(
                                label: "最終復習".localized,
                                value: formatRelativeDate(lastReview),
                                color: .blue
                            )
                        }
                    }

                    // メタデータ
                    VStack(alignment: .leading, spacing: 12) {
                        if let pageRange = memo.pageRange, !pageRange.isEmpty {
                            metaRow(icon: "book", label: "ページ範囲".localized, value: pageRange)
                        }

                        if let nextReview = memo.nextReviewDate {
                            metaRow(icon: "calendar", label: "次回復習日".localized, value: formatDateForDisplay(nextReview))
                        }

                        if let createdAt = memo.createdAt {
                            metaRow(icon: "clock", label: "作成日".localized, value: formatDateForDisplay(createdAt))
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                            .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.secondarySystemBackground))
                    )

                    // 復習履歴（最新5件）
                    if !memo.historyEntriesArray.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("復習履歴".localized)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)

                            ForEach(memo.historyEntriesArray.prefix(5), id: \.id) { entry in
                                HStack {
                                    Circle()
                                        .fill(getRetentionColor(for: entry.recallScore))
                                        .frame(width: 8, height: 8)
                                    Text("\(entry.recallScore)%")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Spacer()
                                    if let date = entry.date {
                                        Text(formatDateForDisplay(date))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                                .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.secondarySystemBackground))
                        )
                    }

                    // アクションボタン
                    HStack(spacing: 12) {
                        Button(action: {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onReview()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 12))
                                Text("復習する".localized)
                                    .fontWeight(.semibold)
                            }
                            .themePrimaryButton()
                        }

                        Button(action: {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onEdit()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 12))
                                Text("編集".localized)
                                    .fontWeight(.semibold)
                            }
                            .themeSecondaryButton()
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.top, AppTheme.Spacing.md)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる".localized) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.65), .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Subviews

    private func scoreCard(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                .fill(color.opacity(0.08))
        )
    }

    private func metaRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 16)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }

    private func formatRelativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "今日".localized }
        if calendar.isDateInYesterday(date) { return "昨日".localized }
        let days = calendar.dateComponents([.day], from: date, to: Date()).day ?? 0
        return String(format: "%d日前".localized, days)
    }
}

