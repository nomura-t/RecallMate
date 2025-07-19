import SwiftUI

// MARK: - UI Constants

struct UIConstants {
    // MARK: - Spacing
    static let smallSpacing: CGFloat = 8
    static let mediumSpacing: CGFloat = 16
    static let largeSpacing: CGFloat = 24
    static let extraLargeSpacing: CGFloat = 32
    
    // MARK: - Corner Radius
    static let smallCornerRadius: CGFloat = 8
    static let mediumCornerRadius: CGFloat = 12
    static let largeCornerRadius: CGFloat = 16
    
    // MARK: - Button Heights
    static let buttonHeight: CGFloat = 50
    static let compactButtonHeight: CGFloat = 36
    
    // MARK: - Icon Sizes
    static let smallIconSize: CGFloat = 16
    static let mediumIconSize: CGFloat = 24
    static let largeIconSize: CGFloat = 32
    
    // MARK: - Avatar Sizes
    static let smallAvatarSize: CGFloat = 30
    static let mediumAvatarSize: CGFloat = 40
    static let largeAvatarSize: CGFloat = 60
    
    // MARK: - Padding
    static let contentPadding: CGFloat = 16
    static let sectionPadding: CGFloat = 20
    static let screenPadding: CGFloat = 24
}

// MARK: - Extended Colors

extension AppColors {
    static let primary = Color.blue
    static let secondary = Color.gray
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    
    static let backgroundPrimary = Color(.systemBackground)
    static let backgroundSecondary = Color(.secondarySystemBackground)
    static let backgroundTertiary = Color(.tertiarySystemBackground)
    
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)
    
    static let overlay = Color.black.opacity(0.3)
    static let divider = Color.gray.opacity(0.3)
}

// MARK: - Animation Constants

struct AnimationConstants {
    static let quickAnimation = Animation.easeInOut(duration: 0.2)
    static let standardAnimation = Animation.easeInOut(duration: 0.3)
    static let slowAnimation = Animation.easeInOut(duration: 0.5)
    
    static let spring = Animation.spring(response: 0.5, dampingFraction: 0.8)
    static let bouncy = Animation.spring(response: 0.3, dampingFraction: 0.6)
}

// MARK: - String Constants

struct StringConstants {
    // MARK: - Common Actions
    static let cancel = "キャンセル"
    static let ok = "OK"
    static let save = "保存"
    static let delete = "削除"
    static let edit = "編集"
    static let add = "追加"
    static let close = "閉じる"
    static let retry = "再試行"
    
    // MARK: - Loading Messages
    static let loading = "読み込み中..."
    static let saving = "保存中..."
    static let deleting = "削除中..."
    static let authenticating = "認証中..."
    static let creating = "作成中..."
    
    // MARK: - Error Messages
    static let networkError = "ネットワークエラーが発生しました"
    static let authError = "認証に失敗しました"
    static let unknownError = "不明なエラーが発生しました"
    static let tryAgain = "もう一度お試しください"
    
    // MARK: - Empty States
    static let noData = "データがありません"
    static let noResults = "結果が見つかりません"
    static let noConnection = "接続できません"
}

// MARK: - System Constants

struct SystemConstants {
    static let minimumTapTargetSize: CGFloat = 44
    static let maxContentWidth: CGFloat = 600
    static let cardElevation: CGFloat = 2
    static let defaultTimeout: TimeInterval = 30
    static let debounceDelay: TimeInterval = 0.3
}

// MARK: - Feature Constants

struct StudyConstants {
    static let defaultStudySessionMinutes = 25
    static let defaultBreakMinutes = 5
    static let maxTagsPerPost = 5
    static let maxPostTitleLength = 100
    static let maxPostContentLength = 1000
    static let maxGroupMembers = 50
}