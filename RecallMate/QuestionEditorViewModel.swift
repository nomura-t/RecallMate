import SwiftUI
import CoreData

class QuestionEditorViewModel: ObservableObject {
    // CoreDataコンテキスト
    let viewContext: NSManagedObjectContext
    let memo: Memo?
    
    // 状態管理用のプロパティ
    @Published var editingKeywords: [String]
    @Published var selectedKeywords = Set<String>()
    @Published var selectedQuestions = Set<String>()
    @Published var newKeyword = ""
    @Published var isEditMode = false
    @Published var error: String? = nil
    
    // データバインディング
    var keywords: Binding<[String]>
    var comparisonQuestions: Binding<[ComparisonQuestion]>
    
    // 初期化
    init(memo: Memo?, keywords: Binding<[String]>, comparisonQuestions: Binding<[ComparisonQuestion]>, viewContext: NSManagedObjectContext) {
        self.memo = memo
        self.keywords = keywords
        self.comparisonQuestions = comparisonQuestions
        self.viewContext = viewContext
        self.editingKeywords = keywords.wrappedValue
    }
    
    // キーワード選択のトグル
    func toggleKeywordSelection(_ keyword: String) {
        if selectedKeywords.contains(keyword) {
            selectedKeywords.remove(keyword)
        } else {
            selectedKeywords.insert(keyword)
        }
    }
    
    // 問題選択のトグル
    func toggleQuestionSelection(_ question: ComparisonQuestion) {
        if let id = question.id?.uuidString, !id.isEmpty {
            if selectedQuestions.contains(id) {
                selectedQuestions.remove(id)
            } else {
                selectedQuestions.insert(id)
            }
        }
    }
    
    // 選択したアイテムを削除
    func deleteSelectedItems() {
        // 選択したキーワードを削除
        editingKeywords.removeAll { selectedKeywords.contains($0) }
        
        // 選択した問題を削除
        for question in comparisonQuestions.wrappedValue {
            if let id = question.id?.uuidString, selectedQuestions.contains(id) {
                viewContext.delete(question)
            }
        }
        
        // 保存
        do {
            try viewContext.save()
            
            // 問題リストを更新
            if let memo = memo {
                loadComparisonQuestions(for: memo)
            }
            
            // 選択をクリア
            selectedKeywords.removeAll()
            selectedQuestions.removeAll()
            
            // 編集モードを終了
            isEditMode = false
        } catch {
            // エラーメッセージを直接保存
            self.error = "データ保存に失敗しました: \(error.localizedDescription)"
            print("❌ 選択アイテム削除エラー: \(error.localizedDescription)")
        }
    }
    
    // キーワード追加
    func addKeyword() {
        let trimmedKeyword = newKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKeyword.isEmpty else { return }
        
        if !editingKeywords.contains(trimmedKeyword) {
            editingKeywords.append(trimmedKeyword)
            newKeyword = ""
        }
    }
    
    // キーワード削除
    func deleteKeyword(at offsets: IndexSet) {
        editingKeywords.remove(atOffsets: offsets)
    }
    
    // 比較問題削除
    func deleteComparisonQuestion(at offsets: IndexSet) {
        for index in offsets {
            let question = comparisonQuestions.wrappedValue[index]
            viewContext.delete(question)
        }
        
        do {
            try viewContext.save()
            
            // 問題リストを更新
            if let memo = memo {
                loadComparisonQuestions(for: memo)
            }
        } catch {
            // エラーメッセージを直接保存
            self.error = "データ保存に失敗しました: \(error.localizedDescription)"
            print("❌ 比較問題削除エラー: \(error.localizedDescription)")
        }
    }
    
    // 変更を保存
    func saveChanges(completion: @escaping () -> Void) {
        // キーワードの変更を保存
        keywords.wrappedValue = editingKeywords
        
        // メモがある場合はCoreDataにも保存
        if let memoToSave = memo {
            memoToSave.keywords = editingKeywords.joined(separator: ",")
            
            do {
                try viewContext.save()
                print("✅ キーワード保存完了: \(editingKeywords.count)個")
            } catch {
                // エラーメッセージを直接保存
                self.error = "データ保存に失敗しました: \(error.localizedDescription)"
                print("❌ キーワード保存エラー: \(error.localizedDescription)")
            }
        }
        
        completion()
    }
    
    // 比較問題を読み込む
    func loadComparisonQuestions(for memo: Memo) {
        QuestionService.shared.loadComparisonQuestions(
            for: memo,
            viewContext: viewContext
        ) { [weak self] questions in
            DispatchQueue.main.async {
                // 親のBindingを更新
                self?.comparisonQuestions.wrappedValue = questions
            }
        }
    }
    
    // クリップボードコピー用メソッド
    func copyQuestionsToClipboard() {
        let items = generateQuestionItems()
        let clipboardText = QuestionService.shared.formatQuestionsForClipboard(questions: items)
        UIPasteboard.general.string = clipboardText
    }
    
    // インポートされた回答を適用するメソッド
    func applyImportedAnswers(_ answers: [String: String]) {
        let items = generateQuestionItems()
        
        QuestionService.shared.applyImportedAnswers(
            answers: answers,
            questions: items
        ) { [weak self] in
            guard let self = self else { return }
            
            // キーワード問題の回答を処理
            for (index, keyword) in self.editingKeywords.enumerated() {
                let questionNumber = index + 1
                if let answer = answers[String(questionNumber)] {
                    // キーワード問題の回答を保存
                    QuestionService.shared.saveKeywordAnswer(keyword: keyword, answer: answer)
                }
            }
            
            // 比較問題の回答を処理
            let keywordCount = self.editingKeywords.count
            for (index, question) in self.comparisonQuestions.wrappedValue.enumerated() {
                let questionNumber = keywordCount + index + 1
                if let answer = answers[String(questionNumber)] {
                    // 比較問題の回答を保存
                    QuestionService.shared.saveComparisonQuestionAnswer(
                        question: question,
                        answer: answer,
                        viewContext: self.viewContext
                    )
                }
            }
            // 追加: 明示的に通知を送信
            DispatchQueue.main.async {
                print("📣 回答インポート完了通知を送信します")
                NotificationCenter.default.post(name: NSNotification.Name("AnswersImported"), object: nil)
                
                // 1秒後に再度通知を送信（UI更新のタイミング問題に対処）
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    NotificationCenter.default.post(name: NSNotification.Name("AnswersImported"), object: nil)
                }
            }
        }
    }
    
    func generateQuestionItems() -> [QuestionItem] {
        var items: [QuestionItem] = []
        let registry = QuestionItemRegistry.shared
        
        // キーワードから問題アイテムを生成
        for keyword in keywords.wrappedValue {
            // UserDefaultsから回答を取得
            let answerKey = "keyword_answer_\(keyword)"
            let answer = UserDefaults.standard.string(forKey: answerKey)
            
            // 既存のアイテムを取得または新規作成
            let item = registry.getOrCreateQuestionItem(
                id: "keyword_\(keyword)",
                questionText: "「\(keyword)」について説明してください。",
                subText: "この概念、特徴、重要性について詳しく述べてください。",
                isExplanation: true
            )
            
            // 回答を設定（もし異なる場合）
            if item.answer != answer {
                item.answer = answer
            }
            
            items.append(item)
        }
        
        // 比較問題から問題アイテムを生成
        for question in comparisonQuestions.wrappedValue {
            let questionId = question.id?.uuidString ?? UUID().uuidString
            
            // 既存のアイテムを取得または新規作成
            let item = registry.getOrCreateQuestionItem(
                id: questionId,
                questionText: question.question ?? "",
                subText: question.note ?? "",
                isExplanation: false
            )
            
            // 回答を設定（もし異なる場合）
            if item.answer != question.answer {
                item.answer = question.answer
            }
            
            items.append(item)
        }
        
        return items
    }
}

// 拡張メソッド
extension QuestionEditorViewModel {
    // キーワード更新メソッド
    func updateKeyword(at index: Int, newKeyword: String) {
        guard index < editingKeywords.count else { return }
        let oldKeyword = editingKeywords[index]
        
        // キーワードを更新
        editingKeywords[index] = newKeyword
        
        // 選択セットも更新
        if selectedKeywords.contains(oldKeyword) {
            selectedKeywords.remove(oldKeyword)
            selectedKeywords.insert(newKeyword)
        }
        
        // UserDefaultsの回答も移行
        let oldAnswerKey = "keyword_answer_\(oldKeyword)"
        let newAnswerKey = "keyword_answer_\(newKeyword)"
        
        if let oldAnswer = UserDefaults.standard.string(forKey: oldAnswerKey) {
            UserDefaults.standard.set(oldAnswer, forKey: newAnswerKey)
        }
    }
    
    // 比較問題更新メソッド
    func updateComparisonQuestion(_ question: ComparisonQuestion, newText: String, newNote: String?) {
        question.question = newText
        question.note = newNote
        
        do {
            try viewContext.save()
        } catch {
            self.error = "比較問題の更新に失敗しました: \(error.localizedDescription)"
        }
    }
}
