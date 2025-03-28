import SwiftUI
import CoreData

struct CustomQuestionCreatorView: View {
    let memo: Memo?
    let viewContext: NSManagedObjectContext
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @State private var questionText = ""
    @State private var questionNote = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("カスタム問題文")) {
                    TextEditor(text: $questionText)
                        .frame(height: 120)
                        .overlay(
                            Group {
                                if questionText.isEmpty {
                                    Text("例: この章で学んだ内容を要約してください。")
                                        .foregroundColor(.gray)
                                        .padding(8)
                                        .allowsHitTesting(false)
                                }
                            }, alignment: .topLeading
                        )
                        .ignoresSafeArea(.keyboard, edges: .bottom)
                }
                
                Section(header: Text("メモ（オプション）")) {
                    TextEditor(text: $questionNote)
                        .frame(height: 100)
                        .overlay(
                            Group {
                                if questionNote.isEmpty {
                                    Text("この問題に関するメモやヒントを入力できます")
                                        .foregroundColor(.gray)
                                        .padding(8)
                                        .allowsHitTesting(false)
                                }
                            }, alignment: .topLeading
                        )
                        .ignoresSafeArea(.keyboard, edges: .bottom)
                }
                
                Button(action: saveCustomQuestion) {
                    Text("問題を保存")
                        .frame(maxWidth: .infinity)
                }
                .disabled(questionText.isEmpty)
            }
            .navigationTitle("カスタム問題作成")
            .navigationBarItems(trailing: Button("キャンセル") { onCancel() })
        }
    }
    
    private func saveCustomQuestion() {
        guard !questionText.isEmpty else {
            return
        }
        
        if memo == nil {
            // UserDefaultsに一時保存
            var tempCustomQuestions = UserDefaults.standard.array(forKey: "tempCustomQuestions") as? [[String]] ?? []
            let note = questionNote.isEmpty ? "" : questionNote
            tempCustomQuestions.append([questionText, note])
            UserDefaults.standard.set(tempCustomQuestions, forKey: "tempCustomQuestions")
            onSave()
            return
        }
        
        // 既存のメモがある場合は通常通り保存
        let newQuestion = ComparisonQuestion(context: viewContext)
        newQuestion.id = UUID()
        newQuestion.question = questionText
        newQuestion.note = questionNote.isEmpty ? nil : questionNote
        newQuestion.createdAt = Date()
        newQuestion.memo = memo
        
        do {
            try viewContext.save()
            onSave()
        } catch {
        }
    }
}
