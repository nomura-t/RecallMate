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
                                Text("「\(keyword)」について説明してください。")
                                    .font(.headline)
                                
                                Text("概念、特徴、重要性について詳しく述べてください。")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                } header: {
                    Button(action: { isExplanationQuestionsExpanded.toggle() }) {
                        HStack {
                            Text("説明問題 (\(keywords.count))")
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
                    Text("保存された問題はありません")
                        .foregroundColor(.gray)
                        .italic()
                } else if isComparisonQuestionsExpanded {
                    ForEach(comparisonQuestions) { question in
                        VStack(alignment: .leading) {
                            Text(question.question ?? "")
                                .font(.headline)
                            
                            if let note = question.note, !note.isEmpty {
                                Text("メモ: \(note)")
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
                        Text("保存された問題 (\(comparisonQuestions.count))")
                        Spacer()
                        Image(systemName: isComparisonQuestionsExpanded ? "chevron.up" : "chevron.down")
                    }
                }
                .foregroundColor(.primary)
            }
        }
        .onAppear {
            print("🔄 QuestionListView appeared with \(comparisonQuestions.count) comparison questions")
            
            // 各問題の内容を表示
            for (index, question) in comparisonQuestions.enumerated() {
                print("表示する問題 #\(index+1): \(question.question ?? "nil")")
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
            print("✅ 問題を削除しました")
            // 比較問題リストを更新
            onQuestionsUpdated()
        } catch {
            print("❌ 比較問題削除エラー: \(error.localizedDescription)")
        }
    }
}
