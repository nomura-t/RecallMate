import SwiftUI

struct RecallSliderGuideView: View {
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
            
            // 記憶定着度スライダーエリア周辺のレイアウト
            GeometryReader { geometry in
                VStack {
                    // スクロール後の位置に合わせて調整（上部余白を小さく）
                    Spacer().frame(height: geometry.size.height * 0.2)
                    
                    // ガイドコンテンツを中央に配置
                    VStack(spacing: 16) {
                        // スライダーエリアを囲む半透明の背景 - 高さを調整
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: geometry.size.width * 0.9, height: 180)
                        
                        // ガイドテキスト
                        Text("あなたの記憶度を評価してみよう！\nどのくらい記憶できているか自己評価することで\n次回の復習タイミングを最適化します\nスライダーを動かして評価してみよう！")
                            .font(.headline)
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .frame(width: geometry.size.width)
            }
        }
        .transition(.opacity)
    }
}
