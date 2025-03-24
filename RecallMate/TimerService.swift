// TimerService.swift
import Foundation

class TimerService {
    static let shared = TimerService()
    
    // 現在のポモドーロタイマーへの参照
    private var currentTimer: PomodoroTimer?
    
    private init() {}
    
    // タイマーを登録
    func registerTimer(_ timer: PomodoroTimer) {
        currentTimer = timer
    }
    
    // 通知からセッション開始
    func startNextSession() {
        guard let timer = currentTimer else { return }
        
        if timer.timerState == .stopped {
            // 停止状態なら開始
            timer.start()
        } else if timer.timerState == .paused {
            // 一時停止状態なら再開
            timer.resume()
        }
        // 実行中の場合は何もしない
    }
}
