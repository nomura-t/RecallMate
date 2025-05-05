// RecallMate/ColorScheme.swift
import SwiftUI

struct AppColors {
    // テキストカラー
    static var primaryText: Color {
        Color(.label)
    }
    
    static var secondaryText: Color {
        Color(.secondaryLabel)
    }
    
    static var tertiaryText: Color {
        Color(.tertiaryLabel)
    }
    
    // 背景色
    static var background: Color {
        Color(.systemBackground)
    }
    
    static var secondaryBackground: Color {
        Color(.secondarySystemBackground)
    }
    
    static var groupedBackground: Color {
        Color(.systemGroupedBackground)
    }
    
    static var cardBackground: Color {
        Color(.secondarySystemBackground)
    }
    
    // アクセントカラー
    static var accent: Color {
        Color.blue
    }
    
    static var accentLight: Color {
        Color.blue.opacity(0.1)
    }
    
    // 記憶度に応じた色を返す（ダークモード対応）
    static func retentionColor(for score: Int16) -> Color {
        switch score {
        case 81...100:
            return Color(red: 0.0, green: 0.7, blue: 0.3) // 緑
        case 61...80:
            return Color(red: 0.3, green: 0.7, blue: 0.0) // 黄緑
        case 41...60:
            return Color(red: 0.95, green: 0.6, blue: 0.1) // オレンジ
        case 21...40:
            return Color(red: 0.9, green: 0.45, blue: 0.0) // 濃いオレンジ
        default:
            return Color(red: 0.9, green: 0.2, blue: 0.2) // 赤
        }
    }
    
    // シャドウカラー - 環境変数をstaticコンテキストで使用する代替方法
    static func shadowColor(for colorScheme: ColorScheme) -> Color {
        return colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1)
    }
    
    // カード枠線 - 環境変数をstaticコンテキストで使用する代替方法
    static func borderColor(for colorScheme: ColorScheme) -> Color {
        return colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear
    }
}

// UIコンポーネント用の修飾子 - 名前を変更
struct AdaptiveCardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(AppColors.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.borderColor(for: colorScheme), lineWidth: colorScheme == .dark ? 1 : 0)
            )
            .shadow(
                color: AppColors.shadowColor(for: colorScheme),
                radius: colorScheme == .dark ? 3 : 5,
                x: 0,
                y: colorScheme == .dark ? 1 : 2
            )
    }
}

extension View {
    // メソッド名を変更して競合を回避
    func adaptiveCardStyle() -> some View {
        self.modifier(AdaptiveCardStyle())
    }
}
