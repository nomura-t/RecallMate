// AppTheme.swift - 統合デザインシステム
import SwiftUI

// MARK: - AppTheme

enum AppTheme {
    // MARK: - Colors
    enum Colors {
        static let brand = Color.orange
        static let brandGradient = LinearGradient(
            colors: [Color.orange, Color.orange.opacity(0.8)],
            startPoint: .leading,
            endPoint: .trailing
        )
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue

        static let cardBackground = Color(.secondarySystemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let groupedBackground = Color(.systemGroupedBackground)
    }

    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    // MARK: - Radius
    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
    }

    // MARK: - Animation
    enum Anim {
        static let quick = Animation.easeInOut(duration: 0.2)
        static let standard = Animation.easeInOut(duration: 0.3)
        static let slow = Animation.easeInOut(duration: 0.5)
        static let spring = Animation.spring(response: 0.5, dampingFraction: 0.8)
        static let bouncy = Animation.spring(response: 0.3, dampingFraction: 0.6)
    }
}

// MARK: - Theme Card Modifier (ダークモード対応)

struct ThemeCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                    .stroke(
                        colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear,
                        lineWidth: colorScheme == .dark ? 1 : 0
                    )
            )
            .shadow(
                color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.08),
                radius: 6, x: 0, y: 3
            )
    }
}

// MARK: - Theme Primary Button Modifier

struct ThemePrimaryButtonModifier: ViewModifier {
    let isEnabled: Bool

    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: isEnabled
                        ? [AppTheme.Colors.brand, AppTheme.Colors.brand.opacity(0.85)]
                        : [Color.gray, Color.gray.opacity(0.85)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(AppTheme.Radius.md)
            .scaleEffect(1.0)
    }
}

// MARK: - Theme Secondary Button Modifier

struct ThemeSecondaryButtonModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.medium))
            .foregroundColor(AppTheme.Colors.brand)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .fill(colorScheme == .dark ? Color(.systemGray5) : AppTheme.Colors.brand.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .stroke(AppTheme.Colors.brand.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - View Extensions

extension View {
    func themeCard() -> some View {
        self.modifier(ThemeCardModifier())
    }

    func themePrimaryButton(isEnabled: Bool = true) -> some View {
        self.modifier(ThemePrimaryButtonModifier(isEnabled: isEnabled))
    }

    func themeSecondaryButton() -> some View {
        self.modifier(ThemeSecondaryButtonModifier())
    }
}
