// String+Localization.swift

import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localized(comment: String) -> String {
        return NSLocalizedString(self, comment: comment)
    }
    
    func localizedFormat(_ arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
    
    // 数値付きのパラメータ化された文字列に便利
    func localizedWithInt(_ value: Int) -> String {
        return String(format: self.localized, value)
    }
    
    // 日付付きのパラメータ化された文字列に便利
    func localizedWithDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        return String(format: self.localized, formatter.string(from: date))
    }
}
