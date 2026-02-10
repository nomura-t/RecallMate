// ActiveRecallStepView.swift - 新規学習・復習共通のアクティブリコールステップUI
import SwiftUI

/// 4マイクロステップのチェックリスト風アクティブリコールUI
/// 新規学習(Step1)と復習(Step0)で共有
struct ActiveRecallStepView: View {
    let memoTitle: String
    @Binding var microStep: Int // 0-3
    let elapsedTime: TimeInterval
    let onComplete: () -> Void // 全ステップ完了→評価へ

    private let steps: [(label: String, guide: String)] = [
        ("読む".localized, "学習した内容をよく読みましょう".localized),
        ("閉じる".localized, "教材を閉じてください".localized),
        ("思い出す".localized, "頭の中で内容を思い出してみましょう".localized),
        ("確認".localized, "教材を開いて答え合わせしましょう".localized)
    ]

    private var allCompleted: Bool {
        microStep > 3
    }

    private var formattedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        VStack(spacing: 0) {
            // タイマー
            Text(formattedTime)
                .font(.system(size: 40, weight: .light, design: .monospaced))
                .foregroundColor(.purple.opacity(0.8))
                .padding(.top, 16)
                .padding(.bottom, 8)

            // メモタイトル
            Text(memoTitle)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

            // ステップリスト
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(0..<4, id: \.self) { index in
                        stepRow(index: index)
                    }
                }
                .padding(.horizontal, 20)
            }

            Spacer()

            // メインボタン
            if allCompleted {
                FlowActionButton(
                    title: "評価に進む".localized,
                    icon: "arrow.right.circle.fill",
                    color: .purple,
                    action: onComplete
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            } else {
                let nextStepName = microStep < 3 ? steps[microStep + 1].label : "完了".localized
                let nextLabel = String(format: "次のステップ: %@".localized, nextStepName)
                FlowActionButton(
                    title: nextLabel,
                    icon: "checkmark.circle",
                    color: .purple.opacity(0.85),
                    action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            microStep += 1
                        }
                    }
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Step Row

    @ViewBuilder
    private func stepRow(index: Int) -> some View {
        let isCompleted = index < microStep || allCompleted
        let isCurrent = index == microStep && !allCompleted
        let isUpcoming = index > microStep && !allCompleted

        HStack(spacing: 12) {
            // チェックマーク / 番号
            ZStack {
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.green)
                } else if isCurrent {
                    Circle()
                        .stroke(Color.purple, lineWidth: 2.5)
                        .frame(width: 22, height: 22)
                        .overlay(
                            Circle()
                                .fill(Color.purple.opacity(0.2))
                                .frame(width: 14, height: 14)
                        )
                } else {
                    Circle()
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                }
            }
            .frame(width: 28)

            // ラベル + ガイドテキスト
            VStack(alignment: .leading, spacing: 4) {
                Text(steps[index].label)
                    .font(.subheadline)
                    .fontWeight(isCurrent ? .semibold : .regular)
                    .foregroundColor(isCompleted ? .secondary : (isCurrent ? .primary : .gray))
                    .strikethrough(isCompleted, color: .secondary)

                if isCurrent {
                    Text(steps[index].guide)
                        .font(.caption)
                        .foregroundColor(.purple)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            Spacer()
        }
        .padding(.vertical, isCurrent ? 14 : 10)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrent ? Color.purple.opacity(0.08) : Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrent ? Color.purple.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .opacity(isUpcoming ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 0.25), value: microStep)
    }
}
