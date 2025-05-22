// ReviewCompletionView.swift
import SwiftUI
import CoreData

struct ReviewCompletionView: View {
    let memo: Memo
    let onCompletion: () -> Void
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var recallScore: Int16 = 50
    @State private var isSubmitting = false
    @State private var sessionStartTime = Date()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // ヘッダー
                VStack(spacing: 12) {
                    Text("復習完了")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("「\(memo.title ?? "無題")」の復習はいかがでしたか？")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // 記憶度評価セクション
                VStack(spacing: 20) {
                    // 記憶度の円形プログレス
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2), lineWidth: 12)
                            .frame(width: 150, height: 150)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(recallScore) / 100)
                            .stroke(
                                retentionColor(for: recallScore),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 150, height: 150)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.3), value: recallScore)
                        
                        VStack(spacing: 4) {
                            Text("\(Int(recallScore))")
                                .font(.system(size: 36, weight: .bold))
                            Text("%")
                                .font(.system(size: 18))
                        }
                        .foregroundColor(retentionColor(for: recallScore))
                    }
                    
                    // 記憶状態の説明
                    Text(retentionDescription(for: recallScore))
                        .font(.headline)
                        .foregroundColor(retentionColor(for: recallScore))
                        .multilineTextAlignment(.center)
                    
                    // スライダー
                    VStack(spacing: 12) {
                        HStack {
                            Text("0%")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Slider(value: Binding(
                                get: { Double(recallScore) },
                                set: { newValue in
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                    recallScore = Int16(newValue)
                                }
                            ), in: 0...100, step: 1)
                            .accentColor(retentionColor(for: recallScore))
                            
                            Text("100%")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        // スライダー下部のインジケーター
                        HStack(spacing: 0) {
                            ForEach(0..<5) { i in
                                let level = i * 20
                                let isActive = recallScore >= Int16(level)
                                
                                Rectangle()
                                    .fill(isActive ? retentionColorForLevel(i) : Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2))
                                    .frame(height: 6)
                                    .cornerRadius(3)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // 完了ボタン
                Button(action: completeReview) {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                        }
                        
                        Text(isSubmitting ? "保存中..." : "復習完了")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [retentionColor(for: recallScore), retentionColor(for: recallScore).opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .disabled(isSubmitting)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 20)
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .overlay(
                // 閉じるボタン
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 20)
                    }
                    Spacer()
                }
            )
        }
        .onAppear {
            // 現在の記憶度を初期値として設定
            recallScore = memo.recallScore
        }
    }
    
    // 復習完了処理
    private func completeReview() {
        isSubmitting = true
        
        // 実際の復習時間を計算
        let reviewDuration = Int(Date().timeIntervalSince(sessionStartTime))
        
        // 記憶度を更新
        memo.recallScore = recallScore
        memo.lastReviewedDate = Date()
        
        // 次回復習日を計算
        let nextReviewDate = ReviewCalculator.calculateNextReviewDate(
            recallScore: recallScore,
            lastReviewedDate: Date(),
            perfectRecallCount: memo.perfectRecallCount
        )
        memo.nextReviewDate = nextReviewDate
        
        // 復習アクティビティを記録
        let activity = LearningActivity.recordActivityWithPrecision(
            type: .review,
            durationSeconds: max(reviewDuration, 60), // 最低1分は記録
            memo: memo,
            note: "復習完了: \(memo.title ?? "無題")",
            in: viewContext
        )
        
        // 変更を保存
        do {
            try viewContext.save()
            
            // ハプティックフィードバック
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            // サウンド再生
            SoundManager.shared.playMemoryCompletedSound()
            
            // データ更新通知
            NotificationCenter.default.post(
                name: NSNotification.Name("ForceRefreshMemoData"),
                object: nil
            )
            
            // 完了処理
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onCompletion()
                dismiss()
            }
            
        } catch {
            print("Error saving review completion: \(error)")
            isSubmitting = false
        }
    }
    
    // 記憶度に応じた色を返す
    private func retentionColor(for score: Int16) -> Color {
        switch score {
        case 81...100:
            return Color(red: 0.0, green: 0.7, blue: 0.3) // 緑
        case 61...80:
            return Color(red: 0.3, green: 0.7, blue: 0.0) // 黄緑
        case 41...60:
            return Color(red: 0.95, green: 0.6, blue: 0.1) // オレンジ
        case 21...40:
            return Color(red: 0.9, green: 0.45, blue: 0.0) // 濃いオレンジ
        default:
            return Color(red: 0.9, green: 0.2, blue: 0.2) // 赤
        }
    }
    
    // レベルごとの色を返す
    private func retentionColorForLevel(_ level: Int) -> Color {
        switch level {
        case 4:
            return Color(red: 0.0, green: 0.7, blue: 0.3) // 緑
        case 3:
            return Color(red: 0.3, green: 0.7, blue: 0.0) // 黄緑
        case 2:
            return Color(red: 0.95, green: 0.6, blue: 0.1) // オレンジ
        case 1:
            return Color(red: 0.9, green: 0.45, blue: 0.0) // 濃いオレンジ
        default:
            return Color(red: 0.9, green: 0.2, blue: 0.2) // 赤
        }
    }
    
    // 記憶度に応じた説明テキストを返す
    private func retentionDescription(for score: Int16) -> String {
        switch score {
        case 91...100:
            return "完璧に覚えています！"
        case 81...90:
            return "十分に理解できています"
        case 71...80:
            return "だいたい理解しています"
        case 61...70:
            return "要点は覚えています"
        case 51...60:
            return "基本概念を思い出せます"
        case 41...50:
            return "断片的に覚えています"
        case 31...40:
            return "うっすらと覚えています"
        case 21...30:
            return "ほとんど忘れています"
        case 1...20:
            return "ほぼ完全に忘れています"
        default:
            return "全く覚えていません"
        }
    }
}
