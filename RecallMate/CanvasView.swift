import SwiftUI
import PencilKit
import UIKit

struct CanvasView: UIViewRepresentable {
    @Binding var canvas: PKCanvasView
    @Binding var toolPicker: PKToolPicker
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> PKCanvasView {
        // 基本設定
        canvas.backgroundColor = UIColor.systemGray6
        // iOS 14.0以降では drawingPolicy を使用（allowsFingerDrawing は非推奨）
        canvas.drawingPolicy = .anyInput
        canvas.isOpaque = false
        
        // デリゲートを設定
        canvas.delegate = context.coordinator
        
        return canvas
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // 初期化が済んでいない場合のみ処理
        if !context.coordinator.isToolPickerInitialized {
            // 非同期処理として実行し、メインスレッドの負荷を軽減
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if let window = uiView.window {
                    toolPicker.setVisible(true, forFirstResponder: uiView)
                    toolPicker.addObserver(uiView)
                    uiView.becomeFirstResponder()
                    context.coordinator.isToolPickerInitialized = true
                }
            }
        }
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: CanvasView
        var isToolPickerInitialized = false
        
        init(_ parent: CanvasView) {
            self.parent = parent
        }
        
        // キャンバスの描画状態が変更された際のハンドリング
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // 描画中の処理を最適化（必要に応じて実装）
        }
    }
}
