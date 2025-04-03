import SwiftUI

/// 記憶度スライダーと詳細情報を1つのセクションにまとめたコンポーネント
struct CombinedRecallSection: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        Section(header: Text("記憶定着度振り返り")) {
            // シンプルなプログレスバー
            HStack {
                // 固定幅を確保し、右寄せにしてテキストが常に同じ位置に表示されるようにする
                Text("\(Int(viewModel.recallScore))%")
                    .font(.subheadline)
                    .foregroundColor(retentionColor(for: viewModel.recallScore))
                    .frame(width: 60, alignment: .trailing) // 幅を60に設定し、100%でも崩れないようにする
                
                // プログレスバー
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // 背景バー
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 12)
                        
                        // 進捗バー
                        RoundedRectangle(cornerRadius: 8)
                            .fill(retentionColor(for: viewModel.recallScore))
                            .frame(width: CGFloat(viewModel.recallScore) / 100.0 * geometry.size.width, height: 12)
                    }
                }
                .frame(height: 12)
            }
            .padding(.vertical, 4)
            
            // 記憶度のスライダー
            Slider(value: Binding(
                get: { Double(viewModel.recallScore).isNaN ? 50.0 : Double(viewModel.recallScore) },
                set: {
                    viewModel.recallScore = Int16($0)
                    // スライダー操作時に直接状態を更新
                    viewModel.contentChanged = true
                    viewModel.recordActivityOnSave = true
                    // 次回復習日を更新 - ViewModelのメソッドを呼び出す
                    viewModel.updateNextReviewDate()
                }
            ), in: 0...100, step: 1)
            .modifier(SliderColorModifier(color: retentionColor(for: viewModel.recallScore)))
            
            // 記憶度の説明
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: statusIcon(for: viewModel.recallScore))
                        .foregroundColor(retentionColor(for: viewModel.recallScore))
                        .frame(width: 24) // アイコンの幅を固定
                    
                    Text(retentionDescription(for: viewModel.recallScore))
                        .font(.subheadline)
                }
                
                // 詳細説明
                Text(retentionDetailedDescription(for: viewModel.recallScore))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
                
                // 次回復習日（存在する場合）
                // ここで viewModel.reviewDate は更新された値を表示
                if let nextReviewDate = viewModel.reviewDate {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.blue)
                            .frame(width: 24) // アイコンの幅を固定
                        
                        Text("次回の推奨復習日: \(viewModel.formattedDate(nextReviewDate))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.top, 8)
        }
        // 元コードと同様にonChangeハンドラを追加
        .onChange(of: viewModel.recallScore) { _, _ in
            viewModel.contentChanged = true
            viewModel.recordActivityOnSave = true
            // 次回復習日を更新 - ViewModelのメソッドを呼び出す
            viewModel.updateNextReviewDate()
        }
    }
    
    // iOS バージョンに応じてスライダーの色を設定するモディファイア
    struct SliderColorModifier: ViewModifier {
        let color: Color
        
        func body(content: Content) -> some View {
            if #available(iOS 15.0, *) {
                content.tint(color)
            } else {
                content.accentColor(color)
            }
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
            return Color(red: 0.95, green: 0.6, blue: 0.1) // オレンジ（画像のような色）
        case 21...40:
            return Color(red: 0.9, green: 0.45, blue: 0.0) // 濃いオレンジ
        default:
            return Color(red: 0.9, green: 0.2, blue: 0.2) // 赤
        }
    }
    
    // 記憶度に応じたアイコンを返す
    private func statusIcon(for score: Int16) -> String {
        switch score {
        case 81...100:
            return "checkmark.circle"
        case 61...80:
            return "brain"
        case 41...60:
            return "questionmark.circle"
        case 21...40:
            return "exclamationmark.circle"
        default:
            return "exclamationmark.triangle"
        }
    }
    
    // 記憶度に応じた説明テキストを返す
    private func retentionDescription(for score: Int16) -> String {
        switch score {
        case 91...100:
            return "完璧に覚えた！自信満々！"
        case 81...90:
            return "十分に理解、自分の言葉で説明可能"
        case 71...80:
            return "だいたい理解している"
        case 61...70:
            return "要点は覚えている"
        case 51...60:
            return "基本概念は思い出せる"
        case 41...50:
            return "断片的に覚えている"
        case 31...40:
            return "うっすらと覚えている"
        case 21...30:
            return "ほとんど忘れている"
        case 1...20:
            return "ほぼ完全に忘れている"
        default:
            return "全く覚えていない"
        }
    }
    
    // 記憶度に応じた詳細説明を返す
    private func retentionDetailedDescription(for score: Int16) -> String {
        switch score {
        case 91...100:
            return "試験でも即答できる状態です。この記憶は長期間保持される可能性が高いです。"
        case 81...90:
            return "概念をしっかり把握し、自分の言葉で説明できます。細部に不安はありますが、基本的な理解は定着しています。"
        case 71...80:
            return "主要な部分は説明できますが、一部詳細が曖昧です。より定着させるには、アクティブリコールを続けることが効果的です。"
        case 61...70:
            return "要点は覚えていますが、説明するとき少し詰まることがあります。復習間隔を少し短くすると効果的です。"
        case 51...60:
            return "基本的な概念は思い出せますが、詳細を思い出すのに時間がかかります。より頻繁な復習が必要です。"
        case 41...50:
            return "断片的に覚えていますが、全体像が不明確です。短い間隔での復習と、関連付けを強化する学習が有効です。"
        case 31...40:
            return "うっすらと覚えていますが、思い出すのに大きなヒントが必要です。基礎から再確認することをお勧めします。"
        case 21...30:
            return "ほとんど忘れており、わずかな記憶の断片しか残っていません。より基本的な部分から学び直す必要があります。"
        case 1...20:
            return "ほぼ完全に忘れています。学習したことを認識できる程度です。もう一度基礎から学び直しましょう。"
        default:
            return "全く覚えていません。まったく新しい情報のように感じるでしょう。初めから学習し直す必要があります。"
        }
    }
}
