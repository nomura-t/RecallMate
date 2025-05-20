// TodayStudyTimeCard.swift
import SwiftUI
import CoreData

struct TodayStudyTimeCard: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    // コアデータからロードした基本時間（秒）
    @State private var baseStudySeconds: Int = 0
    
    // ストップウォッチ関連の状態管理
    @State private var activeSessionSeconds: Int = 0
    @State private var sessionStartTime: Date? = nil
    @State private var isRunning: Bool = false
    @State private var lastRefreshed = Date()
    
    // タイマーの管理
    @State private var timer: Timer? = nil
    
    var body: some View {
        HStack(spacing: 8) {
            // 学習時間アイコン
            Image(systemName: isRunning ? "timer" : "clock.fill")
                .foregroundColor(isRunning ? .green : .blue)
                .font(.system(size: 14))
            
            // 学習時間表示（ベース時間＋アクティブセッション時間）
            Text(formattedTotalStudyTime)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
            
            // リアルタイム更新中を示すインジケーター
            Circle()
                .fill(isRunning ? Color.green : Color.gray.opacity(0.5))
                .frame(width: 6, height: 6)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 2, x: 0, y: 1)
        )
        .onAppear {
            // アプリ表示時に基本時間を取得し、ストップウォッチを開始
            fetchTodaysStudyData()
            startStopwatch()
        }
        .onDisappear {
            // 非表示時にストップウォッチを停止
            stopStopwatch()
        }
        // データ更新通知の監視（新しい学習活動が記録された時）
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshActivityData"))) { _ in
            // 基本時間を更新するが、セッション時間は継続
            updateBaseTime()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ForceRefreshMemoData"))) { _ in
            // 基本時間を更新するが、セッション時間は継続
            updateBaseTime()
        }
    }
    
    // 合計表示時間（ベース時間＋アクティブセッション時間）
    private var totalStudySeconds: Int {
        return baseStudySeconds + activeSessionSeconds
    }
    
    // 時間のフォーマット（時:分:秒）
    private var formattedTotalStudyTime: String {
        let totalSeconds = totalStudySeconds
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    // CoreDataから今日の学習データを取得（基本時間として設定）
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
            
            // 合計学習時間を秒で計算（分から秒へ変換）
            baseStudySeconds = activities.reduce(0) { $0 + Int($1.durationMinutes) * 60 }
            
            // 更新時刻を記録
            lastRefreshed = Date()
        } catch {
            print("Error fetching today's study data: \(error)")
        }
    }
    
    // 基本時間の更新（セッションタイマーはリセットしない）
    private func updateBaseTime() {
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
            
            // 新しい基本時間を計算
            let newBaseSeconds = activities.reduce(0) { $0 + Int($1.durationMinutes) * 60 }
            
            // セッション時間をリセットするかどうかを判断
            if newBaseSeconds > baseStudySeconds {
                // 新しい活動が記録された場合、それが現在のセッションを含む場合がある
                // 安全のため、セッション時間をリセット
                baseStudySeconds = newBaseSeconds
                resetSessionTime()
            } else {
                // 特に変更がない場合は基本時間のみを更新
                baseStudySeconds = newBaseSeconds
            }
            
            // 更新時刻を記録
            lastRefreshed = Date()
        } catch {
            print("Error updating base time: \(error)")
        }
    }
    
    // セッション時間のリセット（ストップウォッチのリセット）
    private func resetSessionTime() {
        activeSessionSeconds = 0
        sessionStartTime = Date()
    }
    
    // ストップウォッチ開始
    private func startStopwatch() {
        // セッション開始時間を記録
        sessionStartTime = Date()
        activeSessionSeconds = 0
        
        // 既存のタイマーを停止
        stopStopwatch()
        
        // 1秒ごとに更新する新しいタイマーを作成
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let startTime = sessionStartTime {
                // 現在の経過時間を計算（秒単位）
                let elapsedTime = Int(Date().timeIntervalSince(startTime))
                activeSessionSeconds = elapsedTime
            }
        }
        
        // タイマーを確実に動かすためRunLoopに追加
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
        
        isRunning = true
    }
    
    // ストップウォッチ停止
    private func stopStopwatch() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
}
