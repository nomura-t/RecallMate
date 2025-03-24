import XCTest
@testable import RecallMate

final class ReviewCalculatorTests: XCTestCase {

    func testReviewDateCalculation() {
        let today = Date()

        // 記憶度が低い場合（10%）
        let lowScoreDate = ReviewCalculator.calculateNextReviewDate(recallScore: 10, lastReviewedDate: today, perfectRecallCount: 0)
        XCTAssertTrue(Calendar.current.date(byAdding: .day, value: 1, to: today)! <= lowScoreDate)

        // 記憶度が高い場合（90%）
        let highScoreDate = ReviewCalculator.calculateNextReviewDate(recallScore: 90, lastReviewedDate: today, perfectRecallCount: 3)
        XCTAssertTrue(Calendar.current.date(byAdding: .day, value: 14, to: today)! <= highScoreDate)

        // 100%記憶回数が多い場合（10回）
        let perfectRecallDate = ReviewCalculator.calculateNextReviewDate(recallScore: 100, lastReviewedDate: today, perfectRecallCount: 10)
        XCTAssertTrue(Calendar.current.date(byAdding: .day, value: 120, to: today)! <= perfectRecallDate)
    }
}
