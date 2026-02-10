// NewLearningSheetViewModel.swift - 新規学習4ステップフローのViewModel
import Foundation
import SwiftUI
import CoreData

/// 新規学習フローの状態管理
/// Step 0: タイトル+タグ入力, Step 1: アクティブリコール, Step 2: 理解度評価, Step 3: 保存完了
class NewLearningSheetViewModel: ObservableObject {
    // MARK: - Flow State
    @Published var currentStep: Int = 0
    @Published var isPresented: Bool = false

    // MARK: - Step 0: Input
    @Published var title: String = ""
    @Published var selectedChapter: Int = 0  // 0 = 未選択, 1-30 = 章番号
    @Published var pageStart: Int = 0       // 0 = 未選択
    @Published var pageEnd: Int = 0         // 0 = 未選択

    // MARK: - Title Suggestions
    @Published var titleSuggestions: [String] = []
    @Published var showSuggestions: Bool = false

    // MARK: - Step 1: Active Recall
    @Published var microStep: Int = 0 // 0=読む, 1=閉じる, 2=思い出す, 3=確認
    @Published var elapsedTime: TimeInterval = 0

    // MARK: - Step 2: Assessment
    @Published var recallScore: Int16 = 70
    @Published var selectedReviewDate: Date = Date()
    @Published var defaultReviewDate: Date = Date()
    @Published var showDatePicker: Bool = false

    // MARK: - Step 3: Completion
    @Published var isSaving: Bool = false
    @Published var saveSuccess: Bool = false

    // MARK: - Guide
    @Published var showingGuide: Bool = false

    // MARK: - Private
    private var timer: Timer?
    private var timerStartDate: Date?
    private let viewContext: NSManagedObjectContext

    // MARK: - Computed
    var isTitleValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var microStepLabels: [String] {
        [
            "読む".localized,
            "閉じる".localized,
            "思い出す".localized,
            "確認".localized
        ]
    }

    var currentStepTitle: String {
        switch currentStep {
        case 0: return "学習内容を入力".localized
        case 1: return "アクティブリコール".localized
        case 2: return "理解度の評価".localized
        case 3: return "保存完了".localized
        default: return ""
        }
    }

    var currentStepColor: Color {
        switch currentStep {
        case 0: return .blue
        case 1: return .purple
        case 2: return .orange
        case 3: return .green
        default: return .gray
        }
    }

    var formattedElapsedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Preset Manager
    let presetManager = TitlePresetManager.shared

    // MARK: - Init
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }

    // MARK: - Flow Control

    func present() {
        reset()
        isPresented = true
        fetchTitleSuggestions()
        // 初回ガイド表示
        if !UserDefaults.standard.bool(forKey: "hasSeenActiveRecallGuide") {
            showingGuide = true
        }
    }

    func dismiss() {
        stopTimer()
        isPresented = false
    }

    func proceedToStep1() {
        guard isTitleValid else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = 1
        }
        startTimer()
    }

    func proceedToStep2() {
        stopTimer()
        recalculateReviewDate()
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = 2
        }
    }

    func completeMicroStep() {
        if microStep <= 3 {
            withAnimation(.easeInOut(duration: 0.25)) {
                microStep += 1
            }
        }
    }

    // MARK: - Title Suggestions

    func fetchTitleSuggestions() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Memo")
        request.propertiesToFetch = ["title"]
        request.resultType = .dictionaryResultType
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            let results = try viewContext.fetch(request) as? [[String: Any]] ?? []
            var seen = Set<String>()
            var unique: [String] = []
            for dict in results {
                if let t = dict["title"] as? String,
                   !t.isEmpty,
                   !seen.contains(t) {
                    seen.insert(t)
                    unique.append(t)
                }
            }
            titleSuggestions = unique
        } catch {
            titleSuggestions = []
        }
    }

    func filteredSuggestions(for query: String) -> [String] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return [] }
        return titleSuggestions
            .filter { $0.lowercased().contains(q) }
            .prefix(10)
            .map { $0 }
    }

    func buildPageRangeString() -> String {
        let chapterStr = selectedChapter > 0 ? "第\(selectedChapter)章" : ""

        let pageStr: String
        if pageStart > 0 && pageEnd > 0 {
            pageStr = "p.\(pageStart)-\(pageEnd)"
        } else if pageStart > 0 {
            pageStr = "p.\(pageStart)"
        } else {
            pageStr = ""
        }

        switch (chapterStr.isEmpty, pageStr.isEmpty) {
        case (true, true): return ""
        case (false, true): return chapterStr
        case (true, false): return pageStr
        case (false, false): return "\(chapterStr) \(pageStr)"
        }
    }

    // MARK: - Timer

    func startTimer() {
        timerStartDate = Date()
        elapsedTime = 0
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.timerStartDate else { return }
            DispatchQueue.main.async {
                self.elapsedTime = Date().timeIntervalSince(start)
            }
        }
        if let t = timer {
            RunLoop.main.add(t, forMode: .common)
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Review Date Calculation

    func recalculateReviewDate() {
        let calculatedDate = ReviewCalculator.calculateNextReviewDate(
            recallScore: recallScore,
            lastReviewedDate: Date(),
            perfectRecallCount: 0,
            historyEntries: []
        )
        defaultReviewDate = calculatedDate
        if !showDatePicker {
            selectedReviewDate = calculatedDate
        }
    }

    // MARK: - Save

    func save() async {
        guard isTitleValid, !isSaving else { return }

        await MainActor.run {
            isSaving = true
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = 3
            }
        }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        await MainActor.run {
            let newMemo = Memo(context: viewContext)
            newMemo.id = UUID()
            newMemo.title = trimmedTitle
            newMemo.pageRange = buildPageRangeString()
            newMemo.content = ""
            newMemo.recallScore = recallScore
            newMemo.createdAt = Date()
            newMemo.lastReviewedDate = Date()
            newMemo.nextReviewDate = selectedReviewDate

            // 履歴エントリ
            let historyEntry = MemoHistoryEntry(context: viewContext)
            historyEntry.id = UUID()
            historyEntry.date = Date()
            historyEntry.recallScore = recallScore
            historyEntry.memo = newMemo

            // 学習アクティビティ記録
            let duration = max(Int(elapsedTime), 1)
            let _ = LearningActivity.recordActivityWithPrecision(
                type: .exercise,
                durationSeconds: duration,
                memo: newMemo,
                note: "新規学習: \(trimmedTitle)",
                in: viewContext
            )

            // ストリーク更新
            StreakTracker.shared.checkAndUpdateStreak(in: viewContext)

            do {
                try viewContext.save()
                isSaving = false
                saveSuccess = true

                NotificationCenter.default.post(
                    name: NSNotification.Name("ForceRefreshMemoData"),
                    object: nil
                )

                UINotificationFeedbackGenerator().notificationOccurred(.success)

                // 2秒後に自動閉じ
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    self?.dismiss()
                }
            } catch {
                isSaving = false
                print("新規学習メモの保存に失敗しました: \(error)")
            }
        }
    }

    // MARK: - Reset

    private func reset() {
        currentStep = 0
        title = ""
        selectedChapter = 0
        pageStart = 0
        pageEnd = 0
        showSuggestions = false
        microStep = 0
        elapsedTime = 0
        recallScore = 70
        selectedReviewDate = Date()
        defaultReviewDate = Date()
        showDatePicker = false
        isSaving = false
        saveSuccess = false
        showingGuide = false
    }
}
