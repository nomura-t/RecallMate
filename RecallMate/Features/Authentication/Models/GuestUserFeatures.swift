import Foundation
import SwiftUI

// ゲストユーザーの機能制限を定義
struct GuestUserFeatures {
    
    // MARK: - 利用可能な機能
    static let availableFeatures = [
        "メモの作成・編集・削除",
        "復習機能（スペースドリピティション）",
        "タグ管理",
        "学習統計の閲覧（ローカルデータのみ）",
        "基本的な設定変更",
        "オフライン使用"
    ]
    
    // MARK: - 制限される機能
    static let restrictedFeatures = [
        "データのクラウド同期",
        "複数デバイス間でのデータ共有",
        "フレンド機能",
        "スタディグループへの参加",
        "ソーシャル機能（ランキング、通知）",
        "プロフィール写真のアップロード",
        "データのエクスポート/インポート"
    ]
    
    // MARK: - 機能チェックメソッド
    
    /// フレンド機能が使用可能かチェック
    static func canUseFriendFeature(isAuthenticated: Bool, isAnonymous: Bool) -> Bool {
        return isAuthenticated && !isAnonymous
    }
    
    /// グループ機能が使用可能かチェック
    static func canUseGroupFeature(isAuthenticated: Bool, isAnonymous: Bool) -> Bool {
        return isAuthenticated && !isAnonymous
    }
    
    /// クラウド同期が使用可能かチェック
    static func canUseCloudSync(isAuthenticated: Bool, isAnonymous: Bool) -> Bool {
        return isAuthenticated && !isAnonymous
    }
    
    /// ランキング機能が使用可能かチェック
    static func canViewRanking(isAuthenticated: Bool, isAnonymous: Bool) -> Bool {
        // ランキングの閲覧は可能だが、参加は不可
        return true
    }
    
    /// ランキングに参加可能かチェック
    static func canParticipateInRanking(isAuthenticated: Bool, isAnonymous: Bool) -> Bool {
        return isAuthenticated && !isAnonymous
    }
    
    /// プロフィール編集が可能かチェック
    static func canEditProfile(isAuthenticated: Bool, isAnonymous: Bool) -> Bool {
        // ゲストユーザーは表示名のみ編集可能
        return true
    }
    
    /// プロフィール画像のアップロードが可能かチェック
    static func canUploadProfileImage(isAuthenticated: Bool, isAnonymous: Bool) -> Bool {
        return isAuthenticated && !isAnonymous
    }
    
    // MARK: - UI表示用メッセージ
    
    /// 機能制限メッセージを取得
    static func getRestrictionMessage(for feature: RestrictedFeature) -> String {
        switch feature {
        case .friends:
            return "フレンド機能を使用するには、アカウントのアップグレードが必要です。"
        case .groups:
            return "グループ機能を使用するには、アカウントのアップグレードが必要です。"
        case .cloudSync:
            return "データを同期するには、アカウントのアップグレードが必要です。"
        case .ranking:
            return "ランキングに参加するには、アカウントのアップグレードが必要です。"
        case .profileImage:
            return "プロフィール画像をアップロードするには、アカウントのアップグレードが必要です。"
        case .dataExport:
            return "データのエクスポート/インポートには、アカウントのアップグレードが必要です。"
        }
    }
    
    // MARK: - 制限される機能の列挙
    enum RestrictedFeature {
        case friends
        case groups
        case cloudSync
        case ranking
        case profileImage
        case dataExport
    }
}

// MARK: - ゲストユーザー向けのアップグレード促進バナー
struct GuestUserUpgradeBanner: View {
    let feature: GuestUserFeatures.RestrictedFeature
    let onUpgrade: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)
                
                Text(GuestUserFeatures.getRestrictionMessage(for: feature))
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            
            Button(action: onUpgrade) {
                Text("アカウントをアップグレード")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(16)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}