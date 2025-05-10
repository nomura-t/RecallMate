import SwiftUI
import CoreData

struct QuestionListView: View {
    // 読み取り専用のプロパティ
    let keywords: [String]
    let comparisonQuestions: [ComparisonQuestion]
    
    // 状態管理用のバインディング
    @Binding var isExplanationQuestionsExpanded: Bool
    @Binding var isComparisonQuestionsExpanded: Bool
    
    // CoreDataコンテキストと更新コールバック
    let viewContext: NSManagedObjectContext
    let onQuestionsUpdated: () -> Void
    
    var body: some View {
        Group {
            // 自動生成された説明問題リスト
            if !keywords.isEmpty {
                Section {
                    if isExplanationQuestionsExpanded {
                        ForEach(keywords, id: \.self) { keyword in
                            VStack(alignment: .leading) {
                                Text("「%@」について説明してください。".localizedFormat(keyword))                                    .font(.headline)
                                
                                Text("概念、特徴、重要性について詳しく述べてください。".localized)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                } header: {
                    Button(action: { isExplanationQuestionsExpanded.toggle() }) {
                        HStack {
                            Text("説明問題 (%d)".localizedWithInt(keywords.count))
                            Spacer()
                            Image(systemName: isExplanationQuestionsExpanded ? "chevron.up" : "chevron.down")
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            
            // 保存された比較問題リスト
            Section {
                if comparisonQuestions.isEmpty {
                    Text("保存された問題はありません".localized)
                        .foregroundColor(.gray)
                        .italic()
                } else if isComparisonQuestionsExpanded {
                    ForEach(comparisonQuestions) { question in
                        VStack(alignment: .leading) {
                            Text(question.question ?? "")
                                .font(.headline)
                            
                            if let note = question.note, !note.isEmpty {
                                Text("メモ: %@".localizedFormat(note))
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .onDelete(perform: deleteComparisonQuestion)
                }
            } header: {
                Button(action: { isComparisonQuestionsExpanded.toggle() }) {
                    HStack {
                        Text("保存された問題 (%d)".localizedWithInt(comparisonQuestions.count))
                        Spacer()
                        Image(systemName: isComparisonQuestionsExpanded ? "chevron.up" : "chevron.down")
                    }
                }
                .foregroundColor(.primary)
            }
        }
        .onAppear {
            // 各問題の内容を表示
            for (index, question) in comparisonQuestions.enumerated() {
            }
        }
    }
    
    // 比較問題の削除
    private func deleteComparisonQuestion(at offsets: IndexSet) {
        for index in offsets {
            let question = comparisonQuestions[index]
            viewContext.delete(question)
        }
        
        // CoreDataを保存
        do {
            try viewContext.save()
            // 比較問題リストを更新
            onQuestionsUpdated()
        } catch {
        }
    }
}
