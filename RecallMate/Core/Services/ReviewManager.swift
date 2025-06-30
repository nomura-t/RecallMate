// ReviewManager.swift
import SwiftUI
import StoreKit

class ReviewManager: ObservableObject {
    static let shared = ReviewManager()
    
    @Published var shouldShowReview = false
    
    private let userDefaults = UserDefaults.standard
    private let taskCompletionCountKey = "task_completion_count"
    private let lastReviewRequestDateKey = "last_review_request_date"
    private let reviewRequestedKey = "has_requested_review"
    
    private let requiredTaskCount = 15 // タスク完了15回でレビュー表示
    
    private init() {
        // 初回起動時の処理
        if userDefaults.object(forKey: taskCompletionCountKey) == nil {
            userDefaults.set(0, forKey: taskCompletionCountKey)
        }
    }
    
    // タスク完了時に呼び出すメソッド
    func incrementTaskCompletionCount() {
        let currentCount = userDefaults.integer(forKey: taskCompletionCountKey)
        let newCount = currentCount + 1
        userDefaults.set(newCount, forKey: taskCompletionCountKey)
        checkIfShouldShowReview()
    }
    
    func checkIfShouldShowReview() {
        // すでにレビューを依頼済みの場合は表示しない（1回だけにしたい場合）
        if userDefaults.bool(forKey: reviewRequestedKey) {
            return
        }
        
        // 前回の依頼から一定期間経過していない場合は表示しない
        if let lastRequestDate = userDefaults.object(forKey: lastReviewRequestDateKey) as? Date {
            let calendar = Calendar.current
            let daysSinceLastRequest = calendar.dateComponents([.day], from: lastRequestDate, to: Date()).day ?? 0
            if daysSinceLastRequest < 90 { // 例：3ヶ月間は再表示しない
                return
            }
        }
        
        let taskCompletionCount = userDefaults.integer(forKey: taskCompletionCountKey)
        
        // 条件：タスク完了回数が15回以上
        if taskCompletionCount >= requiredTaskCount {
            // レビュー表示フラグをON
            DispatchQueue.main.async {
                self.shouldShowReview = true
                
                // 表示日時を記録
                self.userDefaults.set(Date(), forKey: self.lastReviewRequestDateKey)
                self.userDefaults.set(true, forKey: self.reviewRequestedKey)
            }
        }
    }
    
    // レビュー表示をリセットする（テスト用）
    func resetReviewRequest() {
        userDefaults.set(false, forKey: reviewRequestedKey)
        userDefaults.set(0, forKey: taskCompletionCountKey)
    }
}
