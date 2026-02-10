// PrimaryReviewButton.swift - メイン復習開始ボタン
import SwiftUI

struct PrimaryReviewButton: View {
    let remainingCount: Int
    let onStartReview: () -> Void

    private var isAllDone: Bool { remainingCount <= 0 }

    var body: some View {
        Button(action: {
            if !isAllDone {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                onStartReview()
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: isAllDone ? "checkmark.circle.fill" : "play.fill")
                    .font(.system(size: 16, weight: .semibold))

                Text(isAllDone ? "全て完了!".localized : "復習を始める".localized)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: isAllDone
                        ? [Color.green, Color.green.opacity(0.8)]
                        : [AppTheme.Colors.brand, AppTheme.Colors.brand.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(AppTheme.Radius.md)
        }
        .disabled(isAllDone)
        .opacity(isAllDone ? 0.7 : 1.0)
        .padding(.horizontal, AppTheme.Spacing.md)
    }
}
