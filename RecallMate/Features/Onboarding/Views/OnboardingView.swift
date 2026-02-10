// OnboardingView.swift - 強化版
import SwiftUI

struct OnboardingView: View {
    @Binding var isShowingOnboarding: Bool
    @State private var currentPage = 0
    @State private var iconAnimations: [Bool] = Array(repeating: false, count: 6)

    private let pages: [(image: String, title: String, description: String)] = [
        (
            image: "doc.text",
            title: "新規記録を作成".localized,
            description: "ホーム画面右下の「🧠」ボタンから学習内容の記録を作成できます。".localized
        ),
        (
            image: "arrow.clockwise",
            title: "アクティブリコール".localized,
            description: "記録を閉じて学んだ内容を思い出し、記憶を強化しましょう。".localized
        ),
        (
            image: "calendar",
            title: "分散学習".localized,
            description: "最適な間隔で復習することで、長期記憶への定着率が向上します。".localized
        ),
        (
            image: "slider.horizontal.3",
            title: "記憶度の評価".localized,
            description: "記憶度を評価すると、次回の復習タイミングが自動的に最適化されます。".localized
        ),
        (
            image: "timer",
            title: "集中タイマー".localized,
            description: "集中力を最大化するテクニックを活用しましょう。".localized
        ),
        (
            image: "brain.head.profile",
            title: "記録を作成してみましょう".localized,
            description: "ホーム画面に戻ったら、右下の脳アイコンをタップして最初の記録を作成してみましょう！".localized
        )
    ]

    var body: some View {
        ZStack {
            // 背景
            Color(.systemBackground)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // スキップボタン
                HStack {
                    Spacer()
                    Button(action: { dismissOnboarding() }) {
                        Text("スキップ".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.top, 8)
                .padding(.trailing, 8)

                Spacer()

                // コンテンツカード
                VStack(spacing: 0) {
                    // ページコンテンツ
                    TabView(selection: $currentPage) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            onboardingPage(index: index)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: 300)

                    // カスタムプログレスインジケータ
                    progressIndicator
                        .padding(.top, 12)

                    // ナビゲーションボタン
                    navigationButton
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.top, 20)
                        .padding(.bottom, AppTheme.Spacing.lg)
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(AppTheme.Radius.xl)
                .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 4)
                .padding(.horizontal, 32)

                Spacer()
            }
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

    private func onboardingPage(index: Int) -> some View {
        VStack(spacing: 20) {
            // アニメーション付きアイコン
            ZStack {
                Circle()
                    .fill(pageColor(for: index).opacity(0.1))
                    .frame(width: 100, height: 100)
                    .scaleEffect(iconAnimations[index] ? 1.0 : 0.8)

                Image(systemName: pages[index].image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .foregroundColor(pageColor(for: index))
                    .scaleEffect(iconAnimations[index] ? 1.0 : 0.5)
                    .rotationEffect(.degrees(iconAnimations[index] ? 0 : -10))
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: iconAnimations[index])

            // テキスト
            VStack(spacing: 10) {
                Text(pages[index].title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(pages[index].description)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
                    .padding(.horizontal, 8)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? pageColor(for: currentPage) : Color.gray.opacity(0.3))
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(AppTheme.Anim.standard, value: currentPage)
            }
        }
    }

    // MARK: - Navigation Button

    private var navigationButton: some View {
        Button(action: {
            let feedback = UIImpactFeedbackGenerator(style: currentPage == pages.count - 1 ? .medium : .light)
            feedback.impactOccurred()

            if currentPage < pages.count - 1 {
                withAnimation(AppTheme.Anim.spring) {
                    currentPage += 1
                }
            } else {
                dismissOnboarding()
            }
        }) {
            HStack(spacing: 8) {
                if currentPage == pages.count - 1 {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                }
                Text(currentPage == pages.count - 1 ? "RecallMateを始める".localized : "次へ".localized)
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
                    colors: [pageColor(for: currentPage), pageColor(for: currentPage).opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(AppTheme.Radius.md)
            .shadow(
                color: pageColor(for: currentPage).opacity(0.3),
                radius: 4, x: 0, y: 2
            )
        }
    }

    // MARK: - Helpers

    private func pageColor(for index: Int) -> Color {
        let colors: [Color] = [.blue, .purple, .orange, .green, .red, .orange]
        return colors[index % colors.count]
    }

    private func animateIcon(at index: Int) {
        // リセットしてからアニメーション
        iconAnimations[index] = false
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
            iconAnimations[index] = true
        }
    }

    private func dismissOnboarding() {
        withAnimation(AppTheme.Anim.standard) {
            isShowingOnboarding = false
            saveOnboardingShown()
        }
    }

    private func saveOnboardingShown() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
    }
}
