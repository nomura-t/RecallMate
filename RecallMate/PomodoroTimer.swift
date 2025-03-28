import Foundation
import SwiftUI
import UserNotifications
import AudioToolbox

// タイマーの状態を管理するクラス
class PomodoroTimer: ObservableObject {
    // タイマーの状態
    enum TimerState {
        case stopped
        case running
        case paused
    }
    
    // セッションの種類
    enum SessionType {
        case work
        case shortBreak
        case longBreak
        
        var title: String {
            switch self {
            case .work: return "作業"
            case .shortBreak: return "短い休憩"
            case .longBreak: return "長い休憩"
            }
        }
    }
    
    // 設定
    @Published var workDuration: TimeInterval = 25 * 60  // 25分
    @Published var shortBreakDuration: TimeInterval = 5 * 60  // 5分
    @Published var longBreakDuration: TimeInterval = 15 * 60  // 15分
    @Published var longBreakAfter: Int = 4  // 4セッションごとに長い休憩
    @Published var notificationSound: String = "default"  // 通知音設定
    
    // 状態
    @Published var timerState: TimerState = .stopped
    @Published var currentSession: SessionType = .work
    @Published var sessionCount: Int = 0
    @Published var timeRemaining: TimeInterval = 25 * 60  // デフォルト：25分
    @Published var progress: Double = 1.0
    @Published var notificationsEnabled = false
    
    private var timer: Timer?
    private var startTime: Date?
    private var savedTimeRemaining: TimeInterval = 0
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    init() {
        // 通知許可を得る
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.notificationsEnabled = granted
                if let error = error {
                } else if granted {
                    // 通知カテゴリを設定
                    self.setupNotificationCategories()
                } else {
                }
            }
            TimerService.shared.registerTimer(self)
        }
        
        // アプリがバックグラウンドに入った時の処理
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        // アプリがフォアグラウンドに戻った時の処理
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    // PomodoroTimer.swift に追加するメソッド
    public func resetSessionCount() {
        sessionCount = 0
    }
    // 通知カテゴリの設定
    private func setupNotificationCategories() {
        let startAction = UNNotificationAction(identifier: "START_ACTION", title: "次のセッションを開始", options: .foreground)
        let category = UNNotificationCategory(identifier: "pomodoroTimer", actions: [startAction], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    // アプリがバックグラウンドに入った時
    @objc func appMovedToBackground() {
        if timerState == .running {
            // バックグラウンドタスクを開始
            backgroundTaskID = UIApplication.shared.beginBackgroundTask {
                self.endBackgroundTask()
            }
            
            // ローカル通知をスケジュール
            scheduleBackgroundNotification()
        }
    }
    
    // アプリがフォアグラウンドに戻った時
    @objc func appMovedToForeground() {
        if backgroundTaskID != .invalid {
            endBackgroundTask()
        }
        
        // 予定された通知をキャンセル
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // タイマーが実行中ならインターフェースを更新
        if timerState == .running {
            updateTimerAfterBackground()
        }
    }
    
    // バックグラウンドタスクを終了
    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
    
    // バックグラウンド通知をスケジュール
    private func scheduleBackgroundNotification() {
        if timeRemaining <= 0 { return }
        
        let content = UNMutableNotificationContent()
        
        switch currentSession {
        case .work:
            content.title = "作業時間が終了します"
            content.body = "次は休憩時間です"
        case .shortBreak, .longBreak:
            content.title = "休憩時間が終了します"
            content.body = "次は作業時間です"
        }
        
        content.sound = .default
        content.categoryIdentifier = "pomodoroTimer"
        
        // 残り時間にタイマーをセット
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeRemaining, repeats: false)
        let request = UNNotificationRequest(identifier: "pomodoroTimer", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
            }
        }
    }
    
    // フォアグラウンドに戻った後のタイマー更新
    private func updateTimerAfterBackground() {
        if let startTime = startTime {
            let elapsedTime = Date().timeIntervalSince(startTime)
            timeRemaining = max(0, savedTimeRemaining - elapsedTime)
            
            if timeRemaining <= 0 {
                // タイマーが終了している場合
                timerState = .stopped
                moveToNextSession()
                sendNotification()
            } else {
                // タイマーがまだ残っている場合は継続
                timer?.invalidate()
                timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                    self?.updateTimer()
                }
            }
        }
    }
    
    // タイマーを開始
    func start() {
        // セッションに応じた残り時間を確実に設定
        if timerState == .stopped {
            switch currentSession {
            case .work:
                timeRemaining = workDuration
            case .shortBreak:
                timeRemaining = shortBreakDuration
            case .longBreak:
                timeRemaining = longBreakDuration
            }
            savedTimeRemaining = timeRemaining
        }
        
        startTime = Date()
        timerState = .running
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    // タイマーを一時停止
    func pause() {
        timer?.invalidate()
        timer = nil
        
        savedTimeRemaining = timeRemaining
        timerState = .paused
    }
    
    // タイマーを再開
    func resume() {
        startTime = Date()
        timerState = .running
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    // タイマーをリセット
    func reset() {
        timer?.invalidate()
        timer = nil
        
        timerState = .stopped
        setupNextSession()
    }
    
    // 通知許可を再チェック
    func recheckNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // タイマーを更新
    private func updateTimer() {
        guard let startTime = startTime else { return }
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        let remainingTime = max(0, savedTimeRemaining - elapsedTime)
        
        timeRemaining = remainingTime
        
        // 進捗状況の更新
        switch currentSession {
        case .work:
            progress = timeRemaining / workDuration
        case .shortBreak:
            progress = timeRemaining / shortBreakDuration
        case .longBreak:
            progress = timeRemaining / longBreakDuration
        }
        
        // タイマー終了時
        if remainingTime <= 0 {
            timer?.invalidate()
            timer = nil
            
            // 通知を送信
            sendNotification()
            
            // セッションカウントを更新
            if currentSession == .work {
                sessionCount += 1
                ReviewManager.shared.incrementTaskCompletionCount()
            }
            
            // 次のセッションを設定
            moveToNextSession()
        }
    }
    
    // 次のセッションに移動
    private func moveToNextSession() {
        switch currentSession {
        case .work:
            // 作業後: セッション数に応じて短い休憩または長い休憩
            if sessionCount % longBreakAfter == 0 {
                currentSession = .longBreak
                timeRemaining = longBreakDuration
            } else {
                currentSession = .shortBreak
                timeRemaining = shortBreakDuration
            }
        case .shortBreak, .longBreak:
            // 休憩後: 作業に戻る
            currentSession = .work
            timeRemaining = workDuration
        }
        
        savedTimeRemaining = timeRemaining
        progress = 1.0
        timerState = .stopped
    }
    
    // 次のセッションを設定（リセット用）
    private func setupNextSession() {
        switch currentSession {
        case .work:
            timeRemaining = workDuration
        case .shortBreak:
            timeRemaining = shortBreakDuration
        case .longBreak:
            timeRemaining = longBreakDuration
        }
        
        savedTimeRemaining = timeRemaining
        progress = 1.0
    }
    // 通知を送信
    private func sendNotification() {
        // アプリがフォアグラウンドの場合でも通知を表示
        let content = UNMutableNotificationContent()
        
        switch currentSession {
        case .work:
            content.title = "作業時間が終了しました"
            content.body = "休憩をとりましょう"
        case .shortBreak, .longBreak:
            content.title = "休憩時間が終了しました"
            content.body = "作業を再開しましょう"
        }
        
        // 通知音を設定
        if notificationSound != "none" {
            content.sound = .default
        }
        
        // カテゴリIDを設定
        content.categoryIdentifier = "pomodoroTimer"
        
        // 即時に通知を表示
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
            }
        }
        
        // アプリがフォアグラウンドの場合はサウンドを再生
        if UIApplication.shared.applicationState == .active {
            playTimerEndSound()
        }
    }
    
    // タイマー終了サウンドを再生（アプリ内）
    private func playTimerEndSound() {
        // システムサウンドをフォアグラウンドで再生
        AudioServicesPlaySystemSound(1005) // システムサウンド ID
    }
    
    // フォーマットされた残り時間を取得
    func formattedTimeRemaining() -> String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
