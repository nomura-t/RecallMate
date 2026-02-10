import SwiftUI

// MARK: - Legacy Card Modifiers (AppTheme.themeCard() に統合)

struct CardDecorationModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
            .cornerRadius(AppTheme.Radius.md)
            .shadow(
                color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.1),
                radius: 4, x: 0, y: 2
            )
    }
}

extension View {
    func cardDecoration() -> some View {
        self.modifier(CardDecorationModifier())
    }
}

struct CardStyleModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.md)
            .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
            .cornerRadius(AppTheme.Radius.md)
            .shadow(
                color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.08),
                radius: 3, x: 0, y: 1
            )
    }
}

extension View {
    func cardStyle() -> some View {
        self.modifier(CardStyleModifier())
    }
}
