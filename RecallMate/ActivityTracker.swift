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
        
        // 開始時間を記録リから削除
        activeSessions.removeValue(forKey: sessionId)
        
        // 実時間を計算（分単位）
        let endTime = Date()
        let durationSeconds = endTime.timeIntervalSince(startTime)
        let durationMinutes = Int(durationSeconds / 60.0)
        
        // 0分の場合は最低1分として扱う、最大は120分
        let cappedDuration = min(max(durationMinutes, 1), 120)
        // 内容が変更された場合のみ記録
        // この条件チェックは呼び出し側に任せる
        
        // コンテキストを内部で取得
        let context = PersistenceController.shared.container.viewContext
        
        // 習慣化チャレンジと連携するメソッドを使用
        LearningActivity.recordActivityWithHabitChallenge(
            type: .review,
            durationMinutes: cappedDuration,
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
        return Int(durationSeconds / 60.0)
    }
    
    // 指定されたIDのセッションが存在するか確認
    func hasActiveSession(sessionId: UUID) -> Bool {
        return activeSessions[sessionId] != nil
    }
}
