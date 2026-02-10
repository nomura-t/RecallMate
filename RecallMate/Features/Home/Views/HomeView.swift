// HomeView.swift - 分散学習に最適化されたUI
import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: - Core State
    @State private var refreshTrigger = UUID()
    @State private var memoToEdit: Memo?
    @State private var showingEditSheet = false
    @State private var showingProfileView = false
    @State private var showingSettingsView = false
    @State private var showCelebration = false
    @State private var previousRemainingCount: Int? = nil
    @State private var showingCalendarSheet = false
    @State private var showingMemoDetail = false
    @State private var selectedMemoForDetail: Memo?
    @State private var totalDueAtStartOfDay: Int = 0
    @State private var pendingEditMemo: Memo?

    // MARK: - ViewModels
    @StateObject private var reviewFlowViewModel: ReviewFlowViewModel
    @StateObject private var newLearningViewModel: NewLearningSheetViewModel
    @StateObject private var authManager = AuthenticationManager.shared
    @EnvironmentObject private var deepLinkManager: DeepLinkManager
    @EnvironmentObject private var appSettings: AppSettings

    // MARK: - Tab State
    @State private var selectedTab: HomeTab = .today

    enum HomeTab: String, CaseIterable {
        case today = "今日"
        case all = "すべて"
    }

    // MARK: - Initialization
    init() {
        let context = PersistenceController.shared.container.viewContext
        self._reviewFlowViewModel = StateObject(wrappedValue: ReviewFlowViewModel(viewContext: context))
        self._newLearningViewModel = StateObject(wrappedValue: NewLearningSheetViewModel(viewContext: context))
    }

    // MARK: - Computed Properties

    /// 今日の復習対象（今日 + 期限超過）
    private var todayDueMemos: [Memo] {
        let fetchRequest: NSFetchRequest<Memo> = Memo.fetchRequest()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = (calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay).addingTimeInterval(-1)

        fetchRequest.predicate = NSPredicate(
            format: "(nextReviewDate >= %@ AND nextReviewDate <= %@) OR (nextReviewDate < %@)",
            startOfDay as NSDate,
            endOfDay as NSDate,
            startOfDay as NSDate
        )
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Memo.nextReviewDate, ascending: true)
        ]

        return (try? viewContext.fetch(fetchRequest)) ?? []
    }

    /// 期限超過メモ
    private var overdueMemos: [Memo] {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return todayDueMemos.filter { memo in
            guard let date = memo.nextReviewDate else { return false }
            return date < startOfToday
        }
    }

    /// 今日のみのメモ
    private var todayOnlyMemos: [Memo] {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return todayDueMemos.filter { memo in
            guard let date = memo.nextReviewDate else { return true }
            return date >= startOfToday
        }
    }

    /// 完了済み件数
    private var completedCount: Int {
        max(totalDueAtStartOfDay - todayDueMemos.count, 0)
    }

    /// 全メモ（nextReviewDate順）
    private var allMemos: [Memo] {
        let fetchRequest: NSFetchRequest<Memo> = Memo.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Memo.nextReviewDate, ascending: true)
        ]
        return (try? viewContext.fetch(fetchRequest)) ?? []
    }

    // MARK: - Main View Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // ストリークバッジ
                    StreakBadge()
                        .padding(.top, 4)

                    // 進捗リング
                    ReviewProgressRing(
                        totalDue: totalDueAtStartOfDay,
                        completed: completedCount
                    )

                    // メイン復習ボタン
                    PrimaryReviewButton(
                        remainingCount: todayDueMemos.count,
                        onStartReview: {
                            if let memo = todayDueMemos.first {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    reviewFlowViewModel.startReview(with: memo)
                                }
                            }
                        }
                    )

                    // 今日/すべて切替ピッカー
                    Picker("", selection: $selectedTab) {
                        ForEach(HomeTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)

                    // メモリスト
                    if selectedTab == .today {
                        if todayDueMemos.isEmpty {
                            EmptyStateView(
                                hasTagFilter: false,
                                onAddMemo: {
                                    newLearningViewModel.present()
                                }
                            )
                        } else {
                            DueMemoList(
                                overdueMemos: overdueMemos,
                                todayMemos: todayOnlyMemos,
                                onTapMemo: { memo in
                                    selectedMemoForDetail = memo
                                    showingMemoDetail = true
                                },
                                onReviewMemo: { memo in
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        reviewFlowViewModel.startReview(with: memo)
                                    }
                                },
                                onDeleteMemo: { memo in
                                    withAnimation(.easeInOut) {
                                        deleteMemo(memo)
                                    }
                                }
                            )
                        }
                    } else {
                        AllMemosList(
                            memos: allMemos,
                            onTapMemo: { memo in
                                selectedMemoForDetail = memo
                                showingMemoDetail = true
                            },
                            onReviewMemo: { memo in
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    reviewFlowViewModel.startReview(with: memo)
                                }
                            },
                            onDeleteMemo: { memo in
                                withAnimation(.easeInOut) {
                                    deleteMemo(memo)
                                }
                            }
                        )
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .refreshable {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    forceRefreshData()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("")
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    profileButton
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    calendarButton
                    addButton
                    settingsButton
                }
            }
        }
        .onAppear {
            forceRefreshData()
            initTotalDue()
            handleDeepLink()
            previousRemainingCount = todayDueMemos.count
        }
        .onReceive(deepLinkManager.$pendingAction) { action in
            if action != nil {
                handleDeepLink()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ForceRefreshMemoData"))) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                forceRefreshData()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                checkCelebration()
            }
        }
        // 復習フロー
        .sheet(isPresented: $reviewFlowViewModel.showingReviewFlow) {
            ReviewFlowSheetView(viewModel: reviewFlowViewModel)
                .alert("長期記憶に定着しました".localized, isPresented: $reviewFlowViewModel.showLongTermMemoryAlert) {
                    Button("削除する".localized, role: .destructive) {
                        reviewFlowViewModel.deleteLongTermMemo()
                    }
                    Button("残す".localized, role: .cancel) {
                        // 閉じるだけ
                    }
                } message: {
                    Text("このメモは4回以上高スコアで復習されました。復習リストから削除しますか？".localized)
                }
        }
        // 新規学習フロー（4ステップ）
        .sheet(isPresented: $newLearningViewModel.isPresented) {
            NewLearningSheet(viewModel: newLearningViewModel)
        }
        // 編集シート
        .sheet(isPresented: $showingEditSheet) {
            if let memo = memoToEdit {
                NavigationView {
                    ContentView(memo: memo)
                        .environmentObject(appSettings)
                        .navigationBarItems(
                            leading: Button("キャンセル") {
                                showingEditSheet = false
                            },
                            trailing: Button("完了") {
                                showingEditSheet = false
                            }
                        )
                }
                .onDisappear {
                    memoToEdit = nil
                    forceRefreshData()
                }
            }
        }
        // カレンダーシート
        .sheet(isPresented: $showingCalendarSheet) {
            CalendarSheet { memo in
                selectedMemoForDetail = memo
                showingMemoDetail = true
            }
        }
        // メモ詳細シート
        .sheet(isPresented: $showingMemoDetail) {
            if let memo = selectedMemoForDetail {
                MemoDetailSheet(
                    memo: memo,
                    onReview: {
                        reviewFlowViewModel.startReview(with: memo)
                    },
                    onEdit: {
                        pendingEditMemo = memo
                    }
                )
            }
        }
        // メモ詳細が閉じた後に編集シートを開く
        .onChange(of: showingMemoDetail) { isShowing in
            if !isShowing, let memo = pendingEditMemo {
                pendingEditMemo = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    editMemo(memo)
                }
            }
        }
        // プロフィール
        .sheet(isPresented: $showingProfileView) {
            ProfileView()
        }
        // 設定
        .sheet(isPresented: $showingSettingsView) {
            SettingsView()
        }
        // セレブレーション
        .overlay {
            if showCelebration {
                CelebrationOverlay(isShowing: $showCelebration)
                    .zIndex(100)
            }
        }
    }

    // MARK: - Toolbar

    private var profileButton: some View {
        Button(action: { showingProfileView = true }) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.blue)
        }
    }

    private var calendarButton: some View {
        Button(action: { showingCalendarSheet = true }) {
            Image(systemName: "calendar")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
        }
    }

    private var addButton: some View {
        Button(action: { newLearningViewModel.present() }) {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.blue)
        }
    }

    private var settingsButton: some View {
        Button(action: { showingSettingsView = true }) {
            Image(systemName: "gearshape")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
        }
    }

    // MARK: - Helper Methods

    private func deleteMemo(_ memo: Memo) {
        viewContext.delete(memo)
        do {
            try viewContext.save()
            NotificationCenter.default.post(name: NSNotification.Name("ForceRefreshMemoData"), object: nil)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } catch {
            print("メモの削除に失敗しました: \(error)")
        }
    }

    private func editMemo(_ memo: Memo) {
        memoToEdit = memo
        showingEditSheet = true
    }

    private func forceRefreshData() {
        viewContext.rollback()
        viewContext.refreshAllObjects()
        refreshTrigger = UUID()
    }

    private func initTotalDue() {
        let key = "totalDueAtStartOfDay_\(Calendar.current.startOfDay(for: Date()).timeIntervalSince1970)"
        let stored = UserDefaults.standard.integer(forKey: key)
        if stored > 0 {
            totalDueAtStartOfDay = stored
        } else {
            let count = todayDueMemos.count
            totalDueAtStartOfDay = count
            UserDefaults.standard.set(count, forKey: key)
        }
    }

    private func handleDeepLink() {
        guard let action = deepLinkManager.consumeAction() else { return }
        switch action {
        case .startReview:
            if let memo = todayDueMemos.first {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    reviewFlowViewModel.startReview(with: memo)
                }
            }
        }
    }

    private func checkCelebration() {
        let currentCount = todayDueMemos.count
        if let prev = previousRemainingCount, prev > 0, currentCount == 0 {
            showCelebration = true
        }
        previousRemainingCount = currentCount
    }
}

// MARK: - Review Flow Sheet View（復習フローシートビュー - 簡素化2ステップ）

/// 復習フロー: Step 0=思い出しプロンプト, Step 1=記憶度評価, Step 2=完了フィードバック
struct ReviewFlowSheetView: View {
    @ObservedObject var viewModel: ReviewFlowViewModel
    @State private var autoDismissTimer: Timer?

    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()

            FlowContainerView {
                VStack(spacing: 0) {
                    // ヘッダー部分
                    FlowHeaderView(
                        currentStep: viewModel.reviewStep,
                        totalSteps: 3,
                        stepTitle: viewModel.currentStepTitle,
                        stepColor: viewModel.currentStepColor,
                        onClose: viewModel.closeReviewFlow
                    )

                    // メインコンテンツ
                    Group {
                        if viewModel.reviewStep == 0 {
                            ActiveRecallStepView(
                                memoTitle: viewModel.currentMemo?.title ?? "無題".localized,
                                microStep: $viewModel.microStep,
                                elapsedTime: viewModel.reviewElapsedTime,
                                onComplete: {
                                    viewModel.stopReviewTimer()
                                    viewModel.proceedToNextStep()
                                }
                            )
                        } else if viewModel.reviewStep == 1 {
                            SimplifiedAssessmentStepView(viewModel: viewModel)
                        } else {
                            EnhancedCompletionStepView(viewModel: viewModel)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .animation(.easeInOut(duration: 0.3), value: viewModel.reviewStep)
                }
            }
        }
        .onAppear {
            viewModel.recalculateReviewDate()
        }
        .onChange(of: viewModel.reviewSaveSuccess) { success in
            if success {
                // 3秒後に自動閉じ
                autoDismissTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                    DispatchQueue.main.async {
                        viewModel.closeReviewFlow()
                    }
                }
            }
        }
        .onDisappear {
            autoDismissTimer?.invalidate()
        }
    }
}

// MARK: - Step 1: 記憶度評価画面（簡素化）

struct SimplifiedAssessmentStepView: View {
    @ObservedObject var viewModel: ReviewFlowViewModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // メモタイトル + コンテキスト情報表示
                    if let memo = viewModel.currentMemo {
                        VStack(spacing: 8) {
                            Text("「\(memo.title ?? "無題")」")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)

                            HStack(spacing: 16) {
                                // ページ範囲
                                if let pageRange = memo.pageRange, !pageRange.isEmpty {
                                    HStack(spacing: 4) {
                                        Image(systemName: "book.pages")
                                            .font(.caption2)
                                        Text(pageRange)
                                            .font(.caption)
                                    }
                                    .foregroundColor(.secondary)
                                }

                                // 前回スコア
                                HStack(spacing: 4) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.caption2)
                                    Text("前回".localized + ": \(Int(viewModel.previousScore))%")
                                        .font(.caption)
                                }
                                .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 8)
                    }

                    // 記憶度スライダー
                    MemoryAssessmentView(
                        score: $viewModel.recallScore,
                        scoreLabel: "記憶度を評価してください".localized,
                        color: getRetentionColor
                    )

                    // 推奨復習日表示
                    reviewDateSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }

            // 復習完了ボタン
            Button(action: {
                Task {
                    await viewModel.completeReview()
                }
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                    Text("復習完了".localized)
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .onChange(of: viewModel.recallScore) { _ in
            viewModel.recalculateReviewDate()
        }
    }

    private var reviewDateSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.indigo)
                Text("次回復習日".localized)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text(formatDateForDisplay(viewModel.selectedReviewDate))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.indigo)
            }

            if viewModel.showDatePicker {
                DatePicker(
                    "",
                    selection: $viewModel.selectedReviewDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(height: 160)

                Button(action: {
                    viewModel.selectedReviewDate = viewModel.defaultReviewDate
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.caption)
                        Text("推奨日に戻す".localized)
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
            }

            Button(action: {
                withAnimation {
                    viewModel.showDatePicker.toggle()
                }
            }) {
                Text(viewModel.showDatePicker ? "閉じる".localized : "日付を変更".localized)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .underline()
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Step 2: 強化版完了画面

struct EnhancedCompletionStepView: View {
    @ObservedObject var viewModel: ReviewFlowViewModel
    @State private var currentStreak: Int16 = 0

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // 完了アイコン
            Image(systemName: viewModel.isSavingReview ? "clock.fill" : "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(viewModel.isSavingReview ? .orange : .green)
                .scaleEffect(viewModel.isSavingReview ? 0.8 : 1.0)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: viewModel.isSavingReview)

            Text(viewModel.isSavingReview ? "保存中...".localized : "復習完了！".localized)
                .font(.title)
                .fontWeight(.bold)

            if let memo = viewModel.currentMemo {
                Text("「\(memo.title ?? "無題")」")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // スコア差分 + 次回復習日
            if viewModel.reviewSaveSuccess {
                VStack(spacing: 16) {
                    // スコア変動
                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Text("前回".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(viewModel.previousScore))%")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        }

                        Image(systemName: "arrow.right")
                            .foregroundColor(.secondary)

                        VStack(spacing: 4) {
                            Text("今回".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(viewModel.recallScore))%")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(getRetentionColor(for: viewModel.recallScore))
                        }

                        Text(viewModel.scoreDiffText)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(viewModel.scoreDiffColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(viewModel.scoreDiffColor.opacity(0.1))
                            .cornerRadius(8)
                    }

                    Divider()

                    // 次回復習日
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.indigo)
                        Text("次回復習日".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatDateForDisplay(viewModel.selectedReviewDate))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.indigo)
                    }

                    // ストリーク表示
                    if currentStreak > 0 {
                        HStack {
                            Text("\(currentStreak)" + "日連続学習中！".localized)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .padding(.horizontal, 20)
                .transition(.scale.combined(with: .opacity))

                Text("自動で閉じます...".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 閉じるボタン（すぐ閉じたい人向け）
            if viewModel.reviewSaveSuccess {
                Button(action: viewModel.closeReviewFlow) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                        Text("閉じる".localized)
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            currentStreak = viewModel.fetchCurrentStreak()
        }
    }
}

