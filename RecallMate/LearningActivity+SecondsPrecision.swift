// LearningActivity+SecondsPrecision.swift

import Foundation
import CoreData

extension LearningActivity {
    // 秒単位の時間を取得・設定するためのラッパープロパティ
    var durationInSeconds: Int32 {
        get {
            // CoreData の属性値が設定されていればそれを使用
            if let secondsValue = primitiveValue(forKey: "durationSeconds") as? Int32, secondsValue > 0 {
                return secondsValue
            }
            // そうでない場合は分から秒に変換（後方互換性）
            return Int32(durationMinutes) * 60
        }
        set {
            // 秒を直接設定
            setPrimitiveValue(newValue, forKey: "durationSeconds")
            // 分も一緒に更新（後方互換性のため）
            let minutes = Int16(ceil(Double(newValue) / 60.0))
            setPrimitiveValue(minutes, forKey: "durationMinutes")
        }
    }
    
    // 分単位の時間（文字列）
    var minutesFormatted: String {
        let totalMinutes = Int(ceil(Double(self.durationInSeconds) / 60.0))
        return "\(totalMinutes)分"
    }
    
    // 時間を詳細に表示（時:分:秒）
    var timeFormatted: String {
        let seconds = Int(self.durationInSeconds)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        } else {
            return String(format: "%d:%02d", minutes, remainingSeconds)
        }
    }
    
    // 秒単位で学習時間を記録するメソッド
    static func recordActivityWithPrecision(
        type: ActivityType,
        durationSeconds: Int,
        memo: Memo?,
        note: String? = nil,
        in context: NSManagedObjectContext
    ) -> LearningActivity {
        let activity = LearningActivity(context: context)
        activity.id = UUID()
        activity.date = Date()
        activity.type = type.rawValue
        // プロパティ名を変更
        activity.durationInSeconds = Int32(durationSeconds)
        activity.memo = memo
        activity.note = note
        activity.color = type.color
        
        do {
            try context.save()
            StreakTracker.shared.checkAndUpdateStreak(in: context)
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("RefreshActivityData"),
                    object: nil
                )
            }
            
            return activity
        } catch {
            context.delete(activity)
            return activity
        }
    }
}
