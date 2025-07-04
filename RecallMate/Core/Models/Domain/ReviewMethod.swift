// ReviewMethod.swift - 新規作成
import Foundation
import SwiftUI

enum ReviewMethod: String, CaseIterable {
    case thorough = "じっくり復習コース"
    case quick = "さくっと復習コース"
    case assessment = "理解度確認のみ"
    
    var localizedRawValue: String {
        return self.rawValue.localized
    }
    
    var icon: String {
        switch self {
        case .thorough: return "brain.head.profile"
        case .quick: return "bolt.fill"
        case .assessment: return "checkmark.circle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .thorough: return "しっかりと時間をかけて復習したい時に".localized
        case .quick: return "時間がない時や軽く復習したい時に".localized
        case .assessment: return "記憶度だけを確認したい時に".localized
        }
    }
    
    var detail: String {
        switch self {
        case .thorough: return "4ステップのアクティブリコールで完全復習".localized
        case .quick: return "3ステップの効率的復習".localized
        case .assessment: return "素早く記憶度をチェックして次回の復習日を最適化".localized
        }
    }
    
    var color: Color {
        switch self {
        case .thorough: return .blue
        case .quick: return .orange
        case .assessment: return .purple
        }
    }
}
