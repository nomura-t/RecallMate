import SwiftUI
import UIKit

struct ScrollToBottomController: UIViewControllerRepresentable {
    var triggerScroll: Bool
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        // デバッグ用にタグを設定
        controller.view.tag = 12345
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if triggerScroll {
            
            // 十分な遅延を設けて、ビュー階層が確実に構築された後に実行
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                findAndScrollToBottom(from: UIApplication.shared.windows.first?.rootViewController)
            }
        }
    }
    
    private func findAndScrollToBottom(from viewController: UIViewController?) {
        guard let viewController = viewController else {
            return
        }
        
        
        // すべてのスクロールビューを列挙する
        var allScrollViews: [UIScrollView] = []
        findAllScrollViews(in: viewController.view, result: &allScrollViews)
        
        
        // 最も見込みのあるスクロールビューを選択（通常はコンテンツサイズが最大のもの）
        if let bestScrollView = allScrollViews.max(by: {
            $0.contentSize.height < $1.contentSize.height
        }) {
            
            // 最下部までスクロール
            let bottomOffset = CGPoint(
                x: 0,
                y: max(0, bestScrollView.contentSize.height - bestScrollView.bounds.height + bestScrollView.contentInset.bottom)
            )
            
            
            // アニメーションを追加
            UIView.animate(withDuration: 0.8) {
                bestScrollView.setContentOffset(bottomOffset, animated: true)
            }
            
            // ハプティックフィードバック
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            // 通知を送信
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(name: NSNotification.Name("ScrollToBottom"), object: nil)
            }
        } else {
            
            // 代替手段として通知だけ送信する
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(name: NSNotification.Name("ScrollToBottom"), object: nil)
            }
        }
    }
    
    // 再帰的にすべてのスクロールビューを見つける
    private func findAllScrollViews(in view: UIView, result: inout [UIScrollView]) {
        // 自身がスクロールビューかチェック
        if let scrollView = view as? UIScrollView {
            result.append(scrollView)
        }
        
        // すべての子ビューを再帰的に探索
        for subview in view.subviews {
            findAllScrollViews(in: subview, result: &result)
        }
    }
}
