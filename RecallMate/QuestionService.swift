import Foundation
import CoreData

// 問題関連の処理を一元管理するサービスクラス
class QuestionService {
    static let shared = QuestionService()
    
    private init() {}
    
    // MARK: - 問題の読み込み
    
    /// メモに関連する全ての問題（キーワードと比較問題）を読み込む
    func loadAllQuestions(
        for memo: Memo?,
        keywords: [String],
        viewContext: NSManagedObjectContext,
        completion: @escaping ([QuestionItem]) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var items: [QuestionItem] = []
            
            // 説明問題を追加
            for keyword in keywords {
                // UserDefaultsから保存済みの回答を取得
                let answerKey = "keyword_answer_\(keyword)"
                let answer = UserDefaults.standard.string(forKey: answerKey)
                
                items.append(QuestionItem(
                    id: "keyword_\(keyword)",
                    questionText: "「\(keyword)」について説明してください。",
                    subText: "この概念、特徴、重要性について詳しく述べてください。",
                    isExplanation: true,
                    answer: answer,
                    onAnswerChanged: { [weak self] newAnswer in
                        self?.saveKeywordAnswer(keyword: keyword, answer: newAnswer)
                    }
                ))
            }
            
            // メモがある場合は比較問題も追加
            if let memo = memo {
                self?.loadComparisonQuestions(for: memo, viewContext: viewContext) { questions in
                    for question in questions {
                        items.append(QuestionItem(
                            id: question.id?.uuidString ?? UUID().uuidString,
                            questionText: question.question ?? "",
                            subText: question.note ?? "",
                            isExplanation: false,
                            answer: question.answer,
                            onAnswerChanged: { [weak self] newAnswer in
                                self?.saveComparisonQuestionAnswer(
                                    question: question,
                                    answer: newAnswer,
                                    viewContext: viewContext
                                )
                            }
                        ))
                    }
                    
                    DispatchQueue.main.async {
                        completion(items)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(items)
                }
            }
        }
    }
    
    /// メモに関連する比較問題を読み込む
    func loadComparisonQuestions(
        for memo: Memo,
        viewContext: NSManagedObjectContext,
        completion: @escaping ([ComparisonQuestion]) -> Void
    ) {
        let fetchRequest: NSFetchRequest<ComparisonQuestion> = ComparisonQuestion.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "memo == %@", memo)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ComparisonQuestion.createdAt, ascending: true)]
        
        DispatchQueue.global(qos: .background).async {
            do {
                let questions = try viewContext.fetch(fetchRequest)
                DispatchQueue.main.async {
                    completion(questions)
                    print("📚 比較問題を読み込みました: \(questions.count)件")
                }
            } catch {
                print("❌ 比較問題読み込みエラー: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
    
    // MARK: - 回答の保存
    
    func saveKeywordAnswer(keyword: String, answer: String?) {
        let key = "keyword_answer_\(keyword)"
        if let answer = answer, !answer.isEmpty {
            UserDefaults.standard.set(answer, forKey: key)
            print("✅ キーワード「\(keyword)」の回答を保存しました")
        } else {
            // 空の回答は保存するが、削除メッセージは変更
            UserDefaults.standard.set("", forKey: key)
            print("🔄 キーワード「\(keyword)」の回答を空にしました")
        }
        
        // レジストリに更新を通知
        let id = "keyword_\(keyword)"
        if let item = QuestionItemRegistry.shared.getItemById(id) {
            item.answer = answer
        }
        QuestionItemRegistry.shared.notifyUpdates()
    }
    
    /// 比較問題の回答を保存
    func saveComparisonQuestionAnswer(question: ComparisonQuestion, answer: String?, viewContext: NSManagedObjectContext) {
        // 空の回答でも保存する
        question.answer = answer
        
        do {
            try viewContext.save()
            if let answer = answer, !answer.isEmpty {
                print("✅ 比較問題「\(question.question?.prefix(20) ?? "")...」の回答を保存しました")
            } else {
                print("🔄 比較問題「\(question.question?.prefix(20) ?? "")...」の回答を空にしました")
            }
            
            // レジストリに更新を通知
            if let id = question.id?.uuidString {
                if let item = QuestionItemRegistry.shared.getItemById(id) {
                    item.answer = answer
                }
            }
            QuestionItemRegistry.shared.notifyUpdates()
        } catch {
            print("❌ 比較問題回答保存エラー: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 回答のインポート
    
    /// テキストから回答を抽出して処理する
    func processAnswerText(_ text: String, completion: @escaping ([String: String]) -> Void) {
        // 改善された正規表現パターン - より柔軟に「問題X回答:」の形式を検出
        let pattern = "問題\\s*(\\d+)\\s*回答\\s*:\\s*([\\s\\S]*?)(?=問題\\s*\\d+\\s*回答\\s*:|$)"
        let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        
        var processedAnswers: [String: String] = [:]
        
        if let regex = regex {
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            for match in matches {
                if match.numberOfRanges >= 3 {
                    let questionNumberRange = match.range(at: 1)
                    let answerRange = match.range(at: 2)
                    
                    if questionNumberRange.location != NSNotFound && answerRange.location != NSNotFound {
                        let questionNumber = nsString.substring(with: questionNumberRange)
                        let answer = nsString.substring(with: answerRange).trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        processedAnswers[questionNumber] = answer
                        print("✅ 回答を検出: 問題\(questionNumber)")
                    }
                }
            }
            
            print("📝 検出された回答数: \(processedAnswers.count)")
        }
        
        // 処理結果を返す
        completion(processedAnswers)
    }
    
    /// 回答をQuestionItemsに適用する
    func applyImportedAnswers(
        answers: [String: String],
        questions: [QuestionItem],
        overwriteAll: Bool = true,
        completion: @escaping () -> Void = {}
    ) {
        print("🔄 回答を適用します: \(answers.count)件（上書き: \(overwriteAll)）")
        
        for i in 0..<questions.count {
            let questionIndex = i + 1
            if let answer = answers[String(questionIndex)] {
                if overwriteAll || !questions[i].hasAnswer {
                    print("✅ 問題 \(questionIndex) に回答を適用します")
                    questions[i].answer = answer
                }
            }
        }
        
        // 処理完了を通知
        completion()
    }
    
    // MARK: - 問題文生成
    
    /// 問題文をクリップボード用にフォーマット
    func formatQuestionsForClipboard(questions: [QuestionItem]) -> String {
        var clipboardText = "以下の問題に対する回答を作成してください。各回答の前には「問題X回答:」(Xは問題番号)というタグをつけてください。\n\n"
        
        for (index, question) in questions.enumerated() {
            clipboardText += "問題\(index + 1): \(question.questionText)\n"
            if !question.subText.isEmpty {
                clipboardText += "補足情報: \(question.subText)\n"
            }
            clipboardText += "\n"
        }
        
        clipboardText += "回答は「問題X回答:」の形式で始め、次の問題の回答までの間に空行を入れないでください。"
        
        return clipboardText
    }
}
