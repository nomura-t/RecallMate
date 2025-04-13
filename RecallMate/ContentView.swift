// ContentView.swift - 修正版
import SwiftUI
import CoreData
import PencilKit
import UIKit

class ViewSettings: ObservableObject {
    @Published var keyboardAvoiding = true
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
            VStack {
                // カスタムヘッダー
                HStack {
                    Button(action: {
                        if memo == nil {
                            viewModel.cleanupOrphanedQuestions()
                        }
                        dismiss()
                    }) {
                        Label("ホームに戻る", systemImage: "arrow.left")
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
                
                // ここでScrollViewReaderを配置して全体を包む
                ScrollViewReader { proxy in
                    Form {
                        // メモの詳細セクション
                        Section(header: Text("メモ詳細")) {
                            // タイトルとページ範囲
                            TextField("タイトル", text: $viewModel.title)
                                .font(.headline)
                                .focused($titleFieldFocused)
                                .id(titleField)
                                .background(viewModel.shouldFocusTitle ? Color.red.opacity(0.1) : Color.clear)
                                .onChange(of: viewModel.title) { _, newValue in
                                    if !newValue.isEmpty && viewModel.shouldFocusTitle {
                                        viewModel.shouldFocusTitle = false
                                    }
                                    if viewModel.showTitleInputGuide {
                                        viewModel.showTitleInputGuide = false
                                    }
                                    viewModel.contentChanged = true
                                }
                                .onChange(of: titleFieldFocused) { _, newValue in
                                    viewModel.onTitleFocusChanged(isFocused: newValue)
                                }
                            
                            TextField("ページ範囲", text: $viewModel.pageRange)
                                .font(.subheadline)
                                .padding(.bottom, 4)
                                .onChange(of: viewModel.pageRange) { _, _ in
                                    viewModel.contentChanged = true
                                    viewModel.recordActivityOnSave = true
                                }
                            
                            // 問題カードを配置
                            QuestionCarouselView(
                                keywords: viewModel.keywords,
                                comparisonQuestions: viewModel.comparisonQuestions,
                                memo: memo,
                                viewContext: viewContext,
                                showQuestionEditor: $showQuestionEditor
                            )
                            .padding(.vertical, 8)
                            
                            // 内容フィールド
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("内容")
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    // リセットボタン
                                    Button(action: {
                                        showContentResetAlert = true
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                            .font(.system(size: 16))
                                            .frame(width: 44, height: 44)
                                            .background(Color.clear)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    // iPad向け手書き入力ボタン
                                    if UIDevice.current.userInterfaceIdiom == .pad {
                                        Button(action: {
                                            isDrawing = true
                                        }) {
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
                                                    isDrawing = true
                                                }
                                        )
                                    }
                                }
                                
                                // TextEditor
                                ZStack(alignment: .topLeading) {
                                    TextEditor(text: $viewModel.content)
                                        .font(.system(size: CGFloat(appSettings.memoFontSize)))
                                        .frame(minHeight: 120)
                                        .padding(4)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                        .id(contentField)
                                        .focused($contentFieldFocused)
                                        .onChange(of: viewModel.content) { _, _ in
                                            viewModel.contentChanged = true
                                            viewModel.recordActivityOnSave = true
                                        }
                                        .onChange(of: contentFieldFocused) { _, newValue in
                                            viewModel.onContentFocusChanged(isFocused: newValue)
                                        }
                                    
                                    // プレースホルダー
                                    if viewModel.content.isEmpty {
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
                            }
                            .padding(.top, 4)
                        }
                        .onChange(of: viewModel.shouldFocusTitle) { _, shouldFocus in
                            if shouldFocus {
                                titleFieldFocused = true
                            }
                        }
                        
                        // タグセクション（改善版）
                        Section(header: Text("タグ")) {
                            VStack(alignment: .leading, spacing: 10) {
                                // 選択されたタグを表示
                                if viewModel.selectedTags.isEmpty {
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
                                                ForEach(viewModel.selectedTags) { tag in
                                                    TagChip(
                                                        tag: tag,
                                                        isSelected: true,
                                                        showDeleteButton: true,
                                                        onDelete: {
                                                            if let index = viewModel.selectedTags.firstIndex(where: { $0.id == tag.id }) {
                                                                viewModel.selectedTags.remove(at: index)
                                                                viewModel.contentChanged = true
                                                                viewModel.recordActivityOnSave = true
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
                                                // 選択/解除のトグル
                                                if viewModel.selectedTags.contains(where: { $0.id == tag.id }) {
                                                    // 解除
                                                    if let index = viewModel.selectedTags.firstIndex(where: { $0.id == tag.id }) {
                                                        viewModel.selectedTags.remove(at: index)
                                                    }
                                                } else {
                                                    // 選択
                                                    viewModel.selectedTags.append(tag)
                                                }
                                                
                                                // 変更フラグをセット
                                                viewModel.contentChanged = true
                                                viewModel.recordActivityOnSave = true
                                                
                                                // タグ変更時に即時保存（追加）
                                                if memo != nil {
                                                    DispatchQueue.main.async {
                                                        viewModel.updateAndSaveTags()
                                                    }
                                                }
                                            }) {
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
                                                    viewModel.selectedTags.contains(where: { $0.id == tag.id })
                                                    ? tag.swiftUIColor().opacity(0.2)
                                                    : Color.gray.opacity(0.15)
                                                )
                                                .foregroundColor(
                                                    viewModel.selectedTags.contains(where: { $0.id == tag.id })
                                                    ? tag.swiftUIColor()
                                                    : .primary
                                                )
                                                .cornerRadius(16)
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
                                        .highPriorityGesture(
                                            TapGesture()
                                                .onEnded { _ in
                                                    showTagSelection = true
                                                }
                                        )
                                    }
                                    .padding(.bottom, 4)
                                }
                                .simultaneousGesture(DragGesture().onChanged { _ in }, including: .all)
                                .allowsHitTesting(true) // 明示的にヒットテストを許可
                                .frame(height: 40)
                            }
                            .padding(.vertical, 4)
                            .onChange(of: viewModel.selectedTags) { oldValue, newValue in
                                if memo != nil {
                                    viewModel.updateAndSaveTags()
                                }
                            }
                            .onAppear {
                                // 画面表示時にタグデータを明示的にリフレッシュ
                                if memo != nil {
                                    viewModel.refreshTags()
                                }
                            }
                        }
                        
                        // 記憶度セクション（統合版）
                        CombinedRecallSection(viewModel: viewModel)
                            .onChange(of: viewModel.recallScore) { _, _ in
                                viewModel.contentChanged = true
                                viewModel.recordActivityOnSave = true
                            }
                        
                        // 保存ボタン
                        Button(action: {
                            viewModel.saveMemoWithTracking {
                                dismiss()
                            }
                        }) {
                            Text("記憶した！")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 40)
                                .background(Color.blue)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                    }
                    .listStyle(InsetGroupedListStyle())
                    .onTapGesture {
                        // キーボードを閉じる
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
                .navigationBarHidden(true)
                .onAppear {
                    // 学習セッションの開始
                    if let memo = memo {
                        // 既存メモの場合、時間計測を開始
                        viewModel.startLearningSession()
                    }
                    
                    // 初回メモ作成時はタイトルフィールドにフォーカス
                    if viewModel.showTitleInputGuide {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            titleFieldFocused = true
                        }
                    }
                }
                .onDisappear {
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
                .sheet(isPresented: $showTagSelection, onDismiss: {
                    if memo != nil {
                        viewModel.updateAndSaveTags()
                        viewModel.contentChanged = true
                    }
                }) {
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
                .sheet(isPresented: $showQuestionEditor, onDismiss: {
                    if let memo = memo {
                        viewModel.loadComparisonQuestions(for: memo)
                        viewModel.contentChanged = true
                        viewModel.recordActivityOnSave = true
                    }
                }) {
                    QuestionEditorView(
                        memo: memo,
                        keywords: $viewModel.keywords,
                        comparisonQuestions: $viewModel.comparisonQuestions
                    )
                }
                .environmentObject(ViewSettings())
                .overlay(
                    Group {
                        if showUsageModal {
                            UsageModalView(isPresented: $showUsageModal)
                                .transition(.opacity)
                                .animation(.easeInOut, value: showUsageModal)
                        }
                        
                        // タイトル入力ガイド
                        if viewModel.showTitleInputGuide {
                            TitleInputGuideView(
                                isPresented: $viewModel.showTitleInputGuide,
                                onDismiss: {
                                    viewModel.dismissTitleInputGuide()
                                    // タイトルフィールドにフォーカス
                                    titleFieldFocused = true
                                }
                            )
                            .transition(.opacity)
                            .animation(.easeInOut, value: viewModel.showTitleInputGuide)
                        }
                        // 問題カードガイド
                        if viewModel.showQuestionCardGuide {
                            QuestionCardGuideView(
                                isPresented: $viewModel.showQuestionCardGuide,
                                onDismiss: {
                                    viewModel.dismissQuestionCardGuide()
                                }
                            )
                            .transition(.opacity)
                            .animation(.easeInOut, value: viewModel.showQuestionCardGuide)
                        }
                        // メモ内容ガイド
                        if viewModel.showMemoContentGuide {
                            MemoContentGuideView(
                                isPresented: $viewModel.showMemoContentGuide,
                                onDismiss: {
                                    viewModel.dismissMemoContentGuide()
                                }
                            )
                            .transition(.opacity)
                            .animation(.easeInOut, value: viewModel.showMemoContentGuide)
                            .onAppear {
                                // メモ内容ガイドが表示されたら少し遅延してスクロール
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    triggerScroll = true
                                }
                            }
                        }
                        // タグガイド
                        if viewModel.showTagGuide {
                            TagGuideView(
                                isPresented: $viewModel.showTagGuide,
                                onDismiss: {
                                    viewModel.dismissTagGuide()
                                }
                            )
                            .transition(.opacity)
                            .animation(.easeInOut, value: viewModel.showTagGuide)
                        }
                    }
                )
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
            }
        }
    }
}
