// LearningTimer.swift - 独立したタイマーコンポーネント
import SwiftUI
import Foundation

struct LearningTimer: View {
    let startTime: Date
    let color: Color
    let isActive: Bool
    
    @State private var elapsedTime: TimeInterval = 0
    
    var body: some View {
        HStack(spacing: 12) {
            Text("学習時間")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(formattedTime)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundColor(color)
        }
        .onAppear {
            // 初期値を設定
            updateElapsedTime()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            // アクティブな時のみ時間を更新
            if isActive {
                updateElapsedTime()
            }
        }
    }
    
    private func updateElapsedTime() {
        elapsedTime = Date().timeIntervalSince(startTime)
    }
    
    private var formattedTime: String {
        let totalSeconds = Int(elapsedTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
