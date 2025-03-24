import SwiftUI

struct CarouselHeaderView: View {
    let currentIndex: Int
    let totalCount: Int
    let showQuestionEditorAction: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                if totalCount > 0 {
                    Text("\(currentIndex + 1) / \(totalCount)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(4)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(4)
                        .padding(.leading, 10)
                        .padding(.top, 4)
                }
                
                Spacer()
                
                EditButton(action: showQuestionEditorAction)
                    .padding(.top, 10)
                    .padding(.trailing, 10)
            }
            
            Spacer()
        }
    }
}
