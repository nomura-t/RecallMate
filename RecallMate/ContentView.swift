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
    
    // Add focus state to ContentView
    @FocusState private var titleFieldFocused: Bool
    
    // 「使い方」ボタンと状態変数を追加
    @State private var showUsageModal = false
    
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
                
                Form {
                    // メモの詳細セクション - focus state を渡す
                    MemoDetailSection(
                        viewModel: viewModel,
                        memo: memo,
                        viewContext: viewContext,
                        showQuestionEditor: $showQuestionEditor,
                        isDrawing: $isDrawing,
                        canvasView: $canvasView,
                        toolPicker: $toolPicker,
                        onShouldFocusTitle: {
                            // フォーカスが必要な場合は後でフォーカスを設定
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                titleFieldFocused = true
                            }
                        }
                    )
                    .onChange(of: viewModel.title) { _, _ in
                        viewModel.contentChanged = true
                        viewModel.recordActivityOnSave = true
                    }
                    .onChange(of: viewModel.pageRange) { _, _ in
                        viewModel.contentChanged = true
                        viewModel.recordActivityOnSave = true
                    }
                    .onChange(of: viewModel.content) { _, _ in
                        viewModel.contentChanged = true
                        viewModel.recordActivityOnSave = true
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
                                        .contentShape(Rectangle())
                                        .highPriorityGesture(
                                            TapGesture()
                                                .onEnded { _ in
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
                                                }
                                        )
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
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                    .contentShape(Rectangle())
                                    .highPriorityGesture(
                                        TapGesture()
                                            .onEnded { _ in
                                                showTagSelection = true
                                            }
                                    )
                                }
                                .padding(.bottom, 4)
                            }
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
                        // 明示的にviewModelのメソッドを呼び出す
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
                    .contentShape(Rectangle())
                    .highPriorityGesture(
                        TapGesture()
                            .onEnded { _ in
                                viewModel.saveMemoWithTracking {
                                    dismiss()
                                }
                            }
                    )
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
            // タグ選択画面（高度な編集用）
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
                            // リアルタイムでの更新処理（オプション）
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
                    
                    // タイトル入力ガイド - 脳アイコンガイドと同じスタイル
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
                    // 問題カードガイド - 新規追加
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
                }
            )
            .alert("タイトルが必要です", isPresented: $viewModel.showTitleAlert) {
                Button("OK") { viewModel.showTitleAlert = false }
            } message: {
                Text("続行するにはメモのタイトルを入力してください。")
            }
        }
    }
}
