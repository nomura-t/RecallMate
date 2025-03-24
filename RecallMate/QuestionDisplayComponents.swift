import SwiftUI

// 編集アイコンコンポーネント
struct EditButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "list.bullet.clipboard.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(BorderlessButtonStyle())
    }
}

// カード上部のインジケーターのみ（メニュー削除）
struct CardHeader: View {
    var currentIndex: Int
    var totalCount: Int
    
    var body: some View {
        HStack {
            Text("\(currentIndex + 1) / \(totalCount)")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(4)
                .background(Color.white.opacity(0.9))
                .cornerRadius(4)
            
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.top, 4)
    }
}
