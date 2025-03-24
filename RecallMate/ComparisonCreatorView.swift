import SwiftUI
import CoreData

struct ComparisonCreatorView: View {
    let selectedKeywords: [String]
    let memo: Memo?
    let viewContext: NSManagedObjectContext
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @State private var comparisonQuestion = ""
    @State private var comparisonNote = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("選択された単語")) {
                    ForEach(selectedKeywords, id: \.self) { keyword in
                        Text(keyword)
                    }
                }
                
                Section(header: Text("比較問題")) {
                    TextEditor(text: $comparisonQuestion)
                        .frame(height: 120)
                        .overlay(
                            Group {
                                if comparisonQuestion.isEmpty {
                                    Text("例: 「\(selectedKeywords.first ?? "概念A")」と「\(selectedKeywords.count > 1 ? selectedKeywords[1] : "概念B")」の違いを比較して説明してください。")
                                        .foregroundColor(.gray)
                                        .padding(8)
                                        .allowsHitTesting(false)
                                }
                            }, alignment: .topLeading
                        )
                }
                
                Section(header: Text("メモ（オプション）")) {
                    TextEditor(text: $comparisonNote)
                        .frame(height: 100)
                        .overlay(
                            Group {
                                if comparisonNote.isEmpty {
                                    Text("この比較に関するメモやヒントを入力できます")
                                        .foregroundColor(.gray)
                                        .padding(8)
                                        .allowsHitTesting(false)
                                }
                            }, alignment: .topLeading
                        )
                }
                
                Button(action: saveComparisonQuestion) {
                    Text("比較問題を保存")
                        .frame(maxWidth: .infinity)
                }
                .disabled(comparisonQuestion.isEmpty)
            }
            .navigationTitle("比較問題の作成")
            .navigationBarItems(trailing: Button("キャンセル") { onCancel() })
            .onAppear {
                // デフォルトの問題文を設定
                if comparisonQuestion.isEmpty && selectedKeywords.count >= 2 {
                    comparisonQuestion = "「\(selectedKeywords[0])」と「\(selectedKeywords[1])」の違いを比較して説明してください。それぞれの特徴、共通点、相違点について詳細に述べてください。"
                }
            }
        }
    }
    
    private func saveComparisonQuestion() {
        guard !comparisonQuestion.isEmpty, let memo = memo else { return }
        
        // CoreDataに比較問題を保存
        let newQuestion = ComparisonQuestion(context: viewContext)
        newQuestion.id = UUID()
        newQuestion.question = comparisonQuestion
        newQuestion.note = comparisonNote.isEmpty ? nil : comparisonNote
        newQuestion.createdAt = Date()
        newQuestion.memo = memo
        
        do {
            try viewContext.save()
            onSave()
        } catch {
            print("❌ 比較問題保存エラー: \(error.localizedDescription)")
        }
    }
}
