import SwiftUI
import PencilKit
import UIKit

struct FullScreenCanvasView: View {
    @Binding var isDrawing: Bool
    @Binding var canvas: PKCanvasView
    @Binding var toolPicker: PKToolPicker
    
    // 複数ページ管理のための状態変数
    @State private var canvasPages: [PKDrawing] = [PKDrawing()]
    @State private var currentPageIndex: Int = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー部分（完了ボタンとページコントロール）
            HStack {
                Button("完了") {
                    // 最初のページの内容を元のキャンバスに反映
                    if canvasPages.count > 0 {
                        canvas.drawing = canvasPages[0]
                    }
                    isDrawing = false
                }
                .padding()
                
                Spacer()
                
                // ページ表示とナビゲーション
                HStack(spacing: 8) {
                    Button(action: {
                        if currentPageIndex > 0 {
                            // 現在のキャンバス内容を保存
                            canvasPages[currentPageIndex] = canvas.drawing
                            // 前のページに移動
                            currentPageIndex -= 1
                            canvas.drawing = canvasPages[currentPageIndex]
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(currentPageIndex > 0 ? .blue : .gray)
                    }
                    .disabled(currentPageIndex <= 0)
                    
                    Text("ページ %d/%d".localizedFormat(currentPageIndex + 1, canvasPages.count))
                        .font(.subheadline)
                    
                    Button(action: {
                        if currentPageIndex < canvasPages.count - 1 {
                            // 現在のキャンバス内容を保存
                            canvasPages[currentPageIndex] = canvas.drawing
                            // 次のページに移動
                            currentPageIndex += 1
                            canvas.drawing = canvasPages[currentPageIndex]
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(currentPageIndex < canvasPages.count - 1 ? .blue : .gray)
                    }
                    .disabled(currentPageIndex >= canvasPages.count - 1)
                }
                
                Spacer()
                
                // 新規ページ追加ボタン
                Button(action: {
                    // 現在のキャンバス内容を保存
                    canvasPages[currentPageIndex] = canvas.drawing
                    // 新しいページを追加
                    canvasPages.append(PKDrawing())
                    // 新しいページに移動
                    currentPageIndex = canvasPages.count - 1
                    canvas.drawing = canvasPages[currentPageIndex]
                }) {
                    Image(systemName: "plus.square")
                        .font(.title3)
                }
                .padding()
            }
            .padding(.horizontal)
            .background(Color.white)
            .shadow(radius: 1)
            
            // キャンバス部分
            DrawingCanvasView(canvas: $canvas, toolPicker: $toolPicker, drawing: $canvasPages[currentPageIndex])
                .ignoresSafeArea()
                .background(Color.white)
        }
        .onAppear {
            // 画面表示時の初期化
            if canvasPages.isEmpty {
                canvasPages = [PKDrawing()]
            }
            // 既存の内容があれば保存
            if !canvas.drawing.bounds.isEmpty {
                canvasPages[0] = canvas.drawing
            }
            
            // ツールピッカーの表示
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let _ = windowScene.windows.first {
                toolPicker.setVisible(true, forFirstResponder: canvas)
                toolPicker.addObserver(canvas)
                canvas.becomeFirstResponder()
            }
        }
        .onDisappear {
            // 画面を離れる際に現在のページを保存
            if currentPageIndex < canvasPages.count {
                canvasPages[currentPageIndex] = canvas.drawing
            }
            
            // 元のキャンバスに最初のページの内容を反映
            if canvasPages.count > 0 {
                canvas.drawing = canvasPages[0]
            }
            
            toolPicker.setVisible(false, forFirstResponder: canvas)
        }
    }
}

// キャンバスビュー（PKCanvasViewのラッパー）
struct DrawingCanvasView: UIViewRepresentable {
    @Binding var canvas: PKCanvasView
    @Binding var toolPicker: PKToolPicker
    @Binding var drawing: PKDrawing
    
    func makeUIView(context: Context) -> PKCanvasView {
        // 基本設定
        canvas.backgroundColor = .white
        canvas.drawingPolicy = .anyInput
        canvas.isOpaque = false
        
        // 描画内容を設定
        canvas.drawing = drawing
        
        return canvas
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // 描画内容の更新時の処理
        if uiView.drawing != drawing {
            uiView.drawing = drawing
        }
        
        // ツールピッカーを設定
        toolPicker.setVisible(true, forFirstResponder: uiView)
        toolPicker.addObserver(uiView)
        uiView.becomeFirstResponder()
    }
}
