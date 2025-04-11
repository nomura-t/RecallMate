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
            VStack {
                Spacer()
                
                // メモ内容エリアの強調表示
                VStack(spacing: 16) {
                    // メモ内容フィールドに向かって矢印
                    Image(systemName: "arrow.down")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 2)
                        .padding(.bottom, 8)
                    
                    // 内容入力エリアを囲む半透明の背景
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 340, height: 190)
                        .padding(.bottom, 16)
                    
                    // ガイドテキスト
                    Text("アクティブリコールを実践しましょう！\n教科書を見ないで覚えている内容を書き出してみてください")
                        .font(.headline)
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 350) // 内容フィールドの位置に合わせて調整
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .transition(.opacity)
    }
}
