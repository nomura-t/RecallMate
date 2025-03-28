import SwiftUI
import CoreData
import Combine
import Foundation

// カルーセル用の状態を管理するクラス
class CarouselState: ObservableObject {
    @Published var questions: [QuestionItem] = []
    @Published var currentIndex = 0
    @Published var showAnswerImport = false
    @Published var isLoading = false
    @Published var error: AppError? = nil
    
    // パフォーマンス最適化用のプロパティ
    private var cancellables = Set<AnyCancellable>()
    private var loadTask: DispatchWorkItem?
    private var lastKeywords: [String] = []
    private var lastQuestionIds: [String] = []
    
    init() {
        // 現在の問題の回答状態を監視
        $questions
            .sink { [weak self] questions in
                // 質問数が変更された場合は現在のインデックスが範囲内かチェック
                if let self = self, !questions.isEmpty && self.currentIndex >= questions.count {
                    self.currentIndex = max(0, questions.count - 1)
                }
            }
            .store(in: &cancellables)
    }
    
    // 質問の読み込みを最適化
    func loadQuestions(
        keywords: [String],
        comparisonQuestions: [ComparisonQuestion],
        viewContext: NSManagedObjectContext
    ) {
        // 現在実行中のタスクをキャンセル
        loadTask?.cancel()
        
        // キャッシュを活用するために、前回と同じデータかチェック
        let questionIds = comparisonQuestions.compactMap { $0.id?.uuidString }
        
        // キーワードと問題IDが同じなら再読み込みをスキップ
        if !isLoading &&
           lastKeywords == keywords &&
           lastQuestionIds == questionIds &&
           !questions.isEmpty {
            return
        }
        
        // 読み込み状態を更新
        isLoading = true
        
        // 新しいタスクを作成
        let task = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            // キャンセルされたかチェック - self.loadTaskを使用
            if self.loadTask?.isCancelled ?? true {
                return
            }
            
            // QuestionServiceを使用して問題を読み込む
            QuestionService.shared.loadAllQuestions(
                for: nil, // メモは不要（既にcomparisonQuestionsを持っている）
                keywords: keywords,
                viewContext: viewContext
            ) { [weak self] loadedQuestions in
                guard let self = self else { return }
                
                // キャンセルされたかチェック
                if self.loadTask?.isCancelled ?? true {
                    return
                }
                
                // comparisonQuestionsからQuestionItem配列を生成
                var items = loadedQuestions
                
                for question in comparisonQuestions {
                    items.append(QuestionItem(
                        id: question.id?.uuidString ?? UUID().uuidString,
                        questionText: question.question ?? "",
                        subText: question.note ?? "",
                        isExplanation: false,
                        answer: question.answer,
                        onAnswerChanged: { newAnswer in
                            QuestionService.shared.saveComparisonQuestionAnswer(
                                question: question,
                                answer: newAnswer,
                                viewContext: viewContext
                            )
                        }
                    ))
                }
                
                // 読み込みが完了したらメインスレッドで状態を更新
                DispatchQueue.main.async {
                    if !(self.loadTask?.isCancelled ?? true) {
                        self.questions = items
                        self.lastKeywords = keywords
                        self.lastQuestionIds = questionIds
                        self.isLoading = false
                        print("📊 問題数: \(items.count)")
                    }
                }
            }
        }
        
        // タスクを保存して実行
        self.loadTask = task
        DispatchQueue.global(qos: .userInitiated).async(execute: task)
    }
    
    // インポートされた回答を適用
    func applyImportedAnswers(_ answers: [String: String]) {
        QuestionService.shared.applyImportedAnswers(
            answers: answers,
            questions: questions
        ) {
            // 必要に応じてUIの更新処理を追加
            print("✅ 回答のインポートが完了しました")
        }
    }
    
    // 問題をクリップボードにコピー
    func copyQuestionsToClipboard() {
        let clipboardText = QuestionService.shared.formatQuestionsForClipboard(questions: questions)
        UIPasteboard.general.string = clipboardText
        print("📋 \(questions.count)個の問題をクリップボードにコピーしました")
    }
    
    // 次の問題に移動 - デバッグログを追加
    func moveToNextQuestion() {
        guard !questions.isEmpty else { return }
        let oldIndex = currentIndex
        currentIndex = (currentIndex + 1) % questions.count
    }
    
    // 前の問題に移動 - デバッグログを追加
    func moveToPreviousQuestion() {
        guard !questions.isEmpty else { return }
        let oldIndex = currentIndex
        currentIndex = (currentIndex - 1 + questions.count) % questions.count
    }
    
    // まだ回答のない問題に移動
    func moveToUnansweredQuestion() {
        guard !questions.isEmpty else { return }
        
        // 現在の位置から次の未回答問題を探す
        let startIndex = currentIndex
        var index = (startIndex + 1) % questions.count
        
        while index != startIndex {
            if !questions[index].hasAnswer {
                currentIndex = index
                return
            }
            index = (index + 1) % questions.count
        }
        
        // 見つからなかった場合は現在位置を維持
    }
    
    // リソースの解放
    func cleanup() {
        loadTask?.cancel()
        loadTask = nil
        cancellables.removeAll()
    }
    
    deinit {
        cleanup()
    }
    
    func loadQuestionsFromRegistry(
        keywords: [String],
        comparisonQuestions: [ComparisonQuestion]
    ) {
        // 以前のデータを保存
        lastKeywords = keywords
        lastQuestionIds = comparisonQuestions.compactMap { $0.id?.uuidString }
        
        // レジストリから問題を生成
        var items: [QuestionItem] = []
        let registry = QuestionItemRegistry.shared
        
        // キーワードの問題を追加
        for keyword in keywords {
            let id = "keyword_\(keyword)"
            let answerKey = "keyword_answer_\(keyword)"
            let savedAnswer = UserDefaults.standard.string(forKey: answerKey)
            
            let item = registry.getOrCreateQuestionItem(
                id: id,
                questionText: "「\(keyword)」について説明してください。",
                subText: "この概念、特徴、重要性について詳しく述べてください。",
                isExplanation: true
            )
            
            // 保存されている回答と異なる場合は更新
            if item.answer != savedAnswer {
                item.answer = savedAnswer
            }
            
            items.append(item)
        }
        
        // 比較問題を追加
        for question in comparisonQuestions {
            if let id = question.id?.uuidString {
                let item = registry.getOrCreateQuestionItem(
                    id: id,
                    questionText: question.question ?? "",
                    subText: question.note ?? "",
                    isExplanation: false
                )
                
                // 保存されている回答と異なる場合は更新
                if item.answer != question.answer {
                    item.answer = question.answer
                }
                
                items.append(item)
            }
        }
        
        // 質問リストを更新
        DispatchQueue.main.async {
            self.questions = items
            self.isLoading = false
        }
    }
    func refreshAnswers() {
        print("♻️ カルーセル状態を強制更新します")
        
        // 質問アイテムの回答状態を更新
        for question in questions {
            if question.id.starts(with: "keyword_") {
                let keyword = question.id.replacingOccurrences(of: "keyword_", with: "")
                let answerKey = "keyword_answer_\(keyword)"
                let savedAnswer = UserDefaults.standard.string(forKey: answerKey)
                
                // 更新が必要な場合のみ
                if question.answer != savedAnswer {
                    question.answer = savedAnswer
                }
            }
        }
        
        // 更新通知を発行
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("AnswersUpdated"), object: nil)
        }
    }
}
