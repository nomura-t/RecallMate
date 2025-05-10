import SwiftUI

struct QuestionCard: View {
    var question: QuestionItem
    var onAnswerVisibilityChanged: ((Bool) -> Void)? = nil
    
    @State private var isShowingAnswer = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question.questionText)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            
            if !question.subText.isEmpty {
                Text(question.subText)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            HStack {
                Spacer()
                
                Text(question.isExplanation ? "説明問題".localized : "比較問題".localized)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(question.isExplanation ?
                        Color.blue.opacity(0.2) : Color.orange.opacity(0.2))
                    .cornerRadius(6)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        .onTapGesture {
            withAnimation(.spring()) {
                isShowingAnswer.toggle()
                onAnswerVisibilityChanged?(isShowingAnswer)
            }
        }
    }
}
