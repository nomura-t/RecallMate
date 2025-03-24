import Foundation
// 問題アイテムモデル
class QuestionItem: Identifiable {
    let id: String
    let questionText: String
    let subText: String
    let isExplanation: Bool
    private var _answer: String?
    var onAnswerChanged: ((String?) -> Void)?
    
    var answer: String? {
        get { return _answer }
        set {
            // null回答や空文字列の場合も有効な値として扱う
            _answer = newValue
            onAnswerChanged?(newValue)
        }
    }
    
    var hasAnswer: Bool { return _answer != nil && !_answer!.isEmpty }
    
    init(id: String, questionText: String, subText: String, isExplanation: Bool, answer: String?, onAnswerChanged: ((String?) -> Void)?) {
        self.id = id
        self.questionText = questionText
        self.subText = subText
        self.isExplanation = isExplanation
        self._answer = answer
        self.onAnswerChanged = onAnswerChanged
    }
}
