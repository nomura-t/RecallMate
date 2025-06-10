// StudyGoalManager.swift
import SwiftUI
import Combine

class StudyGoalManager: ObservableObject {
    static let shared = StudyGoalManager()
    
    @Published var dailyGoalMinutes: Int = 60 // デフォルト60分
    @Published var isGoalEnabled: Bool = true
    @Published var currentStreak: Int = 0
    @Published var bestStreak: Int = 0
    
    private let userDefaults = UserDefaults.standard
    
    private init() {
        loadGoalSettings()
    }
    
    // 目標設定の保存と読み込み
    private func loadGoalSettings() {
        dailyGoalMinutes = userDefaults.integer(forKey: "dailyGoalMinutes")
        if dailyGoalMinutes == 0 {
            dailyGoalMinutes = 60 // デフォルト値
        }
        
        isGoalEnabled = userDefaults.bool(forKey: "isGoalEnabled")
        currentStreak = userDefaults.integer(forKey: "currentStreak")
        bestStreak = userDefaults.integer(forKey: "bestStreak")
    }
    
    func updateDailyGoal(minutes: Int) {
        dailyGoalMinutes = minutes
        userDefaults.set(minutes, forKey: "dailyGoalMinutes")
        objectWillChange.send()
    }
    
    func toggleGoal(enabled: Bool) {
        isGoalEnabled = enabled
        userDefaults.set(enabled, forKey: "isGoalEnabled")
        objectWillChange.send()
    }
    
    // 目標達成チェック（ActivityProgressViewから呼び出される）
    func checkGoalAchievement(todayStudySeconds: Int) -> Bool {
        guard isGoalEnabled else { return false }
        
        let todayStudyMinutes = Int(ceil(Double(todayStudySeconds) / 60.0))
        let isAchieved = todayStudyMinutes >= dailyGoalMinutes
        
        // ストリークの管理
        updateStreak(achieved: isAchieved)
        
        return isAchieved
    }
    
    private func updateStreak(achieved: Bool) {
        let lastCheckDate = userDefaults.object(forKey: "lastStreakCheckDate") as? Date
        let today = Calendar.current.startOfDay(for: Date())
        
        // 今日初回のチェックの場合のみストリークを更新
        if let lastDate = lastCheckDate {
            let lastCheckDay = Calendar.current.startOfDay(for: lastDate)
            if lastCheckDay < today {
                if achieved {
                    currentStreak += 1
                    bestStreak = max(bestStreak, currentStreak)
                } else {
                    currentStreak = 0
                }
                
                userDefaults.set(currentStreak, forKey: "currentStreak")
                userDefaults.set(bestStreak, forKey: "bestStreak")
                userDefaults.set(Date(), forKey: "lastStreakCheckDate")
            }
        } else {
            // 初回チェック
            currentStreak = achieved ? 1 : 0
            bestStreak = currentStreak
            userDefaults.set(currentStreak, forKey: "currentStreak")
            userDefaults.set(bestStreak, forKey: "bestStreak")
            userDefaults.set(Date(), forKey: "lastStreakCheckDate")
        }
    }
    
    // 達成率を計算
    func calculateAchievementRate(todayStudySeconds: Int) -> Double {
        guard isGoalEnabled && dailyGoalMinutes > 0 else { return 0.0 }
        
        let todayStudyMinutes = Double(todayStudySeconds) / 60.0
        let rate = todayStudyMinutes / Double(dailyGoalMinutes)
        return min(rate, 1.0) // 100%を上限とする
    }
}
