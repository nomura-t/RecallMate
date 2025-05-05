// ContentView.swift - モダンデザイン版（修正版）
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
    
    // タブ選択とアニメーション
    @State private var selectedTab = 0
    @State private var tabAnimation = false
    
    // UIKitスクロール用のトリガー
    @State private var triggerScroll = false
    
    // フォーカス状態
    @FocusState private var titleFieldFocused: Bool
    @FocusState private var contentFieldFocused: Bool
    
    // 「使い方」ボタンと状態変数
    @State private var showUsageModal = false
    
    // リセット確認アラート用
    @State private var showContentResetAlert = false
    
    // コンテンツフィールド用のID
    @Namespace var contentField
    @Namespace var titleField
    @Namespace var recallSliderSection

    @State private var showUnsavedChangesAlert = false
    
    // スクロール位置制御
    @State private var scrollToBottom = false

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
        ZStack {
            // 背景
            Color(.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // カスタムヘッダー - スタイリッシュな透明感のあるデザイン
                HStack {
                    Button(action: handleBackButton) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("戻る")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.blue)
                        .padding(12)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    
                    Spacer()
                    
                    // タブインジケーター - ピル型デザイン
                    HStack(spacing: 0) {
                        ForEach(0..<2) { index in
                            Text(index == 0 ? "記録" : "学習")
                                .font(.system(size: 14, weight: selectedTab == index ? .bold : .medium))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(
                                    Capsule()
                                        .fill(selectedTab == index ? Color.blue : Color.clear)
                                        .animation(.spring(response: 0.3), value: selectedTab)
                                )
                                .foregroundColor(selectedTab == index ? .white : .primary)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedTab = index
                                    }
                                }
                        }
                    }
                    .padding(3)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(20)
                    
                    Spacer()
                    
                    // 使い方ボタン
                    Button(action: {
                        showUsageModal = true
                    }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)
                
                // タブビュー - アニメーション付き
                TabView(selection: $selectedTab) {
                    recordTab
                        .tag(0)
                    
                    learnTab
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: selectedTab)
                .background(Color(.systemGroupedBackground))
            }
            
            // フローティングボタン - 保存ボタン
            VStack {
                Spacer()
                
                Button {
                    // ハプティックフィードバックを追加
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    // 保存アクション
                    viewModel.saveMemoWithTracking {
                        dismiss()
                    }
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                        Text("メモ完了！")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(height: 56)
                    .frame(minWidth: 180)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(28)
                    .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    .padding(.bottom, 16)
                }
                .padding(.horizontal)
                .transition(.scale)
            }
        }
        .navigationBarHidden(true)
        .onAppear(perform: handleOnAppear)
        .onDisappear(perform: handleOnDisappear)
        // モーダル画面の設定
        .fullScreenCover(isPresented: $isDrawing) {
            FullScreenCanvasView(isDrawing: $isDrawing, canvas: $canvasView, toolPicker: $toolPicker)
                .onDisappear {
                    viewModel.contentChanged = true
                    viewModel.recordActivityOnSave = true
                }
        }
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
                .navigationTitle("タグを選択")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("完了") { showTagSelection = false }
                    }
                }
            }
        }
        .sheet(isPresented: $showQuestionEditor, onDismiss: handleQuestionEditorDismiss) {
            QuestionEditorView(
                memo: memo,
                keywords: $viewModel.keywords,
                comparisonQuestions: $viewModel.comparisonQuestions
            )
        }
        .environmentObject(ViewSettings())
        // アラート設定
        .alert("タイトルが必要です", isPresented: $viewModel.showTitleAlert) {
            Button("OK") { viewModel.showTitleAlert = false }
        } message: {
            Text("続行するにはメモのタイトルを入力してください。")
        }
        .alert("内容をリセット", isPresented: $showContentResetAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("リセット", role: .destructive) {
                DispatchQueue.main.async {
                    viewModel.content = ""
                    viewModel.contentChanged = true
                }
            }
        } message: {
            Text("メモの内容をクリアしますか？この操作は元に戻せません。")
        }
        .alert("変更が保存されていません", isPresented: $showUnsavedChangesAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("保存", role: .none) {
                viewModel.saveMemoWithTracking {
                    dismiss()
                }
            }
            Button("保存せずに戻る", role: .destructive) {
                if memo == nil {
                    viewModel.cleanupOrphanedQuestions()
                }
                dismiss()
            }
        } message: {
            Text("メモの変更内容を保存しますか？")
        }
        // ここに「使い方」モーダルのオーバーレイを追加 - これが修正部分
        .overlay(
            Group {
                if showUsageModal {
                    UsageModalView(isPresented: $showUsageModal)
                        .transition(.opacity)
                        .animation(.easeInOut, value: showUsageModal)
                }
            }
        )
    }
    
    // 記録タブ - モダンなカードベースデザイン
    private var recordTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // タイトルとページ範囲 - エレガントなフォームデザイン
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 12) {
                        // タイトル入力
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("タイトル")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                if viewModel.shouldFocusTitle {
                                    Text("(必須)")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            
                            TextField("学習内容のタイトルを入力", text: $viewModel.title)
                                .font(.headline)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                .focused($titleFieldFocused)
                                .id(titleField)
                                .onChange(of: viewModel.title) { _, _ in
                                    viewModel.contentChanged = true
                                }
                                .onChange(of: titleFieldFocused) { _, newValue in
                                    viewModel.onTitleFocusChanged(isFocused: newValue)
                                }
                        }
                        
                        // ページ範囲入力
                        VStack(alignment: .leading, spacing: 6) {
                            Text("ページ範囲")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("例: p.24-38", text: $viewModel.pageRange)
                                .font(.subheadline)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                .onChange(of: viewModel.pageRange) { _, _ in
                                    viewModel.contentChanged = true
                                    viewModel.recordActivityOnSave = true
                                }
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // タグセクション - 視覚的に魅力的なデザイン
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("タグ", systemImage: "tag.fill")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            showTagSelection = true
                        }) {
                            Label("新規タグ", systemImage: "plus")
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(12)
                        }
                    }
                    
                    // タグリスト - 水平スクロール
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(allTags) { tag in
                                Button(action: {
                                    toggleTag(tag)
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
                                        : Color.white
                                    )
                                    .foregroundColor(
                                        viewModel.selectedTags.contains(where: { $0.id == tag.id })
                                        ? tag.swiftUIColor()
                                        : .primary
                                    )
                                    .cornerRadius(16)
                                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    
                    // 選択されたタグ - 修正版
                    VStack(alignment: .leading, spacing: 8) {
                        if viewModel.selectedTags.isEmpty {
                            Text("選択中: なし")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("選択中:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            // FlowLayoutではなく通常のScrollViewを使用
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(viewModel.selectedTags) { tag in
                                        HStack(spacing: 4) {
                                            Circle()
                                                .fill(tag.swiftUIColor())
                                                .frame(width: 8, height: 8)
                                            
                                            Text(tag.name ?? "")
                                                .font(.caption)
                                            
                                            Button(action: {
                                                removeTag(tag)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.gray)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(tag.swiftUIColor().opacity(0.1))
                                        .cornerRadius(10)
                                    }
                                }
                            }
                            .frame(height: 30) // 固定高さを設定
                        }
                    }
                    .padding(.top, 4) // 少し余白を追加
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                .padding(.horizontal, 16)
                
                // 記憶定着度セクション - モダンなデザイン
                VStack(alignment: .leading, spacing: 12) {
                    Label("記憶定着度振り返り", systemImage: "brain.head.profile")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    ModernRecallSection(viewModel: viewModel)
                        .id("recallSliderSection")
                        .onChange(of: viewModel.recallScore) { _, _ in
                            viewModel.contentChanged = true
                            viewModel.recordActivityOnSave = true
                        }
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                .padding(.horizontal, 16)
                .padding(.bottom, 100) // フローティングボタンのためのスペース
            }
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground))
        .onTapGesture {
            // キーボードを閉じる
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    // 学習タブ - より魅力的なレイアウト
    private var learnTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // メモ内容セクション - よりエレガントなデザイン
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("メモ内容", systemImage: "doc.text.fill")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            // リセットボタン
                            Button(action: { showContentResetAlert = true }) {
                                Image(systemName: "arrow.counterclockwise")
                                    .foregroundColor(.red)
                                    .frame(width: 32, height: 32)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(16)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // iPad向け手書き入力ボタン
                            if UIDevice.current.userInterfaceIdiom == .pad {
                                Button(action: { isDrawing = true }) {
                                    Image(systemName: "pencil.tip")
                                        .foregroundColor(.blue)
                                        .frame(width: 32, height: 32)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(16)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    // TextEditor - より魅力的なスタイル
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $viewModel.content)
                            .font(.system(size: CGFloat(appSettings.memoFontSize)))
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            .focused($contentFieldFocused)
                            .id(contentField)
                            .onChange(of: viewModel.content) { _, _ in
                                viewModel.contentChanged = true
                                viewModel.recordActivityOnSave = true
                            }
                            .onChange(of: contentFieldFocused) { _, newValue in
                                viewModel.onContentFocusChanged(isFocused: newValue)
                            }
                            .frame(minHeight: 300)
                        
                        // プレースホルダー
                        if viewModel.content.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("アクティブリコール学習法")
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                    
                                    Text("教科書を見ないで覚えている内容を書き出してみましょう")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 10) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.blue.opacity(0.2))
                                                .frame(width: 24, height: 24)
                                            Text("1")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                        }
                                        
                                        Text("まずは自分の力で思い出してみる")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    HStack(spacing: 10) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.blue.opacity(0.2))
                                                .frame(width: 24, height: 24)
                                            Text("2")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                        }
                                        
                                        Text("思い出せなかった部分は教科書で確認")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    HStack(spacing: 10) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.blue.opacity(0.2))
                                                .frame(width: 24, height: 24)
                                            Text("3")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                        }
                                        
                                        Text("再度思い出す練習を繰り返す")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(16)
                            .allowsHitTesting(false)
                        }
                    }
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // 問題カードセクション - より視覚的に魅力的なデザイン
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("問題カード", systemImage: "rectangle.on.rectangle.angled")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            showQuestionEditor = true
                        }) {
                            Label("編集", systemImage: "square.and.pencil")
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(12)
                        }
                    }
                    
                    // 問題カードを配置 - よりスタイリッシュなデザイン
                    EnhancedQuestionCarouselView(
                        keywords: viewModel.keywords,
                        comparisonQuestions: viewModel.comparisonQuestions,
                        memo: memo,
                        viewContext: viewContext,
                        showQuestionEditor: $showQuestionEditor
                    )
                    .frame(height: 220)
                    .padding(.vertical, 6)
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                .padding(.horizontal, 16)
                .padding(.bottom, 100) // フローティングボタンのためのスペース
            }
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground))
        .onTapGesture {
            // キーボードを閉じる
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    // MARK: - ヘルパーメソッド
    
    // タグ選択のトグル
    private func toggleTag(_ tag: Tag) {
        if viewModel.selectedTags.contains(where: { $0.id == tag.id }) {
            // 解除
            removeTag(tag)
        } else {
            // 選択
            viewModel.selectedTags.append(tag)
            viewModel.contentChanged = true
            viewModel.recordActivityOnSave = true
            
            // タグ変更時に即時保存
            if memo != nil {
                DispatchQueue.main.async {
                    viewModel.updateAndSaveTags()
                }
            }
        }
    }
    
    // タグ削除
    private func removeTag(_ tag: Tag) {
        if let index = viewModel.selectedTags.firstIndex(where: { $0.id == tag.id }) {
            viewModel.selectedTags.remove(at: index)
            viewModel.contentChanged = true
            viewModel.recordActivityOnSave = true
            
            // タグ変更時に即時保存
            if memo != nil {
                DispatchQueue.main.async {
                    viewModel.updateAndSaveTags()
                }
            }
        }
    }
    
    // 戻るボタンのハンドリング
    private func handleBackButton() {
        if viewModel.contentChanged {
            showUnsavedChangesAlert = true
        } else {
            if memo == nil {
                viewModel.cleanupOrphanedQuestions()
            }
            dismiss()
        }
    }
    
    // 画面表示時の初期化
    private func handleOnAppear() {
        if let memo = memo {
            viewModel.startLearningSession()
        }
    }
    
    // 画面終了時の処理
    private func handleOnDisappear() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        if let memo = memo, let sessionId = viewModel.currentSessionId {
            if viewModel.contentChanged {
                let noteText = "復習セッション: \(memo.title ?? "無題")"
                
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
    
    // タグ選択画面閉じた後の処理
    private func handleTagSelectionDismiss() {
        if memo != nil {
            viewModel.updateAndSaveTags()
            viewModel.contentChanged = true
        }
    }
    
    // 問題エディタ閉じた後の処理
    private func handleQuestionEditorDismiss() {
        if let memo = memo {
            viewModel.loadComparisonQuestions(for: memo)
            viewModel.contentChanged = true
            viewModel.recordActivityOnSave = true
        }
    }
}

// フローレイアウト - タグ表示用の自動折り返しレイアウト
struct FlowLayout: Layout {
    var spacing: CGFloat = 10
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for view in subviews {
            let viewSize = view.sizeThatFits(.unspecified)
            if lineWidth + viewSize.width > width {
                height += lineHeight + spacing
                lineWidth = viewSize.width
                lineHeight = viewSize.height
            } else {
                lineWidth += viewSize.width + spacing
                lineHeight = max(lineHeight, viewSize.height)
            }
        }
        
        height += lineHeight
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        var lineStartIndex = 0
        
        for (index, view) in subviews.enumerated() {
            let viewSize = view.sizeThatFits(.unspecified)
            
            if lineWidth + viewSize.width > bounds.width && index > lineStartIndex {
                placeLine(in: bounds, from: lineStartIndex, to: index, subviews: subviews, lineHeight: lineHeight, y: lineWidth)
                lineWidth = viewSize.width + spacing
                lineHeight = viewSize.height
                lineStartIndex = index
            } else {
                lineWidth += viewSize.width + spacing
                lineHeight = max(lineHeight, viewSize.height)
            }
        }
        
        placeLine(in: bounds, from: lineStartIndex, to: subviews.count, subviews: subviews, lineHeight: lineHeight, y: lineWidth)
    }
    
    private func placeLine(in bounds: CGRect, from startIndex: Int, to endIndex: Int, subviews: Subviews, lineHeight: CGFloat, y: CGFloat) {
        var x = bounds.minX
        let yPosition = bounds.minY + y - lineHeight
        
        for index in startIndex..<endIndex {
            let viewSize = subviews[index].sizeThatFits(.unspecified)
            subviews[index].place(
                at: CGPoint(x: x, y: yPosition),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: viewSize.width, height: viewSize.height)
            )
            x += viewSize.width + spacing
        }
    }
}

// モダンな記憶定着度セクション
struct ModernRecallSection: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // パーセンテージと記憶状態
            HStack(alignment: .center) {
                // 記憶度表示 - より視覚的に魅力的なデザイン
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.recallScore) / 100)
                        .stroke(
                            retentionColor(for: viewModel.recallScore),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 0) {
                        Text("\(Int(viewModel.recallScore))")
                            .font(.system(size: 24, weight: .bold))
                        Text("%")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(retentionColor(for: viewModel.recallScore))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(retentionDescription(for: viewModel.recallScore))
                        .font(.headline)
                        .foregroundColor(retentionColor(for: viewModel.recallScore))
                    
                    Text(retentionShortDescription(for: viewModel.recallScore))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                .padding(.leading, 8)
            }
            
            // 記憶度のスライダー - モダンでスタイリッシュなデザイン
            VStack(spacing: 12) {
                HStack {
                    Text("0%")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Slider(value: Binding(
                        get: { Double(viewModel.recallScore).isNaN ? 50.0 : Double(viewModel.recallScore) },
                        set: {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            
                            viewModel.recallScore = Int16($0)
                            viewModel.contentChanged = true
                            viewModel.recordActivityOnSave = true
                            viewModel.updateNextReviewDate()
                        }
                    ), in: 0...100, step: 1)
                    .accentColor(retentionColor(for: viewModel.recallScore))
                    
                    Text("100%")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // スライダー下部のインジケーター
                HStack(spacing: 0) {
                    ForEach(0..<5) { i in
                        let level = i * 20
                        let isActive = viewModel.recallScore >= Int16(level)
                        
                        Rectangle()
                            .fill(isActive ? retentionColorForLevel(i) : Color.gray.opacity(0.2))
                            .frame(height: 4)
                            .cornerRadius(2)
                    }
                }
            }
            
            // 次回復習日があれば表示 - よりスタイリッシュなデザイン
            if let nextReviewDate = viewModel.reviewDate {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(.blue)
                        .font(.system(size: 16))
                    
                    Text("次回の推奨復習日:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(viewModel.formattedDate(nextReviewDate))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(12)
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(12)
            }
        }
    }
    
    // 記憶度に応じた色を返す
    private func retentionColor(for score: Int16) -> Color {
        switch score {
        case 81...100:
            return Color(red: 0.0, green: 0.7, blue: 0.3) // 緑
        case 61...80:
            return Color(red: 0.3, green: 0.7, blue: 0.0) // 黄緑
        case 41...60:
            return Color(red: 0.95, green: 0.6, blue: 0.1) // オレンジ
        case 21...40:
            return Color(red: 0.9, green: 0.45, blue: 0.0) // 濃いオレンジ
        default:
            return Color(red: 0.9, green: 0.2, blue: 0.2) // 赤
        }
    }
    
    // レベルごとの色を返す
    private func retentionColorForLevel(_ level: Int) -> Color {
        switch level {
        case 4:
            return Color(red: 0.0, green: 0.7, blue: 0.3) // 緑
        case 3:
            return Color(red: 0.3, green: 0.7, blue: 0.0) // 黄緑
        case 2:
            return Color(red: 0.95, green: 0.6, blue: 0.1) // オレンジ
        case 1:
            return Color(red: 0.9, green: 0.45, blue: 0.0) // 濃いオレンジ
        default:
            return Color(red: 0.9, green: 0.2, blue: 0.2) // 赤
        }
    }
    
    // 記憶度に応じた簡潔な説明テキストを返す
    private func retentionDescription(for score: Int16) -> String {
        switch score {
        case 91...100:
            return "完璧に覚えた！"
        case 81...90:
            return "十分に理解できる"
        case 71...80:
            return "だいたい理解している"
        case 61...70:
            return "要点は覚えている"
        case 51...60:
            return "基本概念を思い出せる"
        case 41...50:
            return "断片的に覚えている"
        case 31...40:
            return "うっすらと覚えている"
        case 21...30:
            return "ほとんど忘れている"
        case 1...20:
            return "ほぼ完全に忘れている"
        default:
            return "全く覚えていない"
        }
    }
    
    // 記憶度に応じた短い説明テキストを返す
    private func retentionShortDescription(for score: Int16) -> String {
        switch score {
        case 81...100:
            return "長期記憶に定着しています"
        case 61...80:
            return "基本的な理解は定着しています"
        case 41...60:
            return "より頻繁な復習が必要です"
        case 21...40:
            return "基礎から再確認しましょう"
        default:
            return "もう一度学び直しましょう"
        }
    }
}

// 強化された問題カードビュー
struct EnhancedQuestionCarouselView: View {
    let keywords: [String]
    let comparisonQuestions: [ComparisonQuestion]
    let memo: Memo?
    let viewContext: NSManagedObjectContext
    @Binding var showQuestionEditor: Bool
    
    @StateObject private var state = CarouselState()
    @State private var isShowingAnswer = false
    @State private var currentIndex = 0
    
    var body: some View {
        VStack(spacing: 12) {
            if state.questions.isEmpty {
                // プレースホルダーカード
                emptyQuestionCard
            } else {
                // タブビュー
                TabView(selection: $currentIndex) {
                    ForEach(0..<state.questions.count, id: \.self) { index in
                        questionCard(for: state.questions[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .onChange(of: currentIndex) { _, _ in
                    isShowingAnswer = false
                }
                
                // インジケーターとナビゲーション
                HStack {
                    Button(action: {
                        withAnimation {
                            currentIndex = max(0, currentIndex - 1)
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .disabled(currentIndex == 0)
                    
                    Spacer()
                    
                    Text("\(currentIndex + 1) / \(state.questions.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            currentIndex = min(state.questions.count - 1, currentIndex + 1)
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .disabled(currentIndex == state.questions.count - 1)
                }
                .padding(.horizontal, 8)
            }
        }
        .onAppear {
            loadQuestions()
        }
        .onChange(of: keywords) { _, _ in loadQuestions() }
        .onChange(of: comparisonQuestions) { _, _ in loadQuestions() }
    }
    
    // 空のカードビュー
    private var emptyQuestionCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.stack.fill.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.blue)
                .padding(.bottom, 8)
            
            Text("問題を追加してみましょう！")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text("単語を入力するか、編集ボタンから問題を作成できます")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            Button(action: {
                showQuestionEditor = true
            }) {
                Text("問題を追加")
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    @ViewBuilder
    private func questionCard(for question: QuestionItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // カードヘッダー - シンプル化
            HStack {
                // タイプ表示
                Text(question.isExplanation ? "説明問題" : "比較問題")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(question.isExplanation ? Color.blue.opacity(0.1) : Color.orange.opacity(0.1))
                    .foregroundColor(question.isExplanation ? .blue : .orange)
                    .cornerRadius(8)
                
                Spacer()
                
                // シンプルな切り替えボタン - 単一ボタン
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isShowingAnswer.toggle()
                    }
                    // ハプティックフィードバック
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                } label: {
                    HStack(spacing: 4) {
                        Text(isShowingAnswer ? "問題を表示" : "回答を表示")
                            .font(.caption)
                        Image(systemName: isShowingAnswer ? "doc.text" : "text.bubble")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(16)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            Divider()
                .padding(.horizontal, 16)
            
            // コンテンツ部分 - 構造をシンプル化
            if isShowingAnswer {
                // 回答表示
                answerView(for: question)
            } else {
                // 問題表示
                questionView(for: question)
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 8)
    }

    // 問題表示用ビュー - 分離してシンプル化
    private func questionView(for question: QuestionItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("問題")
                .font(.headline)
                .foregroundColor(.blue)
            
            Text(question.questionText)
                .font(.body)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            
            if !question.subText.isEmpty {
                Text(question.subText)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(3)
            }
            
            Spacer(minLength: 20)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .frame(height: 140, alignment: .topLeading)
        .transition(.opacity)
    }

    // 回答表示用ビュー - 分離してシンプル化
    private func answerView(for question: QuestionItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("回答")
                .font(.headline)
                .foregroundColor(.green)
            
            if let answer = question.answer, !answer.isEmpty {
                ScrollView {
                    Text(answer)
                        .font(.body)
                        .lineLimit(nil)
                        .padding(.bottom, 8)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                    
                    Text("まだ回答がありません")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .frame(height: 140)
        .transition(.opacity)
    }
    
    // 質問データの読み込み
    private func loadQuestions() {
        state.loadQuestionsFromRegistry(
            keywords: keywords,
            comparisonQuestions: comparisonQuestions
        )
    }
}
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
