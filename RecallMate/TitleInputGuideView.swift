import SwiftUI

struct TitleInputGuideView: View {
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
            
            // タイトル入力欄周辺のレイアウト
            VStack(spacing: 0) {
                // タイトル入力欄を囲む半透明の背景
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 350, height: 110)
                }
                .padding(.top, 90) // ここを小さくして上にずらす（120→60）
                
                // 上向き矢印
                Image(systemName: "arrow.up")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 2)
                    .padding(.top, 12)
                
                // ガイドテキスト
                Text("学習した内容がわかるように\nタイトル(必須)とページ範囲(空欄可)\nを入力しましょう！")
                    .font(.headline)
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .transition(.opacity)
    }
}
