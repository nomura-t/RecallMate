import SwiftUI

struct QuestionCardGuideView: View {
    @Binding var isPresented: Bool
    var onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // 半透明のオーバーレイ
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        isPresented = false
                        onDismiss()
                    }
                }
            
            // 問題カード領域周辺のレイアウト
            VStack(spacing: 0) {
                Spacer()
                
                // 問題カードエリアを囲む半透明の背景
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 340, height: 200) // 問題カードの高さに合わせて調整
                }
                .padding(.bottom, 40) // 位置の調整
                
                // 下向き矢印
                Image(systemName: "arrow.down")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 2)
                    .padding(.bottom, 12)
                
                // ガイドテキスト
                Text("ここに分からない単語があれば\n入力して問題を作成してみましょう！\n(空欄可)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .transition(.opacity)
    }
}
