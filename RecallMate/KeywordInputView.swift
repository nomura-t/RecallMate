import SwiftUI
import CoreData

struct KeywordInputView: View {
    @Binding var keywords: [String]
    let memo: Memo?
    let viewContext: NSManagedObjectContext
    @Binding var comparisonQuestions: [ComparisonQuestion]
    @Binding var showCustomQuestionCreator: Bool
    
    @State private var newKeyword = ""
    
    var body: some View {
        Section(header: Text("重要単語リスト".localized)) {
            VStack {
                TextEditor(text: $newKeyword)
                    .frame(height: 40) // 高さを40に縮小（元の60から縮小）
                    .padding(4)        // パディングを4に縮小（元の8から縮小）
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .ignoresSafeArea(.keyboard, edges: .bottom)  // この行を追加
                    .onChange(of: newKeyword) { oldValue, newValue in
                        // 改行を検知
                        if newValue.contains("\n") {
                            // 改行を削除して単語を抽出
                            let lines = newValue.components(separatedBy: "\n")
                            
                            for line in lines where !line.isEmpty {
                                processInputLine(line)
                            }
                            
                            // 入力フィールドをクリア
                            newKeyword = ""
                        }
                    }
                    .overlay(
                        Group {
                            if newKeyword.isEmpty {
                                Text("新しい単語を入力して改行で追加\n(スペースで区切った2つの単語は比較問題になります)".localized)
                                    .foregroundColor(.gray)
                                    .padding(6)  // パディングを縮小
                                    .font(.caption2) // フォントサイズを縮小
                                    .allowsHitTesting(false)
                            }
                        }, alignment: .topLeading
                    )
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        if !newKeyword.isEmpty {
                            processInputLine(newKeyword)
                            newKeyword = ""
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 24))
                    }
                    .disabled(newKeyword.isEmpty)
                }
            }
            
            if !keywords.isEmpty {
                List {
                    ForEach(keywords, id: \.self) { keyword in
                        Text(keyword)
                    }
                    .onDelete(perform: deleteKeywords)
                }
            }
        }
    }
    
    private func processInputLine(_ line: String) {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        // 半角スペースと全角スペースを正確に検出する改良版
        let halfWidthSpace = " "
        let fullWidthSpace = "\u{3000}"
        
        // 入力に半角または全角スペースが含まれているか確認
        if trimmed.contains(halfWidthSpace) || trimmed.contains(fullWidthSpace) {
            // スペースで分割
            var components: [String] = []
            
            // 半角スペースで分割
            if trimmed.contains(halfWidthSpace) {
                components = trimmed.components(separatedBy: halfWidthSpace)
            }
            // 全角スペースで分割
            else if trimmed.contains(fullWidthSpace) {
                components = trimmed.components(separatedBy: fullWidthSpace)
            }
            
            // 空の要素を除去
            components = components.filter { !$0.isEmpty }
            if components.count >= 2 {
                // 最初の2つの単語で比較問題を作成
                createComparisonQuestion(components[0], components[1])
                return
            }
        }
        
        // スペースで区切られていない場合や、単語が1つしかない場合は通常の単語として追加
        addKeywordWithText(trimmed)
    }
    
    private func addKeywordWithText(_ text: String) {
        let trimmedKeyword = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKeyword.isEmpty else { return }
        
        if !keywords.contains(trimmedKeyword) {
            keywords.append(trimmedKeyword)
        }
    }
    
    private func createComparisonQuestion(_ word1: String, _ word2: String) {
        // 両方の単語を追加（説明問題用）
        let trimmedWord1 = word1.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedWord2 = word2.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !trimmedWord1.isEmpty && !keywords.contains(trimmedWord1) {
            keywords.append(trimmedWord1)
        }
        
        if !trimmedWord2.isEmpty && !keywords.contains(trimmedWord2) {
            keywords.append(trimmedWord2)
        }
        
        // 記録がない場合（新規作成中の場合）は、一時的な記録を作成
        if memo == nil {
            // キーワードは既に追加済み。実際の比較問題保存は、記録保存時に行われる
            
            // 何らかの形で比較問題情報を保存する必要がある場合は、
            // UserDefaultsやアプリ内の一時データ構造を使用することも検討できます
            
            // 例: UserDefaultsに一時保存
            var tempComparisonPairs = UserDefaults.standard.array(forKey: "tempComparisonPairs") as? [[String]] ?? []
            tempComparisonPairs.append([trimmedWord1, trimmedWord2])
            UserDefaults.standard.set(tempComparisonPairs, forKey: "tempComparisonPairs")
            // UIに仮表示用の比較問題を追加（非永続的）
            let tempQuestion = ComparisonQuestion(context: viewContext)
            tempQuestion.id = UUID()
            let questionTemplate = "「%@」と「%@」の違いを比較して説明してください。それぞれの特徴、共通点、相違点について詳細に述べてください。".localizedFormat(trimmedWord1, trimmedWord2)
            tempQuestion.question = questionTemplate
            tempQuestion.createdAt = Date()
            
            // viewContextに追加せず、一時リストに追加
            var tempList = comparisonQuestions
            tempList.append(tempQuestion)
            comparisonQuestions = tempList
            
            return
        }
        
        // 既存の記録がある場合は通常通り保存
        let newQuestion = ComparisonQuestion(context: viewContext)
        newQuestion.id = UUID()
        newQuestion.question = "「%@」と「%@」の違いを比較して説明してください。それぞれの特徴、共通点、相違点について詳細に述べてください。".localizedFormat(trimmedWord1, trimmedWord2)
        newQuestion.createdAt = Date()
        newQuestion.memo = memo
        
        do {
            try viewContext.save()
            // 保存後に問題リストを更新
            let fetchRequest: NSFetchRequest<ComparisonQuestion> = ComparisonQuestion.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "memo == %@", memo!)
            
            do {
                let fetchedQuestions = try viewContext.fetch(fetchRequest)
                // comparisonQuestionsの更新
                comparisonQuestions = fetchedQuestions
                
            } catch {
            }
        } catch {
        }
    }
    
    private func deleteKeywords(at offsets: IndexSet) {
        keywords.remove(atOffsets: offsets)
    }
}
