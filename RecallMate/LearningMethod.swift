import Foundation
import SwiftUI

enum LearningMethod: String, CaseIterable {
    case thorough = "じっくり学習コース"
    case quick = "さくっと学習コース"
    case recordOnly = "記録のみコース"
    
    var localizedRawValue: String {
        return self.rawValue.localized
    }
    
    var icon: String {
        switch self {
        case .thorough: return "brain.head.profile"
        case .quick: return "bolt.fill"
        case .recordOnly: return "doc.text.fill"
        }
    }
    
    var description: String {
        switch self {
        case .thorough: return "しっかりと時間をかけて学習したい時に".localized
        case .quick: return "時間がない時や軽く学習したい時に".localized
        case .recordOnly: return "既に学習済みの内容を記録して、効果的な復習計画を立てたい時に".localized
        }
    }
    
    var detail: String {
        switch self {
        case .thorough: return "4ステップのアクティブリコールで完全習得".localized
        case .quick: return "3ステップの効率的アクティブリコール".localized
        case .recordOnly: return "学習記録から最適な復習タイミングを自動計算。分散学習の効果で長期記憶への定着をサポートします".localized
        }
    }
    
    var color: Color {
        switch self {
        case .thorough: return .blue
        case .quick: return .orange
        case .recordOnly: return .green
        }
    }
}
