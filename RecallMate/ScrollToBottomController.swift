// ScrollToBottomController.swift - 新規ファイル
import SwiftUI
import UIKit

struct ScrollToBottomController: UIViewControllerRepresentable {
    var triggerScroll: Bool
    
    func makeUIViewController(context: Context) -> UIViewController {
        return UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if triggerScroll {
            print("📜 ScrollToBottomController: スクロールトリガーON")
            // 次のメインループで実行を遅延させる
            DispatchQueue.main.async {
                self.scrollToBottom(from: uiViewController.view)
            }
        }
    }
    
    private func scrollToBottom(from view: UIView) {
        // ビュー階層内からUIScrollViewを探す
        func findScrollView(in view: UIView) -> UIScrollView? {
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
        
        print("📜 スクロールビュー検索開始")
        guard let scrollView = findScrollView(in: view) else {
            print("❌ スクロールビューが見つかりませんでした")
            return
        }
        
        print("✅ スクロールビューを発見: \(scrollView)")
        
        // 最下部までスクロール
        let bottomOffset = CGPoint(
            x: 0,
            y: scrollView.contentSize.height - scrollView.bounds.height + scrollView.contentInset.bottom
        )
        
        print("📜 スクロール実行: \(bottomOffset)")
        
        // アニメーションを追加
        UIView.animate(withDuration: 0.8) {
            scrollView.setContentOffset(bottomOffset, animated: true)
        }
        
        // ハプティックフィードバック
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}
