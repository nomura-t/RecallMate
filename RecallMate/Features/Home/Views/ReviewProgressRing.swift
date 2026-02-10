// ReviewProgressRing.swift - 大きな進捗リング
import SwiftUI

struct ReviewProgressRing: View {
    let totalDue: Int
    let completed: Int

    @State private var animatedProgress: CGFloat = 0

    private var progress: CGFloat {
        guard totalDue > 0 else { return 1.0 }
        return CGFloat(completed) / CGFloat(totalDue)
    }

    private var remaining: Int {
        max(totalDue - completed, 0)
    }

    private var isAllDone: Bool {
        totalDue > 0 && remaining == 0
    }

    var body: some View {
        ZStack {
            // 背景リング
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: 10)
                .frame(width: 120, height: 120)

            // 進捗リング
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    ringGradient,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))

            // 中央コンテンツ
            VStack(spacing: 2) {
                if isAllDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.green)
                } else {
                    Text("\(remaining)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }

                Text(isAllDone ? "完了!".localized : "残り".localized)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animatedProgress = progress
            }
        }
        .onChange(of: totalDue) { _ in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = progress
            }
        }
        .onChange(of: completed) { _ in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = progress
            }
        }
    }

    private var ringGradient: AngularGradient {
        if isAllDone {
            return AngularGradient(
                colors: [.green, .green.opacity(0.7)],
                center: .center,
                startAngle: .degrees(0),
                endAngle: .degrees(360)
            )
        }
        return AngularGradient(
            colors: [AppTheme.Colors.brand, AppTheme.Colors.brand.opacity(0.6)],
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360)
        )
    }
}
