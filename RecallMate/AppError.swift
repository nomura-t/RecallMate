import Foundation
import SwiftUI

// アプリケーション内のエラータイプを定義
enum AppError: Error, Identifiable, LocalizedError {
    case dataLoadFailed(String)
    case dataSaveFailed(String)
    case importFailed(String)
    case invalidInput(String)
    case unknown(String)
    
    var id: String {
        switch self {
        case .dataLoadFailed(let message): return "dataLoadFailed_\(message.hashValue)"
        case .dataSaveFailed(let message): return "dataSaveFailed_\(message.hashValue)"
        case .importFailed(let message): return "importFailed_\(message.hashValue)"
        case .invalidInput(let message): return "invalidInput_\(message.hashValue)"
        case .unknown(let message): return "unknown_\(message.hashValue)"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .dataLoadFailed(let message): return "データの読み込みに失敗しました: %@".localizedFormat(message)
        case .dataSaveFailed(let message): return "データの保存に失敗しました: %@".localizedFormat(message)
        case .importFailed(let message): return "インポートに失敗しました: %@".localizedFormat(message)
        case .invalidInput(let message): return "無効な入力です: %@".localizedFormat(message)
        case .unknown(let message): return "エラーが発生しました: %@".localizedFormat(message)
        }
    }
}

// エラーアラート表示用のView拡張
extension View {
    func errorAlert(error: Binding<AppError?>, viewName: String) -> some View {
        self.alert(item: error) { error in
            Alert(
                title: Text("エラー".localized),
                message: Text(error.errorDescription ?? "不明なエラーが発生しました".localized),
                dismissButton: .default(Text("OK".localized))
            )
        }
    }
}
