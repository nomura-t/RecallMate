import SwiftUI

struct FloatingGuideView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // 半透明のオーバーレイ
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        isPresented = false
                    }
                }
            
            // 右下に誘導矢印
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 12) {
                        Text("ここをタップして")
                            .font(.headline)
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 2)
                        
                        Text("学習をはじめましょう！")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 2)
                        
                        Image(systemName: "arrow.down")
                            .font(.system(size: 26))
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 2)
                    }
                    .padding()
                    .padding(.trailing, 30)
                    .padding(.bottom, 150) // 脳アイコンの上にくるよう調整
                }
            }
        }
        .transition(.opacity)
    }
}
