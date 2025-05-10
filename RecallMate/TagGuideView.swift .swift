import SwiftUI

struct TagGuideView: View {
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
            
            // タグエリア周辺のレイアウト
            GeometryReader { geometry in
                VStack {
                    // タグセクションまでのスペース
                    Spacer().frame(height: geometry.size.height * 0.35)
                    
                    // ガイドコンテンツを中央に配置
                    VStack(spacing: 16) {
                        // タグエリアを囲む半透明の背景
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: geometry.size.width * 0.9, height: 160)
                        
                        // ガイドテキスト
                        Text("これはメモを検索したり\n分析したりするときに便利なタグ機能だよ！\n今回は試しに新規タグから追加してみよう！".localized)
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
