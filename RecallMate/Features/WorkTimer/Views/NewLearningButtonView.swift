// NewLearningButtonView.swift
import SwiftUI

/// 新規学習を開始するためのボタンコンポーネント
///
/// このコンポーネントは以下の責務を持ちます：
/// - 新規学習開始への誘導UI表示
/// - ユーザーのタップアクションの処理
/// - 適切なビジュアルフィードバックの提供
struct NewLearningButtonView: View {
    /// 新規学習開始時に実行されるアクション
    /// このクロージャを通じて、親ビューに学習開始の意図を伝えます
    let onStartNewLearning: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onStartNewLearning) {
            HStack(spacing: 12) {
                // アイコン：脳のシルエットで学習を象徴
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 2) {
                    // メインメッセージ：行動を促す明確な文言
                    Text("新規学習を始める！")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    // サブメッセージ：具体的な行動を説明
                    Text("今日学んだ内容を記録しましょう")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // 進行方向を示すアイコン
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                // グラデーション背景で視覚的な魅力を向上
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.green,
                        Color.green.opacity(0.8)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(
                color: Color.green.opacity(0.3),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(PlainButtonStyle()) // タップ時の標準的な視覚効果を無効化
    }
}
