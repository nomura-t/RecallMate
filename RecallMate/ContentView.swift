// ContentView.swift - タブ構造再設計版
import SwiftUI
import CoreData
import PencilKit
import UIKit

class ViewSettings: ObservableObject {
    @Published var keyboardAvoiding = true
}

// メモコンテンツのプレースホルダービュー
struct MemoPlaceholderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 30, height: 30)
                    Text("1")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("覚えたいことを教科書を見ないで書き出す")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("まずは自分の力で思い出してみましょう。わからなくても大丈夫！")
                        .font(.subheadline)
                        .foregroundColor(.gray.opacity(0.8))
                }
            }
            
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 30, height: 30)
                    Text("2")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("わからない点は教科書で確認する")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("思い出せなかった部分を確認して、知識を補いましょう。")
                        .font(.subheadline)
                        .foregroundColor(.gray.opacity(0.8))
                }
            }
            
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 30, height: 30)
                    Text("3")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("①と②を繰り返す")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("再度挑戦して、どれだけ覚えているか試してみましょう。")
                        .font(.subheadline)
                        .foregroundColor(.gray.opacity(0.8))
                }
            }
        }
        .padding(16)
        .allowsHitTesting(false)
    }
}

// タグセレクション部分のサブビュー
struct TagSelectionSectionView: View {
    @Binding var selectedTags: [Tag]
    @Binding var contentChanged: Bool
    @Binding var recordActivityOnSave: Bool
    var memo: Memo?
    var allTags: FetchedResults<Tag>
    var viewContext: NSManagedObjectContext
    var updateAndSaveTags: () -> Void
    var refreshTags: () -> Void
    @Binding var showTagSelection: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 選択されたタグを表示
            if selectedTags.isEmpty {
                Text("タグなし")
                    .foregroundColor(.gray)
                    .italic()
                    .padding(.bottom, 4)
            } else {
                HStack {
                    Text("選択中:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(selectedTags) { tag in
                                TagChip(
                                    tag: tag,
                                    isSelected: true,
                                    showDeleteButton: true,
                                    onDelete: {
                                        if let index = selectedTags.firstIndex(where: { $0.id == tag.id }) {
                                            selectedTags.remove(at: index)
                                            contentChanged = true
                                            recordActivityOnSave = true
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .simultaneousGesture(DragGesture().onChanged { _ in }, including: .subviews)
                }
                .padding(.bottom, 4)
            }
            
            // 利用可能なすべてのタグを表示（選択中のタグは強調表示）
            Text("タグを選択")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.bottom, 2)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(allTags) { tag in
                        Button(action: {
                            handleTagSelection(tag)
                        }) {
                            tagButton(for: tag)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    
                    // 新規タグ作成ボタン
                    Button(action: {
                        showTagSelection = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.caption)
                            
                            Text("新規タグ")
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.15))
                        .foregroundColor(.blue)
                        .cornerRadius(16)
                        .frame(height: 44) // タップ領域を垂直方向に拡大
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .contentShape(Rectangle()) // タップ領域を明示的に矩形に設定
                }
                .padding(.bottom, 4)
            }
            .simultaneousGesture(DragGesture().onChanged { _ in }, including: .all)
            .allowsHitTesting(true)
            .frame(height: 40)
        }
        .padding(.vertical, 4)
        .onChange(of: selectedTags) { oldValue, newValue in
            if memo != nil {
                updateAndSaveTags()
            }
        }
        .onAppear {
            // 画面表示時にタグデータを明示的にリフレッシュ
            if memo != nil {
                refreshTags()
            }
        }
    }
    
    private func handleTagSelection(_ tag: Tag) {
        // 選択/解除のトグル
        if selectedTags.contains(where: { $0.id == tag.id }) {
            // 解除
            if let index = selectedTags.firstIndex(where: { $0.id == tag.id }) {
                selectedTags.remove(at: index)
            }
        } else {
            // 選択
            selectedTags.append(tag)
        }
        
        // 変更フラグをセット
        contentChanged = true
        recordActivityOnSave = true
        
        // タグ変更時に即時保存（追加）
        if memo != nil {
            DispatchQueue.main.async {
                updateAndSaveTags()
            }
        }
    }
    
    private func tagButton(for tag: Tag) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(tag.swiftUIColor())
                .frame(width: 8, height: 8)
            
            Text(tag.name ?? "")
                .font(.subheadline)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            selectedTags.contains(where: { $0.id == tag.id })
            ? tag.swiftUIColor().opacity(0.2)
            : Color.gray.opacity(0.15)
        )
        .foregroundColor(
            selectedTags.contains(where: { $0.id == tag.id })
            ? tag.swiftUIColor()
            : .primary
        )
        .cornerRadius(16)
    }
}

// メモコンテンツセクションのサブビュー
struct MemoContentSectionView: View {
    @Binding var content: String
    @Binding var contentChanged: Bool
    @Binding var recordActivityOnSave: Bool
    @FocusState var contentFieldFocused: Bool
    let contentFieldID: Namespace.ID
    let appSettingsFontSize: Double
    var onResetAction: () -> Void
    var isIpad: Bool
    var onDrawAction: () -> Void
    var onContentFocusChanged: (Bool) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("内容")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // リセットボタン
                Button(action: onResetAction) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.system(size: 16))
                        .frame(width: 44, height: 44)
                        .background(Color.clear)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                // iPad向け手書き入力ボタン
                if isIpad {
                    Button(action: onDrawAction) {
                        Image(systemName: "pencil.tip")
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(Circle().fill(Color.clear))
                            .contentShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(width: 44, height: 44)
                    .highPriorityGesture(
                        TapGesture()
                            .onEnded { _ in
                                onDrawAction()
                            }
                    )
                }
            }
            
            // TextEditor
            ZStack(alignment: .topLeading) {
                TextEditor(text: $content)
                    .font(.system(size: CGFloat(appSettingsFontSize)))
                    .frame(minHeight: 200) // 高さを大きくして表示領域を拡大
                    .padding(4)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .id(contentFieldID)
                    .focused($contentFieldFocused)
                    .onChange(of: content) { _, _ in
                        contentChanged = true
                        recordActivityOnSave = true
                    }
                    .onChange(of: contentFieldFocused) { _, newValue in
                        onContentFocusChanged(newValue)
                    }
                
                // プレースホルダー
                if content.isEmpty {
                    MemoPlaceholderView()
                }
            }
        }
        .padding(.top, 4)
    }
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appSettings: AppSettings
    
    var memo: Memo?
    
    @StateObject private var viewModel: ContentViewModel
    @State private var showCustomQuestionCreator = false
    @State private var showQuestionEditor = false
    @State private var isDrawing = false
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    @State private var showTagSelection = false
    @State private var sessionId: UUID? = nil
    
    // タブ選択用の状態変数を追加
    @State private var selectedTab = 0
    
    // UIKitスクロール用のトリガー
    @State private var triggerScroll = false
    
    // フォーカス状態
    @FocusState private var titleFieldFocused: Bool
    @FocusState private var contentFieldFocused: Bool
    
    // 「使い方」ボタンと状態変数を追加
    @State private var showUsageModal = false
    
    // リセット確認アラート用
    @State private var showContentResetAlert = false
    
    // コンテンツフィールド用のID
    @Namespace var contentField
    @Namespace var titleField
    @Namespace var recallSliderSection

    @State private var showUnsavedChangesAlert = false

    // すべてのタグを取得
    @FetchRequest(
        entity: Tag.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)],
        animation: .default)
    private var allTags: FetchedResults<Tag>
    
    init(memo: Memo? = nil) {
        self.memo = memo
        self._viewModel = StateObject(wrappedValue: ContentViewModel(viewContext: PersistenceController.shared.container.viewContext, memo: memo))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // カスタムヘッダー
                HStack {
                    Button(action: handleBackButton) {
                        Label("戻る", systemImage: "arrow.left")
                            .font(.headline)
                            .padding()
                            .foregroundColor(.blue)
                    }
                    Spacer()
                    
                    // 使い方ボタンを追加
                    Button(action: {
                        showUsageModal = true
                    }) {
                        Label("使い方", systemImage: "info.circle")
                            .font(.headline)
                            .padding()
                            .foregroundColor(.blue)
                    }
                }
                
                // UIKitスクロールコントローラー（非表示）
                ScrollControllerView(shouldScroll: $triggerScroll)
                    .frame(width: 0, height: 0)
                
                // スクロールコントローラー
                ScrollToBottomController(triggerScroll: viewModel.triggerBottomScroll)
                    .frame(width: 0, height: 0) // 非表示にする
                
                // タブビューを追加 - ページスタイルに変更
                TabView(selection: $selectedTab) {
                    // 記録するタブ
                    recordTab
                        .tabItem {
                            Label("記録する", systemImage: "square.and.pencil")
                        }
                        .tag(0)
                    
                    // 学習するタブ
                    learnTab
                        .tabItem {
                            Label("学習する", systemImage: "book")
                        }
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic)) // ページスタイルに変更
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            }
            .navigationBarHidden(true)
            .onAppear(perform: handleOnAppear)
            .onDisappear(perform: handleOnDisappear)
            // iPad 手書きモード
            .fullScreenCover(isPresented: $isDrawing) {
                FullScreenCanvasView(isDrawing: $isDrawing, canvas: $canvasView, toolPicker: $toolPicker)
                    .onDisappear {
                        // 手書き入力後は内容が変更されたとみなす
                        viewModel.contentChanged = true
                        viewModel.recordActivityOnSave = true
                    }
            }
            // タグ選択画面
            .sheet(isPresented: $showTagSelection, onDismiss: handleTagSelectionDismiss) {
                NavigationView {
                    TagSelectionView(
                        selectedTags: $viewModel.selectedTags,
                        onTagsChanged: memo != nil ? {
                            viewModel.contentChanged = true
                            viewModel.recordActivityOnSave = true
                        } : nil
                    )
                    .environment(\.managedObjectContext, viewContext)
                    .navigationTitle("")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("完了") { showTagSelection = false }
                        }
                    }
                }
            }
            // 問題エディタへのシート遷移
            .sheet(isPresented: $showQuestionEditor, onDismiss: handleQuestionEditorDismiss) {
                QuestionEditorView(
                    memo: memo,
                    keywords: $viewModel.keywords,
                    comparisonQuestions: $viewModel.comparisonQuestions
                )
            }
            .environmentObject(ViewSettings())
            // アラート群
            .alert("タイトルが必要です", isPresented: $viewModel.showTitleAlert) {
                Button("OK") { viewModel.showTitleAlert = false }
            } message: {
                Text("続行するにはメモのタイトルを入力してください。")
            }
            .alert("内容をリセット", isPresented: $showContentResetAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("リセット", role: .destructive) {
                    // ここでテキストをクリア - メインスレッドで明示的に実行
                    DispatchQueue.main.async {
                        viewModel.content = ""
                        viewModel.contentChanged = true
                    }
                }
            } message: {
                Text("メモの内容をクリアしますか？この操作は元に戻せません。")
            }
            .alert("変更が保存されていません", isPresented: $showUnsavedChangesAlert) {
                Button("キャンセル", role: .cancel) {
                    // 何もせずダイアログを閉じる
                }
                Button("保存", role: .none) {
                    // 保存して戻る
                    viewModel.saveMemoWithTracking {
                        dismiss()
                    }
                }
                Button("保存せずに戻る", role: .destructive) {
                    // 保存せずに戻る
                    if memo == nil {
                        viewModel.cleanupOrphanedQuestions()
                    }
                    dismiss()
                }
            } message: {
                Text("メモの変更内容を保存しますか？")
            }
        }
    }
    
    // MARK: - タブビュー
    
    // 記録するタブ - タイトル、ページ範囲、タブ追加、記憶定着度バー、メモ完了ボタン
    private var recordTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // タイトルとページ範囲
                VStack(alignment: .leading, spacing: 12) {
                    Text("メモ詳細")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        // タイトル入力
                        VStack(alignment: .leading, spacing: 4) {
                            Text("タイトル")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("タイトル", text: $viewModel.title)
                                .font(.headline)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .focused($titleFieldFocused)
                                .id(titleField)
                                .background(viewModel.shouldFocusTitle ? Color.red.opacity(0.1) : Color.clear)
                                .onChange(of: viewModel.title) { _, _ in
                                    viewModel.contentChanged = true
                                }
                                .onChange(of: titleFieldFocused) { _, newValue in
                                    viewModel.onTitleFocusChanged(isFocused: newValue)
                                }
                        }
                        .padding(.horizontal)
                        
                        // ページ範囲入力
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ページ範囲")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("ページ範囲", text: $viewModel.pageRange)
                                .font(.subheadline)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .onChange(of: viewModel.pageRange) { _, _ in
                                    viewModel.contentChanged = true
                                    viewModel.recordActivityOnSave = true
                                }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
                
                // タグセクション
                VStack(alignment: .leading, spacing: 12) {
                    Text("タグ")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    VStack {
                        TagSelectionSectionView(
                            selectedTags: $viewModel.selectedTags,
                            contentChanged: $viewModel.contentChanged,
                            recordActivityOnSave: $viewModel.recordActivityOnSave,
                            memo: memo,
                            allTags: allTags,
                            viewContext: viewContext,
                            updateAndSaveTags: viewModel.updateAndSaveTags,
                            refreshTags: viewModel.refreshTags,
                            showTagSelection: $showTagSelection
                        )
                        .padding()
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
                
                // 記憶定着度セクション
                VStack(alignment: .leading, spacing: 12) {
                    Text("記憶定着度振り返り")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    VStack {
                        CombinedRecallSection(viewModel: viewModel)
                            .id("recallSliderSection")
                            .onChange(of: viewModel.recallScore) { _, _ in
                                viewModel.contentChanged = true
                                viewModel.recordActivityOnSave = true
                            }
                            .padding()
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
                
                // メモ完了ボタン
                Button {
                    viewModel.saveMemoWithTracking {
                        dismiss()
                    }
                } label: {
                    Text("メモ完了！")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .background(Color.blue)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .id("bottomAnchor")
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .onTapGesture {
            // キーボードを閉じる
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    // 学習するタブ - メモの内容と問題カード
    private var learnTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // メモ内容セクション
                VStack(alignment: .leading, spacing: 12) {
                    Text("メモ内容")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    VStack {
                        MemoContentSectionView(
                            content: $viewModel.content,
                            contentChanged: $viewModel.contentChanged,
                            recordActivityOnSave: $viewModel.recordActivityOnSave,
                            contentFieldFocused: _contentFieldFocused,
                            contentFieldID: contentField,
                            appSettingsFontSize: appSettings.memoFontSize,
                            onResetAction: { showContentResetAlert = true },
                            isIpad: UIDevice.current.userInterfaceIdiom == .pad,
                            onDrawAction: { isDrawing = true },
                            onContentFocusChanged: { newValue in
                                viewModel.onContentFocusChanged(isFocused: newValue)
                            }
                        )
                        .padding()
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
                
                // 問題カードセクション
                VStack(alignment: .leading, spacing: 12) {
                    Text("問題カード")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    VStack {
                        // 問題カードを配置
                        QuestionCarouselView(
                            keywords: viewModel.keywords,
                            comparisonQuestions: viewModel.comparisonQuestions,
                            memo: memo,
                            viewContext: viewContext,
                            showQuestionEditor: $showQuestionEditor
                        )
                        .padding(.vertical, 8)
                        
                        // 問題編集ボタン
                        Button(action: {
                            showQuestionEditor = true
                        }) {
                            Label("問題を編集", systemImage: "square.and.pencil")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding()
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .onTapGesture {
            // キーボードを閉じる
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    // MARK: - イベントハンドラメソッド
    
    private func handleBackButton() {
        // 変更があるか確認
        if viewModel.contentChanged {
            // 変更があれば確認ダイアログを表示
            showUnsavedChangesAlert = true
        } else {
            // 変更がなければそのまま戻る
            if memo == nil {
                viewModel.cleanupOrphanedQuestions()
            }
            dismiss()
        }
    }
    
    private func handleOnAppear() {
        // 学習セッションの開始
        if let memo = memo {
            // 既存メモの場合、時間計測を開始
            viewModel.startLearningSession()
        }
    }
    
    private func handleOnDisappear() {
        // キーボードを閉じる
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        // 学習セッションの終了
        if let memo = memo, let sessionId = viewModel.currentSessionId {
            // 変更された場合のみアクティビティを記録
            if viewModel.contentChanged {
                // 復習セッションであることを明示的に記録
                let noteText = "復習セッション: \(memo.title ?? "無題")"
                
                // 復習アクティビティを直接記録
                let context = PersistenceController.shared.container.viewContext
                LearningActivity.recordActivityWithHabitChallenge(
                    type: .review,
                    durationMinutes: ActivityTracker.shared.getCurrentSessionDuration(sessionId: sessionId),
                    memo: memo,
                    note: noteText,
                    in: context
                )
            }
        }
    }
    
    private func handleTagSelectionDismiss() {
        if memo != nil {
            viewModel.updateAndSaveTags()
            viewModel.contentChanged = true
        }
    }
    
    private func handleQuestionEditorDismiss() {
        if let memo = memo {
            viewModel.loadComparisonQuestions(for: memo)
            viewModel.contentChanged = true
            viewModel.recordActivityOnSave = true
        }
    }
}
