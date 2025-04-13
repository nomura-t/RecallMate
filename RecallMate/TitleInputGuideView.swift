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
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // タイトル入力欄に合わせたスペーシング
                    Spacer().frame(height: geometry.size.height * 0.05)
                    
                    // タイトル入力欄を囲む半透明の背景 - 位置を調整
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: geometry.size.width * 0.9, height: 110)
                    }
                    
                    // ガイドテキスト - 矢印を削除
                    Text("学習した内容がわかるように\nタイトルを入力しよう！\nページ範囲は空欄でも大丈夫だよ！\n")
                        .font(.headline)
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 16)
                    
                    Spacer()
                }
                .frame(width: geometry.size.width)
            }
        }
        .transition(.opacity)
    }
}
