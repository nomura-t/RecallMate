import SwiftUI
import CoreData

struct QuestionCarouselView: View {
    // 既存のプロパティ
    let keywords: [String]
    let comparisonQuestions: [ComparisonQuestion]
    let memo: Memo?
    let viewContext: NSManagedObjectContext
    @Binding var showQuestionEditor: Bool
    
    @StateObject private var state = CarouselState()
    private let cardHeight: CGFloat = 180
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var isCardAnimating = false
    @State private var isShowingAnswer = false // 解答表示のための状態を追加
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // カードコンテナ - 固定サイズと背景
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.5))
                .frame(height: cardHeight + 32)
            
            // カードコンテンツ - maxWidthを指定して横幅いっぱいに
            if state.questions.isEmpty {
                // プレースホルダーカード
                placeholderCard
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
            } else {
                // 質問カード (タップで解答切り替え機能を組み込み)
                Group {
                    if isShowingAnswer {
                        // 解答カード
                        answerCard
                    } else {
                        // 問題カード
                        questionCard
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle()) // タップ領域を確実に確保
                .highPriorityGesture(
                    TapGesture()
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                isShowingAnswer.toggle()
                            }
                        }
                )
            }
            
            // 編集ボタン - 常に同じ位置に
            Button {
                showQuestionEditor = true
                // ハプティックフィードバックを追加
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.blue)
                    .shadow(color: Color.primary.opacity(0.2), radius: 1, x: 0, y: 1)
                    .frame(width: 44, height: 44) // タップ領域を広げる
                    .contentShape(Rectangle()) // タップ領域を明確に
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 16)
            .padding(.trailing, 16)
            .highPriorityGesture( // 高優先度のジェスチャーとして設定
                TapGesture()
                    .onEnded { _ in
                        showQuestionEditor = true
                        
                        // ハプティックフィードバックを追加
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }
            )
        }
        .frame(height: cardHeight + 32)
        .padding(.vertical, 8)
        .onAppear(perform: loadQuestions)
        .onChange(of: keywords) { _, _ in loadQuestions() }
        .onChange(of: comparisonQuestions) { _, _ in loadQuestions() }
        .onChange(of: state.currentIndex) { _, _ in
            // カード切り替え時には解答表示をリセット
            isShowingAnswer = false
        }
        // 以下の通知リスナーを追加
        .onReceive(QuestionItemRegistry.shared.updates) { _ in
            // レジストリが更新されたことを検知
            // 回答表示状態に基づいて適切に更新
            if isShowingAnswer {
                // すでに回答表示中ならすぐに再表示
                withAnimation(.spring()) {
                    isShowingAnswer = false
                    
                    // 少し遅らせて再表示
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring()) {
                            isShowingAnswer = true
                        }
                    }
                }
            }
        }
        // AnswersImportedやAnswersUpdatedなどの通知も監視
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AnswersImported"))) { _ in
            // レジストリからの更新を確実に反映
            loadQuestions()
            
            if isShowingAnswer {
                // 回答表示中なら切り替えてから再表示
                withAnimation(.spring()) {
                    isShowingAnswer = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring()) {
                            isShowingAnswer = true
                        }
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AnswersUpdated"))) { _ in
            loadQuestions()
            
            if isShowingAnswer {
                // 回答表示状態を更新
                withAnimation(.spring()) {
                    isShowingAnswer = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring()) {
                            isShowingAnswer = true
                        }
                    }
                }
            }
        }
    }
    
// プレースホルダーカード - 修正バージョン
    private var placeholderCard: some View {
        VStack(spacing: 12) {
            Text("問題を追加してみましょう！")
                .font(.subheadline)
                .foregroundColor(.primary)
                .padding(.top, 12)
            
            Text("単語を入力するか、編集ボタンから\n問題を作成できます")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            Button {
                showQuestionEditor = true
                
                // ハプティックフィードバックを追加
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
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
            .contentShape(Rectangle()) // タップ領域を明確に
            .padding(.vertical, 8) // タップ領域を少し広げる
            .highPriorityGesture( // 高優先度のジェスチャーとして設定
                TapGesture()
                    .onEnded { _ in
                        showQuestionEditor = true
                        
                        // ハプティックフィードバックを追加
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }
            )
            
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .frame(height: cardHeight)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.primary.opacity(0.15), radius: 4, x: 0, y: 2)
    }

    // questionCard を修正
    @ViewBuilder
    private var questionCard: some View {
        if !state.questions.isEmpty {
            let currentQuestion = state.questions[state.currentIndex]
            VStack(alignment: .leading, spacing: 8) {
                Text(currentQuestion.questionText)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                
                if !currentQuestion.subText.isEmpty {
                    Text(currentQuestion.subText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Text(currentQuestion.isExplanation ? "説明問題" : "比較問題")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(currentQuestion.isExplanation ?
                            Color.blue.opacity(0.2) : Color.orange.opacity(0.2))
                        .foregroundColor(currentQuestion.isExplanation ? .blue : .orange)
                        .cornerRadius(6)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .frame(height: cardHeight)
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(color: Color.primary.opacity(0.15), radius: 4, x: 0, y: 2)
            .offset(x: dragOffset)
            .gesture(
                DragGesture(minimumDistance: 30)
                    .onChanged { value in
                        // 解答表示中はスワイプしない
                        guard !isShowingAnswer && !isCardAnimating else { return }
                        
                        isDragging = true
                        if abs(value.translation.width) > abs(value.translation.height) * 2 {
                            withAnimation(nil) {
                                dragOffset = value.translation.width
                            }
                        }
                    }
                    .onEnded { value in
                        // 解答表示中はスワイプしない
                        guard !isShowingAnswer && !isCardAnimating else {
                            dragOffset = 0
                            isDragging = false
                            return
                        }
                        
                        defer {
                            dragOffset = 0
                            isDragging = false
                        }
                        
                        if abs(value.translation.width) > 50 && abs(value.translation.width) > abs(value.translation.height) * 2 {
                            if value.translation.width > 0 {
                                state.moveToPreviousQuestion()
                            } else {
                                state.moveToNextQuestion()
                            }
                        }
                    }
            )
        } else {
            EmptyView()
        }
    }

    // answerCard も同様に修正
    @ViewBuilder
    private var answerCard: some View {
        if !state.questions.isEmpty {
            let currentQuestion = state.questions[state.currentIndex]
            
            VStack(alignment: .leading, spacing: 8) {
                Text("答え")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding(.top, 2)
                
                // 回答の有無に関わらずコンテンツを表示
                if let answer = currentQuestion.answer, !answer.isEmpty {
                    // 回答がある場合
                    ScrollView {
                        Text(answer)
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.top, 2)
                            .frame(maxWidth: .infinity, alignment: .leading) // 左揃えに
                    }
                    .frame(maxHeight: cardHeight - 60)
                } else {
                    // 回答がない場合 - Spacer削除、フレーム調整
                    VStack(spacing: 10) {
                        Image(systemName: "questionmark.circle")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("まだ回答がありません")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: cardHeight - 60)
                    .frame(minHeight: 0, maxHeight: .infinity, alignment: .center) // 垂直中央揃え
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .frame(height: cardHeight)
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(color: Color.primary.opacity(0.15), radius: 4, x: 0, y: 2)
        } else {
            EmptyView()
        }
    }
    
    // 質問データの読み込み
    private func loadQuestions() {
        state.loadQuestionsFromRegistry(
            keywords: keywords,
            comparisonQuestions: comparisonQuestions
        )
    }
}
