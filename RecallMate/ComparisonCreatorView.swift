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
                Section(header: Text("選択された単語".localized)) {
                    ForEach(selectedKeywords, id: \.self) { keyword in
                        Text(keyword)
                    }
                }
                
                Section(header: Text("比較問題".localized)) {
                    TextEditor(text: $comparisonQuestion)
                        .frame(height: 120)
                        .overlay(
                            Group {
                                if comparisonQuestion.isEmpty {
                                    Text(String(format: "例: 「%@」と「%@」の違いを比較して説明してください。".localized, selectedKeywords.first ?? "概念A", selectedKeywords.count > 1 ? selectedKeywords[1] : "概念B"))
                                        .foregroundColor(.gray)
                                        .padding(8)
                                        .allowsHitTesting(false)
                                }
                            }, alignment: .topLeading
                        )
                }
                
                Section(header: Text("記録（オプション）".localized)) {
                    TextEditor(text: $comparisonNote)
                        .frame(height: 100)
                        .overlay(
                            Group {
                                if comparisonNote.isEmpty {
                                    Text("この比較に関する記録やヒントを入力できます".localized)
                                        .foregroundColor(.gray)
                                        .padding(8)
                                        .allowsHitTesting(false)
                                }
                            }, alignment: .topLeading
                        )
                }
                
                Button(action: saveComparisonQuestion) {
                    Text("比較問題を保存".localized)
                        .frame(maxWidth: .infinity)
                }
                .disabled(comparisonQuestion.isEmpty)
            }
            .navigationTitle("比較問題の作成".localized)
            .navigationBarItems(trailing: Button("キャンセル".localized) { onCancel() })
            .onAppear {
                // デフォルトの問題文を設定
                if comparisonQuestion.isEmpty && selectedKeywords.count >= 2 {
                    let format = "「%@」と「%@」の違いを比較して説明してください。それぞれの特徴、共通点、相違点について詳細に述べてください。".localized
                    comparisonQuestion = String(format: format, selectedKeywords[0], selectedKeywords[1])
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
        }
    }
}
