import SwiftUI

struct CardDecorationModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
    }
}

extension View {
    func cardDecoration() -> some View {
        self.modifier(CardDecorationModifier())
    }
}
import SwiftUI

// ViewExtensions.swift に追加
struct CardStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
    }
}

extension View {
    func cardStyle() -> some View {
        self.modifier(CardStyleModifier())
    }
}
