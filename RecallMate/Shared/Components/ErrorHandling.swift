import SwiftUI

// MARK: - Error Alert View Modifier

struct ErrorAlertModifier: ViewModifier {
    @Binding var errorMessage: String?
    let title: String
    
    func body(content: Content) -> some View {
        content
            .alert(title, isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
    }
}

extension View {
    func errorAlert(title: String = "エラー", errorMessage: Binding<String?>) -> some View {
        self.modifier(ErrorAlertModifier(errorMessage: errorMessage, title: title))
    }
}

// MARK: - Error Handling Protocol

@MainActor
protocol ErrorHandling: ObservableObject {
    var errorMessage: String? { get set }
    var isLoading: Bool { get set }
    
    func handleError(_ error: Error, context: String?)
    func clearError()
}

extension ErrorHandling {
    func handleError(_ error: Error, context: String? = nil) {
        let prefix = context != nil ? "\(context!): " : ""
        errorMessage = "\(prefix)\(error.localizedDescription)"
        isLoading = false
    }
    
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - AppError Extensions

extension AppError {
    static let networkError = AppError.unknown("ネットワークエラーが発生しました")
    static let authenticationRequired = AppError.unknown("認証が必要です")
    static let invalidData = AppError.invalidInput("無効なデータです")
    static let userNotFound = AppError.unknown("ユーザーが見つかりません")
    static let permissionDenied = AppError.unknown("権限がありません")
    
    static func custom(_ message: String) -> AppError {
        return AppError.unknown(message)
    }
}