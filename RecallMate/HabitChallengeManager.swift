import Foundation
import UserNotifications
import CoreData
import SwiftUI

// 習慣化チャレンジの状態を管理するクラス
class HabitChallengeManager: ObservableObject {
    static let shared = HabitChallengeManager()
    
    // 各種定数
    private let requiredMinutesPerDay = 5  // 1日あたりの必要学習時間（分）
    private let bronzeMilestone = 7        // 銅メダル達成日数
    private let silverMilestone = 21       // 銀メダル達成日数
    private let goldMilestone = 66         // 金メダル達成日数（目標）
    
    // UserDefaultsのキー
    private let currentStreakKey = "habitChallenge_currentStreak"
    private let lastActiveDateKey = "habitChallenge_lastActiveDate"
    private let bronzeAchievedKey = "habitChallenge_bronzeAchieved"
    private let silverAchievedKey = "habitChallenge_silverAchieved"
    private let goldAchievedKey = "habitChallenge_goldAchieved"
    private let highestStreakKey = "habitChallenge_highestStreak"
    
    // 公開プロパティ
    @Published var currentStreak: Int = 0
    @Published var highestStreak: Int = 0
    @Published var bronzeAchieved: Bool = false
    @Published var silverAchieved: Bool = false
    @Published var goldAchieved: Bool = false
    @Published var showBronzeModal: Bool = false
    @Published var showSilverModal: Bool = false
    @Published var showGoldModal: Bool = false
    @Published var lastActiveDate: Date? = nil
    
    private let defaults = UserDefaults.standard
    
    private init() {
        loadState()
        setupDailyNotification()
    }
    
    // 状態をロード
    private func loadState() {
        currentStreak = defaults.integer(forKey: currentStreakKey)
        highestStreak = defaults.integer(forKey: highestStreakKey)
        bronzeAchieved = defaults.bool(forKey: bronzeAchievedKey)
        silverAchieved = defaults.bool(forKey: silverAchievedKey)
        goldAchieved = defaults.bool(forKey: goldAchievedKey)
        
        if let dateData = defaults.object(forKey: lastActiveDateKey) as? Data {
            if let nsDate = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSDate.self, from: dateData) as? NSDate {
                lastActiveDate = nsDate as Date
            }
        }
    }
    
    // 状態を保存
    private func saveState() {
        defaults.set(currentStreak, forKey: currentStreakKey)
        defaults.set(highestStreak, forKey: highestStreakKey)
        defaults.set(bronzeAchieved, forKey: bronzeAchievedKey)
        defaults.set(silverAchieved, forKey: silverAchievedKey)
        defaults.set(goldAchieved, forKey: goldAchievedKey)
        
        if let date = lastActiveDate {
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: date, requiringSecureCoding: false) {
                defaults.set(data, forKey: lastActiveDateKey)
            }
        }
    }
    
    // 学習アクティビティの記録時にチェック
    func checkLearningActivity(minutes: Int, in context: NSManagedObjectContext) {
        let today = Calendar.current.startOfDay(for: Date())
        
        // 5分以上の学習があるか確認
        if minutes >= requiredMinutesPerDay {
            // 前日以前の最後のアクティビティ日を取得
            if let lastDate = lastActiveDate {
                let lastDay = Calendar.current.startOfDay(for: lastDate)
                let dayDifference = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
                
                if dayDifference == 1 {
                    // 連続日数を増加
                    currentStreak += 1
                    print("✅ 習慣化チャレンジ: 連続学習 \(currentStreak)日目")
                    checkMilestones()
                } else if dayDifference > 1 {
                    // 連続が途切れたのでリセット
                    print("⚠️ 習慣化チャレンジ: \(dayDifference)日の空白があったためリセット (\(currentStreak)日→1日)")
                    currentStreak = 1
                }
            } else {
                // 初めての記録
                currentStreak = 1
                print("🎉 習慣化チャレンジ: 開始しました")
            }
            
            // 最高記録を更新
            if currentStreak > highestStreak {
                highestStreak = currentStreak
            }
            
            // 最終活動日を更新
            lastActiveDate = today
            saveState()
        }
    }
    
    // 日々のチェック（アプリ起動時や日付変更時）
    func checkDailyProgress() {
        guard let lastDate = lastActiveDate else { return }
        
        let today = Calendar.current.startOfDay(for: Date())
        let lastDay = Calendar.current.startOfDay(for: lastDate)
        let dayDifference = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
        
        // 前日以降に活動がなかった場合
        if dayDifference > 1 {
            // 連続が途切れたのでリセット
            print("⚠️ 習慣化チャレンジ: \(dayDifference)日の空白があったためリセット (\(currentStreak)日→0日)")
            currentStreak = 0
            saveState()
        }
    }
    
    // マイルストーンのチェック
    private func checkMilestones() {
        // 銅メダル（7日）
        if currentStreak >= bronzeMilestone && !bronzeAchieved {
            bronzeAchieved = true
            showBronzeModal = true
            print("🥉 習慣化チャレンジ: 銅メダル獲得！")
        }
        
        // 銀メダル（21日）
        if currentStreak >= silverMilestone && !silverAchieved {
            silverAchieved = true
            showSilverModal = true
            print("🥈 習慣化チャレンジ: 銀メダル獲得！")
        }
        
        // 金メダル（66日）
        if currentStreak >= goldMilestone && !goldAchieved {
            goldAchieved = true
            showGoldModal = true
            print("🥇 習慣化チャレンジ: 金メダル獲得！習慣が定着しました！")
        }
    }
    
    // リマインダー通知のセットアップ
    private func setupDailyNotification() {
        let content = UNMutableNotificationContent()
        content.title = "今日の学習を忘れずに"
        content.body = "5分だけでも学習をしてみませんか？少しでもやることが習慣化には非常に有効です！"
        content.sound = .default
        
        // 毎日11:30に通知
        var components = DateComponents()
        components.hour = 11
        components.minute = 30
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "habitChallengeReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ 習慣化リマインダー通知の設定に失敗: \(error.localizedDescription)")
            } else {
                print("✅ 習慣化リマインダー通知を設定しました（毎日11:30）")
            }
        }
    }
    
    // テスト用リセット機能
    func resetChallenge() {
        currentStreak = 0
        bronzeAchieved = false
        silverAchieved = false
        goldAchieved = false
        saveState()
        print("🔄 習慣化チャレンジをリセットしました")
    }
    
    // デバッグ用に習慣化進捗を設定
    func setDebugStreak(_ days: Int) {
        currentStreak = days
        
        // マイルストーンも適切に設定
        if days >= bronzeMilestone {
            bronzeAchieved = true
        }
        
        if days >= silverMilestone {
            silverAchieved = true
        }
        
        if days >= goldMilestone {
            goldAchieved = true
        }
        
        // 最高記録も更新
        if days > highestStreak {
            highestStreak = days
        }
        
        lastActiveDate = Calendar.current.startOfDay(for: Date())
        saveState()
        print("🔧 習慣化チャレンジを \(days)日に設定しました")
    }
}
