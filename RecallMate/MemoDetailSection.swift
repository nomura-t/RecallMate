import SwiftUI
import CoreData
import PencilKit

struct MemoDetailSection: View {
    @ObservedObject var viewModel: ContentViewModel
    let memo: Memo?
    let viewContext: NSManagedObjectContext
    @Binding var showQuestionEditor: Bool
    @Binding var isDrawing: Bool
    @Binding var canvasView: PKCanvasView
    @Binding var toolPicker: PKToolPicker
    @EnvironmentObject var appSettings: AppSettings
    
    // State変数をここで宣言（ViewModelに依存しない）
    @State private var showContentResetAlert = false
    @FocusState var titleFieldFocused: Bool
    @Namespace var titleField

    var body: some View {
        Section(header: Text("メモ詳細")) {
            // タイトルとページ範囲
            TextField("タイトル", text: $viewModel.title)
                .font(.headline)
                .focused($titleFieldFocused) // フォーカス制御
                .id(titleField) // スクロール用ID
                .background(viewModel.shouldFocusTitle ? Color.red.opacity(0.1) : Color.clear) // エラー表示
                .onChange(of: viewModel.title) { _, newValue in
                    if !newValue.isEmpty && viewModel.shouldFocusTitle {
                        viewModel.shouldFocusTitle = false // エラー表示を消す
                    }
                }
            
            TextField("ページ範囲", text: $viewModel.pageRange)
                .font(.subheadline)
                .padding(.bottom, 4) // 下に余白を追加して問題カードとの間隔を確保
            
            // 問題カードを配置
            QuestionCarouselView(
                keywords: viewModel.keywords,
                comparisonQuestions: viewModel.comparisonQuestions,
                memo: memo,
                viewContext: viewContext,
                showQuestionEditor: $showQuestionEditor
            )
            .padding(.vertical, 8) // 上下に余白を追加
            
            // 内容フィールド
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("内容")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // リセットボタン - SwiftUIのネイティブアラートを使用
                    Button(action: {
                        showContentResetAlert = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .padding(.horizontal, 8)
                    
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
                        .frame(width: 44, height: 44) // タップ領域を十分に確保
                        .highPriorityGesture(
                            TapGesture()
                                .onEnded { _ in
                                    isDrawing = true
                                }
                        )
                    }
                }
                
                // 修正：TextEditorにプレースホルダーを追加
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $viewModel.content)
                        .font(.system(size: CGFloat(appSettings.memoFontSize)))
                        .frame(minHeight: 120)
                        .padding(4)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    // プレースホルダー：viewModel.contentが空の場合にのみ表示
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
                        .allowsHitTesting(false) // プレースホルダーをタップしても入力を邪魔しない
                    }
                }
            }
            .padding(.top, 4) // 上に余白を追加して問題カードとの間隔を確保
            .alert("内容をリセット", isPresented: $showContentResetAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("リセット", role: .destructive) {
                    // ここでテキストをクリア - メインスレッドで明示的に実行
                    DispatchQueue.main.async {
                        viewModel.content = ""
                        viewModel.contentChanged = true
                        print("📝 内容をリセットしました") // デバッグログ
                    }
                }
            } message: {
                Text("メモの内容をクリアしますか？この操作は元に戻せません。")
            }
        }
        .onChange(of: viewModel.shouldFocusTitle) { _, shouldFocus in
            if shouldFocus {
                // タイトル欄にフォーカス
                titleFieldFocused = true
            }
        }
        // テスト日設定セクション
        TestDateSection(viewModel: viewModel)
    }
}
