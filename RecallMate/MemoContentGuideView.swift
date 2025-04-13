// MemoContentGuideView.swift - 修正版
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
                    Spacer().frame(height: geometry.size.height * 0.07)
                    
                    // ガイドコンテンツを中央に配置
                    VStack(spacing: 16) {
                        // 内容入力エリアを囲む半透明の背景 - サイズを拡大して上方向にかぶるように
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: geometry.size.width * 0.9, height: 350)
                        
                        // ガイドテキスト
                        Text("このステップが一番重要！！\n教科書を見ないで覚えている内容を\n書き出したり、口に出したり、思い出してみて！\n今回はここに思い出して入力してみてね!\n二回目以降に学習するときは\nここを空欄にしてからもう一度やってみてね！")
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
