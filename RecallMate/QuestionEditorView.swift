import SwiftUI
import CoreData

struct QuestionEditorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let memo: Memo?
    @Binding var keywords: [String]
    @Binding var comparisonQuestions: [ComparisonQuestion]
    
    @StateObject private var viewModel: QuestionEditorViewModel
    @State private var showNewQuestionSheet = false
    @State private var showAnswerImport = false
    @State private var showAlert = false
    @State private var selectedTab = 0 // タブ選択用の状態変数
    
    // 編集用の状態変数
    @State private var showKeywordEditSheet = false
    @State private var editingKeywordInfo: (String, Int)? = nil
    @State private var showQuestionEditSheet = false
    @State private var editingQuestion: ComparisonQuestion? = nil
    
    @State private var showUsageModal = false

    // 初期化時に既存のキーワードをコピー
    init(memo: Memo?, keywords: Binding<[String]>, comparisonQuestions: Binding<[ComparisonQuestion]>) {
        self.memo = memo
        self._keywords = keywords
        self._comparisonQuestions = comparisonQuestions
        self._viewModel = StateObject(wrappedValue:
            QuestionEditorViewModel(
                memo: memo,
                keywords: keywords,
                comparisonQuestions: comparisonQuestions,
                viewContext: PersistenceController.shared.container.viewContext
            )
        )
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // タブビュー切り替え用のセグメントコントロール
                Picker("編集モード", selection: $selectedTab) {
                    Text("問題編集").tag(0)
                    Text("回答編集").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // 選択されたタブに応じてビューを切り替え
                TabView(selection: $selectedTab) {
                    // 問題リスト編集タブ
                    problemListTab
                        .tag(0)
                    
                    // 回答編集タブ
                    answerEditTab
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: selectedTab)
            }
            .toolbar {
                // 共通のナビゲーションバーアイテム
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(viewModel.isEditMode ? "キャンセル" : "キャンセル") {
                        if viewModel.isEditMode {
                            // 編集モードを終了
                            viewModel.isEditMode = false
                            viewModel.selectedKeywords.removeAll()
                            viewModel.selectedQuestions.removeAll()
                        } else {
                            dismiss()
                        }
                    }
                }
                // 使い方ボタンを追加 - 位置は右上
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showUsageModal = true
                    }) {
                        Image(systemName: "info.circle")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                }

                // タブに応じて右側のボタンを変更
                ToolbarItem(placement: .navigationBarTrailing) {
                    if selectedTab == 0 {
                        // 問題リスト編集用ツールバー
                        problemListToolbarItems
                    } else {
                        // 回答編集用ツールバー
                        answerEditToolbarItems
                    }
                }
                
                // 保存ボタン（編集モードでない場合のみ表示）
                ToolbarItem(placement: .primaryAction) {
                    if !viewModel.isEditMode {
                        Button("保存") {
                            viewModel.saveChanges {
                                dismiss()
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showNewQuestionSheet) {
                CustomQuestionCreatorView(
                    memo: memo,
                    viewContext: viewContext,
                    onSave: {
                        if let memo = memo {
                            viewModel.loadComparisonQuestions(for: memo)
                        }
                        showNewQuestionSheet = false
                    },
                    onCancel: { showNewQuestionSheet = false }
                )
            }
            .sheet(isPresented: $showAnswerImport, onDismiss: {
                print("📣 インポートシート閉じた時の通知を送信")
                NotificationCenter.default.post(name: NSNotification.Name("AnswersImported"), object: nil)
                
                // 明示的に回答更新通知も送信
                NotificationCenter.default.post(name: NSNotification.Name("AnswersUpdated"), object: nil)
                
                // 遅延して再度通知を送信（より確実にするため）
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NotificationCenter.default.post(name: NSNotification.Name("AnswersImported"), object: nil)
                    NotificationCenter.default.post(name: NSNotification.Name("AnswersUpdated"), object: nil)
                }
            }) {
                AnswerImportView(
                    allQuestions: Binding<[QuestionItem]>(
                        get: { viewModel.generateQuestionItems() },
                        set: { _ in }
                    ),
                    onComplete: { answers in
                        viewModel.applyImportedAnswers(answers)
                        
                        // インポート完了時に即座に通知を送信
                        DispatchQueue.main.async {
                            print("📣 onComplete内での通知を送信")
                            NotificationCenter.default.post(name: NSNotification.Name("AnswersImported"), object: nil)
                        }
                    }
                )
            }
            .sheet(isPresented: $showKeywordEditSheet) {
                if let (keyword, index) = editingKeywordInfo {
                    KeywordEditView(
                        keyword: keyword,
                        index: index,
                        onSave: { newKeyword in
                            updateKeyword(at: index, from: keyword, to: newKeyword)
                        }
                    )
                }
            }
            .sheet(isPresented: $showQuestionEditSheet) {
                if let question = editingQuestion {
                    QuestionEditView(
                        question: question,
                        onSave: { newQuestion, newNote in
                            updateQuestion(question, newText: newQuestion, newNote: newNote)
                        }
                    )
                }
            }
            .onChange(of: viewModel.error) { newValue in
                if newValue != nil {
                    showAlert = true
                }
            }
            .alert("エラー", isPresented: $showAlert) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                if let errorMessage = viewModel.error {
                    Text(errorMessage)
                } else {
                    Text("不明なエラーが発生しました")
                }
            }
        }
        // 使い方モーダルオーバーレイを追加
        .overlay(
            Group {
                if showUsageModal {
                    QuestionEditorUsageModalView(isPresented: $showUsageModal)
                        .transition(.opacity)
                        .animation(.easeInOut, value: showUsageModal)
                }
            }
        )
    }
    
    // 問題リスト編集タブのコンテンツ
    private var problemListTab: some View {
        List {
            // キーワードセクション
            keywordSection
            
            // 比較問題セクション
//            comparisonQuestionSection
        }
    }
    
    // キーワードセクション
    private var keywordSection: some View {
        Section(header: Text("重要単語")) {
            ForEach(viewModel.editingKeywords.indices, id: \.self) { index in
                let keyword = viewModel.editingKeywords[index]
                HStack {
                    if viewModel.isEditMode {
                        Image(systemName: viewModel.selectedKeywords.contains(keyword) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(.blue)
                            .onTapGesture {
                                viewModel.toggleKeywordSelection(keyword)
                            }
                    }
                    
                    Text(keyword)
                    
                    Spacer()
                    
                    // 編集モードでない場合に編集ボタンを表示
                    if !viewModel.isEditMode {
                        Button(action: {
                            editingKeywordInfo = (keyword, index)
                            showKeywordEditSheet = true
                        }) {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if viewModel.isEditMode {
                        viewModel.toggleKeywordSelection(keyword)
                    }
                }
            }
            .onDelete(perform: viewModel.isEditMode ? nil : viewModel.deleteKeyword)
            
            if !viewModel.isEditMode {
                HStack {
                    TextField("新しいキーワード", text: $viewModel.newKeyword)
                        .ignoresSafeArea(.keyboard, edges: .bottom)
                    Button(action: viewModel.addKeyword) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                    .disabled(viewModel.newKeyword.isEmpty)
                }
            }
        }
    }
    
    // 比較問題セクション
//    private var comparisonQuestionSection: some View {
//        Section(header: Text("比較・カスタム問題")) {
//            ForEach(viewModel.comparisonQuestions.wrappedValue) { question in
//                HStack {
//                    if viewModel.isEditMode {
//                        Image(systemName: viewModel.selectedQuestions.contains(question.id?.uuidString ?? "") ? "checkmark.circle.fill" : "circle")
//                            .foregroundColor(.blue)
//                            .onTapGesture {
//                                viewModel.toggleQuestionSelection(question)
//                            }
//                    }
//                    
//                    VStack(alignment: .leading) {
//                        Text(question.question ?? "")
//                            .font(.subheadline)
//                            .lineLimit(2)
//                        
//                        if let note = question.note, !note.isEmpty {
//                            Text(note)
//                                .font(.caption)
//                                .foregroundColor(.gray)
//                        }
//                    }
//                    
//                    Spacer()
//                    
//                    // 編集モードでない場合に編集ボタンを表示
//                    if !viewModel.isEditMode {
//                        Button(action: {
//                            editingQuestion = question
//                            showQuestionEditSheet = true
//                        }) {
//                            Image(systemName: "pencil")
//                                .foregroundColor(.blue)
//                        }
//                        .buttonStyle(BorderlessButtonStyle())
//                    }
//                }
//                .contentShape(Rectangle())
//                .onTapGesture {
//                    if viewModel.isEditMode {
//                        viewModel.toggleQuestionSelection(question)
//                    }
//                }
//            }
//            .onDelete(perform: viewModel.isEditMode ? nil : viewModel.deleteComparisonQuestion)
//        }
//    }
    
    // 回答編集タブのコンテンツ
    private var answerEditTab: some View {
        List {
            // キーワード問題の回答セクション
            Section(header: Text("キーワード問題の回答")) {
                ForEach(viewModel.editingKeywords.indices, id: \.self) { index in
                    let keyword = viewModel.editingKeywords[index]
                    let answerKey = "keyword_answer_\(keyword)"
                    let answer = UserDefaults.standard.string(forKey: answerKey) ?? ""
                    
                    NavigationLink {
                        AnswerEditDetailView(
                            questionText: "「\(keyword)」について説明してください。",
                            answer: answer,
                            onSave: { newAnswer in
                                QuestionService.shared.saveKeywordAnswer(
                                    keyword: keyword,
                                    answer: newAnswer.isEmpty ? nil : newAnswer
                                )
                            }
                        )
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(keyword)
                                .font(.headline)
                            
                            if !answer.isEmpty {
                                Text(answer.prefix(50) + (answer.count > 50 ? "..." : ""))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                            } else {
                                Text("未回答")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .italic()
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            // 比較問題の回答セクション
            if !comparisonQuestions.isEmpty {
                Section(header: Text("比較問題の回答")) {
                    ForEach(comparisonQuestions) { question in
                        NavigationLink {
                            AnswerEditDetailView(
                                questionText: question.question ?? "",
                                answer: question.answer ?? "",
                                onSave: { newAnswer in
                                    QuestionService.shared.saveComparisonQuestionAnswer(
                                        question: question,
                                        answer: newAnswer.isEmpty ? nil : newAnswer,
                                        viewContext: viewContext
                                    )
                                }
                            )
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(question.question?.prefix(50) ?? "" + (question.question?.count ?? 0 > 50 ? "..." : ""))
                                    .font(.headline)
                                
                                if let answer = question.answer, !answer.isEmpty {
                                    Text(answer.prefix(50) + (answer.count > 50 ? "..." : ""))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .lineLimit(2)
                                } else {
                                    Text("未回答")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .italic()
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
    }
    
    // 問題リストタブのツールバーアイテム
    private var problemListToolbarItems: some View {
        Group {
            if viewModel.isEditMode {
                Button("削除") {
                    viewModel.deleteSelectedItems()
                }
                .foregroundColor(.red)
                .disabled(viewModel.selectedKeywords.isEmpty && viewModel.selectedQuestions.isEmpty)
            } else {
                Menu {
                    Button(action: {
                        viewModel.copyQuestionsToClipboard()
                    }) {
                        Label("問題をコピー", systemImage: "doc.on.doc")
                    }
                    
                    Button(action: {
                        showAnswerImport = true
                    }) {
                        Label("回答をインポート", systemImage: "square.and.arrow.down")
                    }
                    
                    Button(action: {
                        viewModel.isEditMode = true
                    }) {
                        Label("編集", systemImage: "pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.headline)
                }
            }
        }
    }
    
    // 回答編集タブのツールバーアイテム
    private var answerEditToolbarItems: some View {
        Button(action: {
            showAnswerImport = true
        }) {
            Label("回答をインポート", systemImage: "square.and.arrow.down")
                .labelStyle(.titleAndIcon)
        }
    }
    
    // キーワードの更新処理
    private func updateKeyword(at index: Int, from oldKeyword: String, to newKeyword: String) {
        guard index < viewModel.editingKeywords.count else { return }
        
        // キーワードを更新
        viewModel.editingKeywords[index] = newKeyword
        
        // 選択セットも更新
        if viewModel.selectedKeywords.contains(oldKeyword) {
            viewModel.selectedKeywords.remove(oldKeyword)
            viewModel.selectedKeywords.insert(newKeyword)
        }
        
        // UserDefaultsの回答も移行
        let oldAnswerKey = "keyword_answer_\(oldKeyword)"
        let newAnswerKey = "keyword_answer_\(newKeyword)"
        
        if let oldAnswer = UserDefaults.standard.string(forKey: oldAnswerKey) {
            UserDefaults.standard.set(oldAnswer, forKey: newAnswerKey)
            print("✅ キーワード回答を移行: \(oldKeyword) → \(newKeyword)")
        }
    }
    
    // 比較問題の更新処理
    private func updateQuestion(_ question: ComparisonQuestion, newText: String, newNote: String?) {
        question.question = newText
        question.note = newNote
        
        do {
            try viewContext.save()
            print("✅ 比較問題を更新しました")
            // 必要に応じてviewModelの状態を更新
            if let memo = memo {
                viewModel.loadComparisonQuestions(for: memo)
            }
        } catch {
            viewModel.error = "比較問題の更新に失敗しました: \(error.localizedDescription)"
            print("❌ 比較問題更新エラー: \(error.localizedDescription)")
        }
    }
}

// キーワード編集ビュー
struct KeywordEditView: View {
    @Environment(\.dismiss) private var dismiss
    let keyword: String
    let index: Int
    let onSave: (String) -> Void
    
    @State private var editedKeyword: String
    @State private var showConfirmation = false
    
    init(keyword: String, index: Int, onSave: @escaping (String) -> Void) {
        self.keyword = keyword
        self.index = index
        self.onSave = onSave
        self._editedKeyword = State(initialValue: keyword)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("キーワード編集")) {
                    TextField("キーワード", text: $editedKeyword)
                        .padding()
                }
                
                Button(action: saveKeyword) {
                    Text("保存")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.top, 10)
                .disabled(editedKeyword.isEmpty)
            }
            .navigationTitle("キーワードの編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .alert("確認", isPresented: $showConfirmation) {
                Button("はい", role: .destructive) {
                    onSave(editedKeyword)
                    dismiss()
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("キーワードを変更すると、関連する回答の関連付けが変わる可能性があります。続行しますか？")
            }
        }
    }
    
    private func saveKeyword() {
        // キーワードが変更された場合のみ確認ダイアログを表示
        if editedKeyword != keyword {
            showConfirmation = true
        } else {
            dismiss()
        }
    }
}

// 問題編集ビュー
struct QuestionEditView: View {
    @Environment(\.dismiss) private var dismiss
    let question: ComparisonQuestion
    let onSave: (String, String?) -> Void
    
    @State private var questionText: String
    @State private var questionNote: String
    
    init(question: ComparisonQuestion, onSave: @escaping (String, String?) -> Void) {
        self.question = question
        self.onSave = onSave
        self._questionText = State(initialValue: question.question ?? "")
        self._questionNote = State(initialValue: question.note ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("問題内容")) {
                    TextEditor(text: $questionText)
                        .frame(minHeight: 120)
                        .padding(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
                
                Section(header: Text("補足情報")) {
                    TextEditor(text: $questionNote)
                        .frame(height: 100)
                        .padding(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
                
                Button(action: saveQuestion) {
                    Text("保存")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.top, 10)
                .disabled(questionText.isEmpty)
            }
            .navigationTitle("問題の編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveQuestion() {
        onSave(questionText, questionNote.isEmpty ? nil : questionNote)
        dismiss()
    }
}

// 回答編集詳細ビュー
struct AnswerEditDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let questionText: String
    @State private var answerText: String
    let onSave: (String) -> Void
    
    init(questionText: String, answer: String, onSave: @escaping (String) -> Void) {
        self.questionText = questionText
        self._answerText = State(initialValue: answer)
        self.onSave = onSave
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 問題文表示エリア
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(questionText)
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding()
            }
            .frame(height: 120)
            
            Divider()
            
            // 回答編集エリア
            VStack(alignment: .leading) {
                HStack {
                    Text("回答")
                        .font(.headline)
                    Spacer()
                    Button("クリア") {
                        answerText = ""
                    }
                    .foregroundColor(.red)
                }
                .padding(.horizontal)
                .padding(.top)
                
                TextEditor(text: $answerText)
                    .font(.body)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding()
            }
            
            Spacer()
            
            // 保存ボタン
            Button(action: {
                onSave(answerText)
                dismiss()
            }) {
                Text("保存")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
            }
        }
        .navigationTitle("回答編集")
        .navigationBarTitleDisplayMode(.inline)
    }
}
