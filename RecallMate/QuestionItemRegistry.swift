// RecallMate/QuestionItemRegistry.swift
import Foundation
import Combine

class QuestionItemRegistry {
    static let shared = QuestionItemRegistry()
    
    private var questionItems: [String: QuestionItem] = [:]
    private let updateSubject = PassthroughSubject<Void, Never>()
    var updates: AnyPublisher<Void, Never> {
        return updateSubject.eraseToAnyPublisher()
    }
    
    private init() {}
    
    // キーワードまたはIDに基づいて既存のQuestionItemを取得または新規作成
    func getOrCreateQuestionItem(id: String, questionText: String, subText: String, isExplanation: Bool) -> QuestionItem {
        if let existingItem = questionItems[id] {
            return existingItem
        }
        
        let newItem = QuestionItem(
            id: id,
            questionText: questionText,
            subText: subText,
            isExplanation: isExplanation,
            answer: nil,
            onAnswerChanged: { [weak self] _ in
                // 回答が変更されたら更新通知を発行
                self?.updateSubject.send()
            }
        )
        
        questionItems[id] = newItem
        return newItem
    }
    
    // 欠けていたgetItemByIdメソッドを追加
    func getItemById(_ id: String) -> QuestionItem? {
        return questionItems[id]
    }
    
    // レジストリをクリア（必要に応じて）
    func clearItems() {
        questionItems.removeAll()
    }
    
    // 強制的に更新通知を発行
    func notifyUpdates() {
        updateSubject.send()
    }
}
