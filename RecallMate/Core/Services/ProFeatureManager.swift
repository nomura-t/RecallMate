import SwiftUI

// MARK: - Pro Feature Definitions

enum ProFeature {
    case widget
    case advancedStats
    case customGoals
    case unlimitedMemos
}

// MARK: - Pro Feature Manager

class ProFeatureManager: ObservableObject {
    static let shared = ProFeatureManager()

    /// 現在は全機能開放。将来 StoreKit 連携時に切り替え
    @Published var isPro: Bool = true

    func isFeatureAvailable(_ feature: ProFeature) -> Bool {
        isPro
    }
}

// MARK: - Pro Gated ViewModifier

struct ProGatedModifier: ViewModifier {
    let feature: ProFeature
    @ObservedObject private var proManager = ProFeatureManager.shared

    func body(content: Content) -> some View {
        if proManager.isFeatureAvailable(feature) {
            content
        } else {
            content
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.5))
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "lock.fill")
                                    .font(.title2)
                                Text("Pro機能".localized)
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                        )
                )
                .disabled(true)
        }
    }
}

extension View {
    func proGated(_ feature: ProFeature) -> some View {
        modifier(ProGatedModifier(feature: feature))
    }
}
