// ActiveRecallGuideSheet.swift - アクティブリコール説明ガイド（3ページ）
import SwiftUI

struct ActiveRecallGuideSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    @State private var iconAnimations: [Bool] = [false, false, false]

    private let pages: [(icon: String, title: String, description: String, color: Color)] = [
        (
            icon: "brain.head.profile",
            title: "アクティブリコールとは？".localized,
            description: "教材を見ずに頭の中で思い出す学習法です。受動的に読むよりも、能動的に思い出すことで記憶が強化されます。".localized,
            color: .purple
        ),
        (
            icon: "arrow.clockwise",
            title: "実践の流れ".localized,
            description: "① 学習内容を読む → ② 教材を閉じる → ③ 頭の中で思い出す → ④ 答え合わせ。この4ステップを繰り返しましょう。".localized,
            color: .blue
        ),
        (
            icon: "chart.line.uptrend.xyaxis",
            title: "復習で記憶を定着".localized,
            description: "最適なタイミングで復習することで、記憶が長期的に定着します。RecallMateが復習日を自動で計算します。".localized,
            color: .orange
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // コンテンツ
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    guidePage(index: index)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 260)

            // プログレスインジケータ
            HStack(spacing: 6) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? pages[currentPage].color : Color.gray.opacity(0.3))
                        .frame(width: index == currentPage ? 24 : 8, height: 8)
                        .animation(AppTheme.Anim.standard, value: currentPage)
                }
            }
            .padding(.top, 12)

            // ボタン
            Button(action: {
                let feedback = UIImpactFeedbackGenerator(style: currentPage == pages.count - 1 ? .medium : .light)
                feedback.impactOccurred()

                if currentPage < pages.count - 1 {
                    withAnimation(AppTheme.Anim.spring) {
                        currentPage += 1
                    }
                } else {
                    UserDefaults.standard.set(true, forKey: "hasSeenActiveRecallGuide")
                    dismiss()
                }
            }) {
                HStack(spacing: 8) {
                    if currentPage == pages.count - 1 {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                    }
                    Text(currentPage == pages.count - 1 ? "わかりました".localized : "次へ".localized)
                        .fontWeight(.semibold)
                    if currentPage < pages.count - 1 {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [pages[currentPage].color, pages[currentPage].color.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(AppTheme.Radius.md)
                .shadow(
                    color: pages[currentPage].color.opacity(0.3),
                    radius: 4, x: 0, y: 2
                )
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.top, 20)
            .padding(.bottom, AppTheme.Spacing.lg)
        }
        .onChange(of: currentPage) { _ in
            let feedback = UISelectionFeedbackGenerator()
            feedback.selectionChanged()
            animateIcon(at: currentPage)
        }
        .onAppear {
            animateIcon(at: 0)
        }
    }

    // MARK: - Page Content

    private func guidePage(index: Int) -> some View {
        let page = pages[index]
        return VStack(spacing: 20) {
            // アニメーション付きアイコン
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .scaleEffect(iconAnimations[index] ? 1.0 : 0.8)

                Image(systemName: page.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .foregroundColor(page.color)
                    .scaleEffect(iconAnimations[index] ? 1.0 : 0.5)
                    .rotationEffect(.degrees(iconAnimations[index] ? 0 : -10))
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: iconAnimations[index])

            VStack(spacing: 10) {
                Text(page.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
                    .padding(.horizontal, 8)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    // MARK: - Animation

    private func animateIcon(at index: Int) {
        iconAnimations[index] = false
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
            iconAnimations[index] = true
        }
    }
}
