// StudyGoalProgressView.swift
import SwiftUI
import CoreData

struct StudyGoalProgressView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var goalManager = StudyGoalManager.shared
    
    @State private var todayStudySeconds: Int = 0
    @State private var showGoalSettings = false
    @State private var showCelebration = false
    @State private var hasShownTodaysCelebration = false
    
    var body: some View {
        VStack(spacing: 16) {
            if goalManager.isGoalEnabled {
                // メイン達成度表示
                GoalAchievementCard(
                    todayStudySeconds: todayStudySeconds,
                    goalMinutes: goalManager.dailyGoalMinutes,
                    currentStreak: goalManager.currentStreak,
                    bestStreak: goalManager.bestStreak,
                    onSettingsPressed: { showGoalSettings = true }
                )
                
                // 追加の統計情報
                GoalStatisticsCard(
                    todayStudySeconds: todayStudySeconds,
                    goalMinutes: goalManager.dailyGoalMinutes
                )
            } else {
                // 目標が無効な場合の表示
                GoalDisabledCard(
                    onEnablePressed: { showGoalSettings = true }
                )
            }
        }
        .onAppear {
            fetchTodaysStudyData()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshActivityData"))) { _ in
            fetchTodaysStudyData()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ForceRefreshMemoData"))) { _ in
            fetchTodaysStudyData()
        }
        .onChange(of: todayStudySeconds) { _, newValue in
            checkForGoalAchievement(studySeconds: newValue)
        }
        .sheet(isPresented: $showGoalSettings) {
            GoalSettingView()
        }
        .overlay(
            Group {
                if showCelebration {
                    GoalAchievementCelebrationView(
                        isPresented: $showCelebration,
                        studyMinutes: Int(ceil(Double(todayStudySeconds) / 60.0)),
                        goalMinutes: goalManager.dailyGoalMinutes,
                        currentStreak: goalManager.currentStreak
                    )
                    .transition(.opacity)
                    .animation(.easeInOut, value: showCelebration)
                }
            }
        )
    }
    
    private func fetchTodaysStudyData() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-1)
        
        let fetchRequest: NSFetchRequest<LearningActivity> = LearningActivity.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "date >= %@ AND date <= %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        
        do {
            let activities = try viewContext.fetch(fetchRequest)
            todayStudySeconds = activities.reduce(0) { $0 + Int($1.durationInSeconds) }
        } catch {
            todayStudySeconds = 0
        }
    }
    
    private func checkForGoalAchievement(studySeconds: Int) {
        let isAchieved = goalManager.checkGoalAchievement(todayStudySeconds: studySeconds)
        
        // 今日初回の達成の場合のみお祝い表示
        if isAchieved && !hasShownTodaysCelebration {
            let today = Calendar.current.startOfDay(for: Date())
            let lastCelebrationDate = UserDefaults.standard.object(forKey: "lastCelebrationDate") as? Date
            
            if let lastDate = lastCelebrationDate {
                let lastCelebrationDay = Calendar.current.startOfDay(for: lastDate)
                if lastCelebrationDay < today {
                    showCelebrationIfNeeded()
                }
            } else {
                showCelebrationIfNeeded()
            }
        }
    }
    
    private func showCelebrationIfNeeded() {
        hasShownTodaysCelebration = true
        UserDefaults.standard.set(Date(), forKey: "lastCelebrationDate")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                showCelebration = true
            }
        }
        
        // 自動で隠す
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation {
                showCelebration = false
            }
        }
    }
}
