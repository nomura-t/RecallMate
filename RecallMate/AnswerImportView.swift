import SwiftUI

// 回答インポート完了時のコールバック型を定義
typealias AnswerImportCompletion = ([String: String]) -> Void

struct AnswerImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var allQuestions: [QuestionItem]
    @State private var aiResponse = ""
    @State private var processedAnswers: [String: String] = [:]
    @State private var questionIndexesToConfirm: [Int] = []
    @State private var showingConfirmDialog = false
    @State private var errorMessage: String? = nil
    @State private var showingErrorAlert = false
    
    // 完了時のコールバックを追加
    var onComplete: AnswerImportCompletion? = nil
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section(header: Text("生成AIの回答を貼り付け".localized)) {
                        TextEditor(text: $aiResponse)
                            .frame(height: 200)
                            .onChange(of: aiResponse) { _, newValue in
                                processAnswers(newValue)
                            }
                    }
                    
                    if !processedAnswers.isEmpty {
                        Section(header: Text("検出された回答".localized)) {
                            ForEach(Array(processedAnswers.keys.sorted()), id: \.self) { key in
                                VStack(alignment: .leading) {
                                    Text("問題\(key)")
                                        .font(.headline)
                                    
                                    Text(processedAnswers[key] ?? "")
                                        .font(.body)
                                        .lineLimit(3)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
                
                Button(action: checkForExistingAnswers) {
                    Text("回答を適用".localized)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
                .disabled(processedAnswers.isEmpty)
            }
            .navigationTitle("回答のインポート")
            .navigationBarItems(leading: Button("キャンセル") { dismiss() })
            .alert("エラー", isPresented: $showingErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "不明なエラーが発生しました".localized)
            }
            .alert("既存の回答を上書きしますか？".localized, isPresented: $showingConfirmDialog) {
                Button("すべて上書き", role: .destructive) {
                    applyAnswers(overwriteAll: true)
                }
                Button("新規のみ適用") {
                    applyAnswers(overwriteAll: false)
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("\(questionIndexesToConfirm.count)個の問題にすでに回答があります。")
            }
        }
    }
    
    private func processAnswers(_ text: String) {
        // QuestionServiceを使用して処理
        QuestionService.shared.processAnswerText(text) { result in
            self.processedAnswers = result
        }
    }
    
    private func checkForExistingAnswers() {
        questionIndexesToConfirm.removeAll()
        
        for i in 0..<allQuestions.count {
            let questionIndex = i + 1
            if let _ = processedAnswers[String(questionIndex)], allQuestions[i].hasAnswer {
                questionIndexesToConfirm.append(i)
            }
        }
        
        if questionIndexesToConfirm.isEmpty {
            // 上書きする既存回答がない場合は直接適用
            applyAnswers(overwriteAll: true)
        } else {
            showingConfirmDialog = true
        }
    }
    
    private func applyAnswers(overwriteAll: Bool) {
        // QuestionServiceを使用して回答を適用
        QuestionService.shared.applyImportedAnswers(
            answers: processedAnswers,
            questions: allQuestions,
            overwriteAll: overwriteAll
        ) {
            // コールバックを呼び出し
            onComplete?(processedAnswers)
            dismiss()
        }
    }
}
