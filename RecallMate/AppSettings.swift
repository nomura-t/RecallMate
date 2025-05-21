import SwiftUI

class AppSettings: ObservableObject {
    @AppStorage("isDrawingDefault") var isDrawingDefault: Bool = false
    
    // 回答テキストのフォントサイズ設定
    @AppStorage("answerFontSize") var answerFontSize: Double = 16.0
    
    // 記録入力欄のフォントサイズ設定 - 新規追加
    @AppStorage("memoFontSize") var memoFontSize: Double = 16.0
    
    // 最小/最大フォントサイズ（参照用に保持）
    let minFontSize: Double = 12.0
    let maxFontSize: Double = 24.0
    
    // 利用可能なフォントサイズの配列 - 共通で使用
    let availableFontSizes: [Double] = [12, 14, 16, 18, 20, 22, 24]
}

// Double型の拡張メソッド
extension Double {
    var validated: Double {
        return self.isNaN ? 0.0 : self
    }
}
