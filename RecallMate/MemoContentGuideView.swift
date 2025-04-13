import SwiftUI

struct MemoContentGuideView: View {
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
            
            // メモ内容エリア周辺のレイアウト
            GeometryReader { geometry in
                VStack {
                    // メモ内容フィールドに合わせた位置調整
                    Spacer().frame(height: geometry.size.height * 0.5)
                    
                    // ガイドコンテンツを中央に配置
                    VStack(spacing: 16) {
                        // 上向き矢印
                        Image(systemName: "arrow.up")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 2)
                            .padding(.bottom, 8)
                        
                        // 内容入力エリアを囲む半透明の背景
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: geometry.size.width * 0.85, height: 180)
                        
                        // ガイドテキスト
                        Text("アクティブリコールを実践しましょう！\n教科書を見ないで覚えている内容を書き出してみてください")
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
