import Foundation
import AVFoundation
import UIKit

class SoundManager {
    static let shared = SoundManager()
    
    private init() {}
    
    func playMemoryCompletedSound() {
        // システムサウンドを再生（1054は完了時の効果音）
        AudioServicesPlaySystemSound(1057)
        
        // 触覚フィードバックも追加
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
