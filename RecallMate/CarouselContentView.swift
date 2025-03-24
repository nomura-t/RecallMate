import SwiftUI

struct CarouselContentView: View {
    let questions: [QuestionItem]
    @Binding var currentIndex: Int
    let cardHeight: CGFloat
    
    // パフォーマンス最適化のための状態
    @State private var isAnimating = false
    
    var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(Array(questions.enumerated()), id: \.element.id) { index, question in
                QuestionCard(question: question)
                    .tag(index)
                    .frame(height: cardHeight)
                    .frame(maxWidth: .infinity)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .frame(height: cardHeight)
        .frame(maxWidth: .infinity)
        .onChange(of: currentIndex) { oldValue, newValue in
            guard !isAnimating else { return }
            isAnimating = true
            
            // アニメーション終了後にフラグをリセット
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isAnimating = false
            }
        }
    }
}
