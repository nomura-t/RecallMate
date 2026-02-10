// CelebrationOverlay.swift - 復習全完了時のセレブレーション
import SwiftUI

struct CelebrationOverlay: View {
    @Binding var isShowing: Bool
    @State private var particles: [ConfettiParticle] = []
    @State private var textScale: CGFloat = 0.5
    @State private var textOpacity: Double = 0
    @State private var overlayOpacity: Double = 0

    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.3 * overlayOpacity)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture { dismiss() }

            // コンフェッティパーティクル
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let now = timeline.date.timeIntervalSinceReferenceDate
                    for particle in particles {
                        let age = now - particle.creationTime
                        guard age < 3.0 else { continue }

                        let progress = age / 3.0
                        let x = particle.startX + particle.horizontalSpeed * CGFloat(age)
                        let y = particle.startY + CGFloat(age * age) * 120 + particle.verticalOffset * CGFloat(age)
                        let rotation = Angle.degrees(particle.rotationSpeed * age)
                        let opacity = max(0, 1.0 - progress)
                        let scale = particle.size * CGFloat(max(0.3, 1.0 - progress * 0.5))

                        var transform = context
                        transform.opacity = opacity
                        transform.translateBy(x: x, y: y)
                        transform.rotate(by: rotation)

                        let rect = CGRect(x: -scale/2, y: -scale/2, width: scale, height: scale)
                        transform.fill(
                            RoundedRectangle(cornerRadius: particle.isCircle ? scale/2 : 2).path(in: rect),
                            with: .color(particle.color)
                        )
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)
            .allowsHitTesting(false)

            // メッセージカード
            VStack(spacing: 16) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("今日の復習完了！".localized)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("おめでとう！素晴らしい学習習慣です".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(AppTheme.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                    .fill(.ultraThinMaterial)
            )
            .scaleEffect(textScale)
            .opacity(textOpacity)
        }
        .onAppear {
            generateParticles()

            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                textScale = 1.0
                textOpacity = 1.0
                overlayOpacity = 1.0
            }

            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.success)

            // 2.5秒後に自動フェードアウト
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                dismiss()
            }
        }
    }

    private func dismiss() {
        withAnimation(AppTheme.Anim.standard) {
            textScale = 0.8
            textOpacity = 0
            overlayOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isShowing = false
        }
    }

    private func generateParticles() {
        let colors: [Color] = [.orange, .green, .blue, .purple, .red, .yellow, .pink]
        let screenWidth = UIScreen.main.bounds.width
        var newParticles: [ConfettiParticle] = []

        for _ in 0..<40 {
            let particle = ConfettiParticle(
                startX: CGFloat.random(in: 0...screenWidth),
                startY: CGFloat.random(in: -50...0),
                horizontalSpeed: CGFloat.random(in: -30...30),
                verticalOffset: CGFloat.random(in: -20...40),
                rotationSpeed: Double.random(in: -360...360),
                size: CGFloat.random(in: 6...14),
                color: colors.randomElement() ?? .orange,
                isCircle: Bool.random(),
                creationTime: Date().timeIntervalSinceReferenceDate + Double.random(in: 0...0.5)
            )
            newParticles.append(particle)
        }

        particles = newParticles
    }
}

private struct ConfettiParticle {
    let startX: CGFloat
    let startY: CGFloat
    let horizontalSpeed: CGFloat
    let verticalOffset: CGFloat
    let rotationSpeed: Double
    let size: CGFloat
    let color: Color
    let isCircle: Bool
    let creationTime: TimeInterval
}
