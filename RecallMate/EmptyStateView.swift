import SwiftUI

struct EmptyStateView: View {
    let cardHeight: CGFloat
    let showQuestionEditorAction: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            PlaceholderCardContent(editAction: showQuestionEditorAction)
                .padding(0)
                .frame(height: cardHeight)
                .frame(maxWidth: .infinity)
            
            EditButton(action: showQuestionEditorAction)
                .padding(.top, 10)
                .padding(.trailing, 10)
        }
        .frame(maxWidth: .infinity)
        .padding(0)
    }
}
