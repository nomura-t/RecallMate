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
    
    var body: some View {
        Section(header: Text("メモ詳細")) {
            // タイトルとページ範囲
            TextField("タイトル", text: $viewModel.title)
                .font(.headline)
            
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
                
                TextEditor(text: $viewModel.content)
                    .font(.system(size: CGFloat(appSettings.memoFontSize)))
                    .frame(minHeight: 120)
                    .padding(4)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
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
        
        // テスト日設定セクション
        TestDateSection(viewModel: viewModel)
    }
}
