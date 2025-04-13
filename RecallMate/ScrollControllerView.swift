// ScrollControllerView.swift - スクロール位置を調整
import SwiftUI
import UIKit

struct ScrollControllerView: UIViewRepresentable {
    @Binding var shouldScroll: Bool
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if shouldScroll {
            // 親階層の中からUIScrollViewを探す
            DispatchQueue.main.async {
                findScrollViewAndScroll(from: uiView)
                // フラグをリセット
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    shouldScroll = false
                }
            }
        }
    }
    
    private func findScrollViewAndScroll(from view: UIView) {
        // 現在のビューの親階層を上にたどる
        var parentView = view.superview
        while parentView != nil {
            // UIScrollViewを探す
            if let scrollView = findScrollView(in: parentView!) {
                // スクロール位置を調整 - 以前は0.5だったのを0.4に変更してメモの内容部分に合わせる
                // ここを調整して、ちょうど良い位置に表示されるようにする
                let targetY = scrollView.contentSize.height * 0.32  // 0.5 → 0.32に変更
                
                // スクロール実行
                scrollView.setContentOffset(CGPoint(x: 0, y: targetY), animated: true)
                return
            }
            parentView = parentView?.superview
        }
    }
    
    // ビュー階層から再帰的にUIScrollViewを探す
    private func findScrollView(in view: UIView) -> UIScrollView? {
        // 自身がUIScrollViewかチェック
        if let scrollView = view as? UIScrollView {
            return scrollView
        }
        
        // 子ビューを再帰的に探索
        for subview in view.subviews {
            if let scrollView = findScrollView(in: subview) {
                return scrollView
            }
        }
        
        return nil
    }
}
