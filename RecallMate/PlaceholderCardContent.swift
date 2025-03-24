import SwiftUI

struct PlaceholderCardContent: View {
    var editAction: () -> Void
    
    // カードコンテンツの高さを定義
    private let cardHeight: CGFloat = 180
    
    var body: some View {
        VStack(spacing: 12) {
            Text("問題を追加してみましょう！")
                .font(.subheadline)
                .foregroundColor(.primary)
                .padding(.top, 12)
            
            Text("単語を入力するか、編集ボタンから\n問題を作成できます")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            Button {
                editAction()
            } label: {
                Text("問題を追加")
                    .font(.subheadline)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .buttonStyle(BorderlessButtonStyle())
            
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
    }
}
