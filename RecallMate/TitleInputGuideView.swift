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
            
            // タイトル入力エリアへの誘導
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 12) {
                        Text("学習内容のタイトルを")
                            .font(.headline)
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 2)
                        
                        Text("入力しましょう！")
                            .font(.headline)
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 2)
                        
                        // 脳アイコン
                        Circle()
                            .fill(Color.white)
                            .frame(width: 60, height: 60)
                    }
                    .padding()
                    .padding(.trailing, 20)
                    .padding(.bottom, 340) // タイトル欄の位置に合わせて調整
                }
            }
            
            // タイトル欄を指す矢印
            VStack {
                HStack {
                    Spacer()
                    VStack {
                        Arrow(direction: .up)
                            .fill(Color.white)
                            .frame(width: 30, height: 30)
                            .shadow(color: .black, radius: 2)
                            .padding(.trailing, 50)
                            .padding(.top, 360) // 位置調整
                        
                        Spacer()
                    }
                }
            }
        }
        .transition(.opacity)
    }
}

// 矢印の形状を描画するShape
struct Arrow: Shape {
    enum Direction {
        case up, down, left, right
    }
    
    let direction: Direction
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        switch direction {
        case .up:
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        case .down:
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.closeSubpath()
        case .left:
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.closeSubpath()
        case .right:
            path.move(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
        
        return path
    }
}
