// EmptyStateView.swift - リデザイン版
import SwiftUI

struct EmptyStateView: View {
    var hasTagFilter: Bool = false
    var onAddMemo: (() -> Void)?

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // アイコン
            ZStack {
                Circle()
                    .fill(iconBackgroundColor.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: iconName)
                    .font(.system(size: 44))
                    .foregroundColor(iconBackgroundColor)
            }

            // テキスト
            VStack(spacing: AppTheme.Spacing.sm) {
                Text(titleMessage)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                Text(subtitleMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, AppTheme.Spacing.lg)

            // CTAボタン
            if !hasTagFilter, let onAddMemo = onAddMemo {
                Button(action: onAddMemo) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                        Text("メモを追加".localized)
                            .fontWeight(.semibold)
                    }
                    .themePrimaryButton()
                }
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.top, AppTheme.Spacing.sm)
            }

            // フィルター解除ヒント
            if hasTagFilter {
                HStack(spacing: 6) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.caption)
                    Text("フィルターを解除すると、他の記録も表示されます".localized)
                        .font(.caption)
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.08))
                .cornerRadius(AppTheme.Radius.sm)
            }
        }
        .padding(.vertical, 48)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    // MARK: - Computed Properties

    private var iconName: String {
        if hasTagFilter {
            return "line.3.horizontal.decrease.circle"
        }
        return "brain.head.profile"
    }

    private var iconBackgroundColor: Color {
        if hasTagFilter {
            return .blue
        }
        return .orange
    }

    private var titleMessage: String {
        if hasTagFilter {
            return "選択されたタグの復習記録がありません".localized
        }
        return "復習するメモがありません".localized
    }

    private var subtitleMessage: String {
        if hasTagFilter {
            return "別のタグを選択するか、フィルターを解除してください".localized
        }
        return "新しいメモを追加して学習を始めましょう".localized
    }
}
