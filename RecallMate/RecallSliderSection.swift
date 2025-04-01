import SwiftUI

struct RecallSliderSection: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        Section {
            // 記憶度スライダー
            SimplifiedMemoryBar(retentionPercentage: Int(viewModel.recallScore))
                .padding(.bottom, 8)
            
            // スライダー
            Slider(value: Binding(
                get: { Double(viewModel.recallScore).isNaN ? 50.0 : Double(viewModel.recallScore) },
                set: {
                    viewModel.recallScore = Int16($0)
                    // 重要：直接ここで変更フラグを更新
                    viewModel.contentChanged = true
                    viewModel.recordActivityOnSave = true
                }
            ), in: 0...100, step: 1)
            .modifier(SliderColorModifier(color: sliderColor(for: viewModel.recallScore)))
        }
        // 元のコードと同じく、onChange イベントハンドラを追加
        .onChange(of: viewModel.recallScore) { _, _ in
            viewModel.contentChanged = true
            viewModel.recordActivityOnSave = true
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
    
    // スライダーの色も記憶度に応じて変更
    private func sliderColor(for score: Int16) -> Color {
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
}
