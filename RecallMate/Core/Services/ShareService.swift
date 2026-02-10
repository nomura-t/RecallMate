import Foundation
import UIKit
import SwiftUI

class ShareService {
    static let shared = ShareService()
    
    private init() {}
    
    // デフォルトのシェアテキスト
    let defaultShareText = "RecallMateアプリを使って科学的に記憶力を強化することができます。長期記憶の定着に最適なアプリです！ https://apps.apple.com/app/recallmate/id6744206597" // 実際のApp StoreリンクIDに変更する
    
    // プラットフォーム別のURLスキームチェックと共有処理
    func canShareTo(platform: SocialPlatform) -> Bool {
        switch platform {
        case .line:
            guard let url = URL(string: "line://") else { return false }
            return UIApplication.shared.canOpenURL(url)
        case .whatsapp:
            guard let url = URL(string: "whatsapp://") else { return false }
            return UIApplication.shared.canOpenURL(url)
        case .facebook:
            guard let url = URL(string: "fb://") else { return false }
            return UIApplication.shared.canOpenURL(url)
        case .instagram:
            guard let url = URL(string: "instagram://") else { return false }
            return UIApplication.shared.canOpenURL(url)
        case .twitter:
            let twitterAvailable = URL(string: "twitter://").map { UIApplication.shared.canOpenURL($0) } ?? false
            let xAvailable = URL(string: "x://").map { UIApplication.shared.canOpenURL($0) } ?? false
            return twitterAvailable || xAvailable
        case .system:
            return true
        }
    }
    
    // LINE経由でシェア
    func shareViaLINE(text: String? = nil) {
        let shareText = text ?? defaultShareText
        let encodedText = shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let lineURL = URL(string: "https://line.me/R/msg/text/?\(encodedText)") else { return }

        if UIApplication.shared.canOpenURL(lineURL) {
            UIApplication.shared.open(lineURL)
            logShare(platform: .line)
        } else {
            notifyMissingApp(name: "LINE")
        }
    }
    
    // WhatsApp経由でシェア
    func shareViaWhatsApp(text: String? = nil) {
        let shareText = text ?? defaultShareText
        let encodedText = shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let whatsappURL = URL(string: "whatsapp://send?text=\(encodedText)") else { return }

        if UIApplication.shared.canOpenURL(whatsappURL) {
            UIApplication.shared.open(whatsappURL)
            logShare(platform: .whatsapp)
        } else {
            notifyMissingApp(name: "WhatsApp")
        }
    }
    
    // Facebook経由でシェア
    func shareViaFacebook() {
        // Facebookは直接テキストをシェアするURLスキームがないため、
        // システムシェアシートを使用するか、Facebook SDK統合が必要
        // ここではシンプルにFacebookアプリを開く
        if let fbURL = URL(string: "fb://") {
            if UIApplication.shared.canOpenURL(fbURL) {
                UIApplication.shared.open(fbURL)
                logShare(platform: .facebook)
            } else {
                notifyMissingApp(name: "Facebook")
            }
        }
    }
    
    // Instagram経由でシェア
    func shareViaInstagram() {
        // Instagramもテキストのみの共有URLスキームがないため、
        // 画像共有やストーリー共有にはさらに複雑な実装が必要
        if let instagramURL = URL(string: "instagram://") {
            if UIApplication.shared.canOpenURL(instagramURL) {
                UIApplication.shared.open(instagramURL)
                logShare(platform: .instagram)
            } else {
                notifyMissingApp(name: "Instagram")
            }
        }
    }
    
    // X（旧Twitter）経由でシェア
    func shareViaTwitter(text: String? = nil) {
        let shareText = text ?? defaultShareText
        let encodedText = shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // まずXの新URLスキームを試す
        if let xURL = URL(string: "x://post?text=\(encodedText)"),
           UIApplication.shared.canOpenURL(xURL) {
            UIApplication.shared.open(xURL)
            logShare(platform: .twitter)
        } else if let twitterURL = URL(string: "twitter://post?message=\(encodedText)"),
                  UIApplication.shared.canOpenURL(twitterURL) {
            UIApplication.shared.open(twitterURL)
            logShare(platform: .twitter)
        } else {
            notifyMissingApp(name: "X（Twitter）")
        }
    }
    
    // システムシェアシートを表示
    func showSystemShareSheet(text: String? = nil) -> UIActivityViewController {
        let shareText = text ?? defaultShareText
        let activityItems: [Any] = [shareText]
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        // iPadでの表示位置を指定するために必要な情報をプロパティとして保持
        controller.completionWithItemsHandler = { (activityType, completed, _, _) in
            if completed, let _ = activityType?.rawValue {
            }
        }
        
        return controller
    }
    
    // アプリがインストールされていない場合のコールバック
    private func notifyMissingApp(name: String) {
        // この関数はUIからの呼び出し元に情報を返すためのコールバックとして機能
        // 実際の実装ではNotificationCenterや通知関数をコールバックとして渡すなどの方法がある
        // イベント通知
        NotificationCenter.default.post(
            name: NSNotification.Name("MissingAppNotification"),
            object: nil,
            userInfo: ["appName": name]
        )
    }
    
    // シェアのログ記録
    private func logShare(platform: SocialPlatform) {
        // ここで必要に応じて解析やログ記録を追加
    }
}

// ソーシャルプラットフォームの列挙型
enum SocialPlatform: String, CaseIterable, Identifiable {
    case line = "LINE"
    case whatsapp = "WhatsApp"
    case facebook = "Facebook"
    case instagram = "Instagram"
    case twitter = "X (Twitter)"
    case system = "other"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        return self.rawValue
    }
    
    var iconName: String {
        switch self {
        case .line: return "line.icon" // カスタムアセット名
        case .whatsapp: return "whatsapp.icon" // カスタムアセット名
        case .facebook: return "facebook.icon" // カスタムアセット名
        case .instagram: return "instagram.icon" // カスタムアセット名
        case .twitter: return "twitter.icon" // カスタムアセット名
        case .system: return "square.and.arrow.up"
        }
    }
    
    var systemIconName: String {
        switch self {
        case .line: return "ellipsis.bubble"
        case .whatsapp: return "message.circle"
        case .facebook: return "f.square"
        case .instagram: return "camera"
        case .twitter: return "text.bubble"
        case .system: return "square.and.arrow.up"
        }
    }
    
    var color: Color {
        switch self {
        case .line: return Color.green
        case .whatsapp: return Color.green
        case .facebook: return Color.blue
        case .instagram: return Color.purple
        case .twitter: return Color.blue
        case .system: return Color.gray
        }
    }
}
