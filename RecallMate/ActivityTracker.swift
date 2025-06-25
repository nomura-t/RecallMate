import Foundation
import CoreData
import SwiftUI

/// 学習活動を自動的に記録するためのサービスクラス
class ActivityTracker {
    static let shared = ActivityTracker()
    
    // セッションIDとその開始時間を保持する辞書
    private var activeSessions: [UUID: Date] = [:]
    
    private init() {}
    
    // コンテンツビューでの活動時間を計測するためのセッション開始
    func startTimingSession(for memo: Memo) -> UUID {
        let sessionId = UUID()
        let startTime = Date()
        
        // セッションを記録リに保持（UserDefaultsを使わない）
        activeSessions[sessionId] = startTime
        return sessionId
    }
    
    // セッション終了 - アクティビティを記録する（注釈パラメータを追加）
    func endTimingSession(sessionId: UUID, memo: Memo, note: String? = nil) {
        guard let startTime = activeSessions[sessionId] else {
            return
        }
        
        // 開始時間をメモリから削除
        activeSessions.removeValue(forKey: sessionId)
        
        // 実時間を秒単位で計算
        let endTime = Date()
        let durationSeconds = Int(endTime.timeIntervalSince(startTime))
        
        // 最小制約を緩和：0秒の場合のみ1秒にする
        let adjustedDuration = max(durationSeconds, 1)
        
        // 秒を直接使用して記録
        let context = PersistenceController.shared.container.viewContext
        let _ = LearningActivity.recordActivityWithPrecision(
            type: .review,
            durationSeconds: adjustedDuration, // 秒単位をそのまま使用
            memo: memo,
            note: note ?? "学習セッション: \(memo.title ?? "無題")",
            in: context
        )        
    }
    
    // 現在のセッション時間を取得（記録はしない）
    func getCurrentSessionDuration(sessionId: UUID) -> Int {
        guard let startTime = activeSessions[sessionId] else {
            return 0
        }
        
        let currentTime = Date()
        let durationSeconds = currentTime.timeIntervalSince(startTime)
        
        // ここで分に変換していると問題になる可能性がある
        // 修正: 秒単位で返す
        return Int(durationSeconds)
    }
    
    // 指定されたIDのセッションが存在するか確認
    func hasActiveSession(sessionId: UUID) -> Bool {
        return activeSessions[sessionId] != nil
    }
}
