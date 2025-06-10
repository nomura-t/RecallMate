// HomeView.swift - ViewModelリファクタリング後の完全版
import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - Core State（コア状態管理）
    @State private var selectedDate = Date()
    @Binding var isAddingMemo: Bool
    @State private var selectedTags: [Tag] = []
    @State private var refreshTrigger = UUID()
    
    // MARK: - ViewModels（ビジネスロジック層）
    @StateObject private var reviewFlowViewModel: ReviewFlowViewModel
    @StateObject private var newLearningFlowViewModel: NewLearningFlowViewModel
    
    // MARK: - Data Fetching（データ取得）
    @FetchRequest(
        entity: Tag.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)],
        animation: .default)
    private var allTags: FetchedResults<Tag>
    
    // MARK: - Initialization（初期化）
    init(isAddingMemo: Binding<Bool>) {
        self._isAddingMemo = isAddingMemo
        
        let context = PersistenceController.shared.container.viewContext
        self._reviewFlowViewModel = StateObject(wrappedValue: ReviewFlowViewModel(viewContext: context))
        self._newLearningFlowViewModel = StateObject(wrappedValue: NewLearningFlowViewModel(viewContext: context))
    }
    
    // MARK: - Computed Properties（計算プロパティ）
    private var dailyMemos: [Memo] {
        let fetchRequest: NSFetchRequest<Memo> = Memo.fetchRequest()
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-1)
        
        let isToday = calendar.isDateInToday(selectedDate)
        
        if isToday {
            fetchRequest.predicate = NSPredicate(
                format: "(nextReviewDate >= %@ AND nextReviewDate <= %@) OR (nextReviewDate < %@)",
                startOfDay as NSDate,
                endOfDay as NSDate,
                startOfDay as NSDate
            )
        } else {
            fetchRequest.predicate = NSPredicate(
                format: "nextReviewDate >= %@ AND nextReviewDate <= %@",
                startOfDay as NSDate,
                endOfDay as NSDate
            )
        }
        
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Memo.nextReviewDate, ascending: true)
        ]
        
        do {
            var memos = try viewContext.fetch(fetchRequest)
            
            if !selectedTags.isEmpty {
                memos = memos.filter { memo in
                    for tag in selectedTags {
                        if !memo.tagsArray.contains(where: { $0.id == tag.id }) {
                            return false
                        }
                    }
                    return true
                }
            }
            
            return memos
        } catch {
            return []
        }
    }
    
    // MARK: - Main View Body（メインビュー）
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TodayStudyTimeSection()
                
                DatePickerCalendarView(selectedDate: $selectedDate)
                    .padding(.vertical, 16)
                    .background(
                        Rectangle()
                            .fill(Color(.systemBackground))
                            .shadow(
                                color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1),
                                radius: 2,
                                x: 0,
                                y: 1
                            )
                    )
                
                mainContentSection
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .onAppear {
            forceRefreshData()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ForceRefreshMemoData"))) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                forceRefreshData()
            }
        }
        // 復習フローのモーダル表示
        .sheet(isPresented: $reviewFlowViewModel.showingReviewFlow) {
            ReviewFlowSheetView(viewModel: reviewFlowViewModel)
        }
        // 新規学習フローのモーダル表示
        .sheet(isPresented: $newLearningFlowViewModel.showingNewLearningFlow) {
            NewLearningFlowSheetView(viewModel: newLearningFlowViewModel, allTags: Array(allTags))
        }
    }
    
    // MARK: - View Components（ビューコンポーネント）
    
    private var mainContentSection: some View {
        VStack(spacing: 0) {
            if !allTags.isEmpty {
                TagFilterSection(
                    selectedTags: $selectedTags,
                    allTags: Array(allTags)
                )
                .padding(.top, 16)
            }
            
            DayInfoHeaderView(
                selectedDate: selectedDate,
                memoCount: dailyMemos.count,
                selectedTags: selectedTags
            )
            
            if Calendar.current.isDateInToday(selectedDate) {
                NewLearningButtonView(onStartNewLearning: {
                    newLearningFlowViewModel.startNewLearning()
                })
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            
            if dailyMemos.isEmpty {
                EmptyStateView(
                    selectedDate: selectedDate,
                    hasTagFilter: !selectedTags.isEmpty
                )
            } else {
                memoListSection
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.systemGroupedBackground))
    }
    
    private var memoListSection: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(dailyMemos, id: \.id) { memo in
                    ReviewListItemSimplified(
                        memo: memo,
                        selectedDate: selectedDate,
                        onStartReview: {
                            reviewFlowViewModel.startReview(with: memo)
                        },
                        onOpenMemo: {
                            // 詳細画面への遷移処理（必要に応じて実装）
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
        .refreshable {
            forceRefreshData()
        }
    }
    
    // MARK: - Helper Methods（ヘルパーメソッド）
    
    private func forceRefreshData() {
        viewContext.rollback()
        viewContext.refreshAllObjects()
        refreshTrigger = UUID()
    }
}

// MARK: - Review Flow Sheet View（復習フローシートビュー）

/// 復習フロー全体を管理するシートビュー
/// ViewModelから状態を受け取り、各ステップのビューを適切に表示します
struct ReviewFlowSheetView: View {
    @ObservedObject var viewModel: ReviewFlowViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー部分
            HStack {
                Text(viewModel.currentStepTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: viewModel.closeReviewFlow) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // プログレスバー
            HStack(spacing: 8) {
                ForEach(0..<6) { index in
                    Circle()
                        .fill(index <= viewModel.reviewStep ? getReviewStepColor(step: index) : Color.gray.opacity(0.3))
                        .frame(width: index == viewModel.reviewStep ? 12 : 8, height: index == viewModel.reviewStep ? 12 : 8)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.reviewStep)
                }
            }
            .padding(.top, 16)
            
            // メインコンテンツ
            Group {
                if viewModel.reviewStep == 0 {
                    ReviewContentConfirmationStepView(viewModel: viewModel)
                } else if viewModel.reviewStep == 1 {
                    ReviewMethodSelectionStepView(viewModel: viewModel)
                } else if viewModel.reviewStep == 2 {
                    if viewModel.selectedReviewMethod == .assessment {
                        ReviewMemoryAssessmentStepView(viewModel: viewModel)
                    } else {
                        ActiveReviewGuidanceStepView(viewModel: viewModel)
                    }
                } else if viewModel.reviewStep == 3 {
                    ReviewMemoryAssessmentStepView(viewModel: viewModel)
                } else if viewModel.reviewStep == 4 {
                    ReviewDateSelectionStepView(viewModel: viewModel)
                } else if viewModel.reviewStep == 5 {
                    ReviewCompletionStepView(viewModel: viewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .animation(.easeInOut(duration: 0.3), value: viewModel.reviewStep)
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            // 復習日の初期計算
            if let memo = viewModel.currentMemo {
                viewModel.defaultReviewDate = ReviewCalculator.calculateNextReviewDate(
                    recallScore: viewModel.recallScore,
                    lastReviewedDate: Date(),
                    perfectRecallCount: memo.perfectRecallCount
                )
                viewModel.selectedReviewDate = viewModel.defaultReviewDate
            }
        }
    }
    
    private func getReviewStepColor(step: Int) -> Color {
        switch step {
        case 0: return .blue
        case 1: return .purple
        case 2: return viewModel.selectedReviewMethod.color
        case 3: return .orange
        case 4: return .indigo
        case 5: return .green
        default: return .gray
        }
    }
}

// MARK: - New Learning Flow Sheet View（新規学習フローシートビュー）

/// 新規学習フロー全体を管理するシートビュー
struct NewLearningFlowSheetView: View {
    @ObservedObject var viewModel: NewLearningFlowViewModel
    let allTags: [Tag]
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー部分
            HStack {
                Text(viewModel.currentStepTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: viewModel.closeNewLearningFlow) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // プログレスバー
            HStack(spacing: 8) {
                ForEach(0..<6) { index in
                    Circle()
                        .fill(index <= viewModel.newLearningStep ? getNewLearningStepColor(step: index) : Color.gray.opacity(0.3))
                        .frame(width: index == viewModel.newLearningStep ? 12 : 8, height: index == viewModel.newLearningStep ? 12 : 8)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.newLearningStep)
                }
            }
            .padding(.top, 16)
            
            // メインコンテンツ
            Group {
                if viewModel.newLearningStep == 0 {
                    LearningTitleInputStepView(viewModel: viewModel, allTags: allTags)
                } else if viewModel.newLearningStep == 1 {
                    LearningMethodSelectionStepView(viewModel: viewModel)
                } else if viewModel.newLearningStep == 2 {
                    if viewModel.selectedLearningMethod == .recordOnly {
                        NewLearningInitialAssessmentStepView(viewModel: viewModel)
                    } else {
                        ActiveLearningGuidanceStepView(viewModel: viewModel)
                    }
                } else if viewModel.newLearningStep == 3 {
                    NewLearningInitialAssessmentStepView(viewModel: viewModel)
                } else if viewModel.newLearningStep == 4 {
                    NewLearningDateSelectionStepView(viewModel: viewModel)
                } else if viewModel.newLearningStep == 5 {
                    NewLearningCompletionStepView(viewModel: viewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .animation(.easeInOut(duration: 0.3), value: viewModel.newLearningStep)
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            // 初回復習日の初期計算
            viewModel.defaultNewLearningReviewDate = ReviewCalculator.calculateNextReviewDate(
                recallScore: viewModel.newLearningInitialScore,
                lastReviewedDate: Date(),
                perfectRecallCount: 0
            )
            viewModel.selectedNewLearningReviewDate = viewModel.defaultNewLearningReviewDate
        }
    }
    
    private func getNewLearningStepColor(step: Int) -> Color {
        switch step {
        case 0: return .blue
        case 1: return .purple
        case 2: return viewModel.selectedLearningMethod.color
        case 3: return .orange
        case 4: return .indigo
        case 5: return .green
        default: return .gray
        }
    }
}

// MARK: - Review Flow Step Views（復習フローステップビュー）

/// ステップ0: 復習内容確認画面
struct ReviewContentConfirmationStepView: View {
    @ObservedObject var viewModel: ReviewFlowViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let memo = viewModel.currentMemo {
                    VStack(spacing: 16) {
                        VStack(spacing: 16) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            
                            Text("復習する内容を確認しましょう")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("復習対象")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text(memo.title ?? "無題")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                
                                if let pageRange = memo.pageRange, !pageRange.isEmpty {
                                    Text("ページ: \(pageRange)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Divider()
                                    .padding(.vertical, 8)
                                
                                Text("💡 復習のコツ")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                                
                                Text("効果的な復習のために、まず内容をざっと見直して全体像を思い出しましょう。その後、実際に思い出す練習（アクティブリコール）を行うことで、記憶がより強化されます。")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(12)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                
                                if let content = memo.content, !content.isEmpty {
                                    Divider()
                                        .padding(.vertical, 8)
                                    
                                    Text(content)
                                        .font(.body)
                                        .lineSpacing(4)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                
                Spacer(minLength: 40)
                
                Button(action: {
                    viewModel.proceedToNextStep()
                }) {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 18))
                        Text("内容を確認しました")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 20)
        }
    }
}

/// ステップ1: 復習方法選択画面
struct ReviewMethodSelectionStepView: View {
    @ObservedObject var viewModel: ReviewFlowViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    if let memo = viewModel.currentMemo {
                        Text("「\(memo.title ?? "無題")」")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    
                    Text("どのように復習しますか？")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 16) {
                    ForEach(ReviewMethod.allCases, id: \.self) { method in
                        ReviewMethodCard(
                            method: method,
                            isSelected: viewModel.selectedReviewMethod == method,
                            onSelect: {
                                viewModel.selectedReviewMethod = method
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 40)
                
                Button(action: {
                    if viewModel.selectedReviewMethod == .assessment {
                        viewModel.jumpToStep(3)  // 記憶度評価ステップへ直接進む
                    } else {
                        viewModel.activeReviewStep = 0
                        viewModel.startReviewTimer()
                        viewModel.proceedToNextStep()  // アクティブリコール指導ステップへ
                    }
                }) {
                    HStack {
                        Image(systemName: viewModel.selectedReviewMethod == .assessment ? "arrow.right.circle.fill" : "play.circle.fill")
                            .font(.system(size: 18))
                        Text(viewModel.selectedReviewMethod == .assessment ? "記憶度を評価する" : "復習スタート！")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [viewModel.selectedReviewMethod.color, viewModel.selectedReviewMethod.color.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .padding(.top, 20)
        }
    }
}

/// ステップ2: アクティブリコール復習指導画面
struct ActiveReviewGuidanceStepView: View {
    @ObservedObject var viewModel: ReviewFlowViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            LearningTimer(
                startTime: viewModel.activeReviewStartTime,
                color: viewModel.selectedReviewMethod.color,
                isActive: viewModel.showingReviewFlow && viewModel.reviewStep == 2
            )
            .padding(.top, 20)
            
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.selectedReviewMethod == .thorough {
                        ActiveRecallGuidanceContent(
                            steps: getThoroughReviewSteps(),
                            currentStep: viewModel.activeReviewStep,
                            methodColor: viewModel.selectedReviewMethod.color
                        )
                    } else {
                        ActiveRecallGuidanceContent(
                            steps: getQuickReviewSteps(),
                            currentStep: viewModel.activeReviewStep,
                            methodColor: viewModel.selectedReviewMethod.color
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                if viewModel.activeReviewStep < (viewModel.selectedReviewMethod == .thorough ? 3 : 2) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.activeReviewStep += 1
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 18))
                            Text("次のステップへ")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [viewModel.selectedReviewMethod.color, viewModel.selectedReviewMethod.color.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                    }
                } else {
                    Button(action: {
                        viewModel.proceedToNextStep()  // 記憶度評価ステップへ
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                            Text("復習完了！")
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
                }
                
                Button(action: {
                    viewModel.proceedToNextStep()  // 記憶度評価ステップへ
                }) {
                    Text("復習をスキップして評価に進む")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .underline()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
}

/// ステップ3: 記憶度評価画面
struct ReviewMemoryAssessmentStepView: View {
    @ObservedObject var viewModel: ReviewFlowViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Text("復習後の記憶度を評価してください")
                    .font(.title3)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2), lineWidth: 12)
                        .frame(width: 180, height: 180)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.recallScore) / 100)
                        .stroke(
                            getRetentionColor(for: viewModel.recallScore),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 180, height: 180)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: viewModel.recallScore)
                    
                    VStack(spacing: 4) {
                        Text("\(Int(viewModel.recallScore))")
                            .font(.system(size: 48, weight: .bold))
                        Text("%")
                            .font(.system(size: 20))
                    }
                    .foregroundColor(getRetentionColor(for: viewModel.recallScore))
                }
                
                Text(getRetentionDescription(for: viewModel.recallScore))
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(getRetentionColor(for: viewModel.recallScore))
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.recallScore)
                
                VStack(spacing: 16) {
                    HStack {
                        Text("0%")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Slider(value: Binding(
                            get: { Double(viewModel.recallScore) },
                            set: { newValue in
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                viewModel.recallScore = Int16(newValue)
                            }
                        ), in: 0...100, step: 1)
                        .accentColor(getRetentionColor(for: viewModel.recallScore))
                        
                        Text("100%")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    HStack(spacing: 0) {
                        ForEach(0..<5) { i in
                            let level = i * 20
                            let isActive = viewModel.recallScore >= Int16(level)
                            
                            Rectangle()
                                .fill(isActive ? getRetentionColorForLevel(i) : Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2))
                                .frame(height: 6)
                                .cornerRadius(3)
                        }
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                viewModel.proceedToNextStep()  // 復習日選択ステップへ
            }) {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 18))
                    Text("評価完了")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            getRetentionColor(for: viewModel.recallScore),
                            getRetentionColor(for: viewModel.recallScore).opacity(0.8)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
}

/// ステップ4: 復習日選択画面
struct ReviewDateSelectionStepView: View {
    @ObservedObject var viewModel: ReviewFlowViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 60))
                    .foregroundColor(.indigo)
                
                Text("次回の復習日を選択してください")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                if let memo = viewModel.currentMemo {
                    Text("「\(memo.title ?? "無題")」")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.blue)
                        .font(.system(size: 16))
                    
                    Text("記憶度 \(Int(viewModel.recallScore))% に基づく推奨復習日")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                Text(getReviewDateExplanation(for: viewModel.recallScore))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 8)
            }
            .padding(16)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                Text("復習日を選択")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                DatePicker(
                    "復習日",
                    selection: $viewModel.selectedReviewDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(height: 200)
                
                Button(action: {
                    viewModel.selectedReviewDate = viewModel.defaultReviewDate
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14))
                        Text("推奨日に戻す")
                            .font(.subheadline)
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            Button(action: {
                viewModel.proceedToNextStep()  // 完了ステップへ
            }) {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 18))
                    Text("復習日を設定")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.indigo, Color.indigo.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
}

/// ステップ5: 復習完了画面
struct ReviewCompletionStepView: View {
    @ObservedObject var viewModel: ReviewFlowViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 20)
                
                VStack(spacing: 24) {
                    Image(systemName: viewModel.isSavingReview ? "clock.fill" : (viewModel.reviewSaveSuccess ? "checkmark.circle.fill" : "sparkles"))
                        .font(.system(size: 80))
                        .foregroundColor(viewModel.isSavingReview ? .orange : (viewModel.reviewSaveSuccess ? .green : viewModel.selectedReviewMethod.color))
                        .scaleEffect(viewModel.isSavingReview ? 0.8 : 1.0)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: viewModel.isSavingReview)
                    
                    Text(viewModel.isSavingReview ? "保存中..." : (viewModel.reviewSaveSuccess ? "復習完了！" : "復習完了"))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if let memo = viewModel.currentMemo {
                        Text("「\(memo.title ?? "無題")」")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                    }
                    
                    HStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Text("記憶度")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(Int(viewModel.recallScore))%")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(getRetentionColor(for: viewModel.recallScore))
                        }
                        
                        VStack(spacing: 4) {
                            Text("次回復習日")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(formatDateForDisplay(viewModel.selectedReviewDate))
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6).opacity(0.5))
                    )
                    
                    if viewModel.selectedReviewMethod != .assessment {
                        Text("復習時間: \(formatElapsedTime(viewModel.reviewElapsedTime))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if viewModel.reviewSaveSuccess {
                        Text("復習結果が正常に保存されました")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .padding(.top, 8)
                    }
                }
                
                Spacer()
                    .frame(minHeight: 40)
            }
            .padding(.horizontal, 20)
        }
        
        VStack {
            Spacer()
            
            if !viewModel.reviewSaveSuccess {
                Button(action: {
                    Task {
                        await viewModel.executeReviewCompletion()
                    }
                }) {
                    HStack {
                        if viewModel.isSavingReview {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "sparkles")
                                .font(.system(size: 18))
                        }
                        
                        Text(viewModel.isSavingReview ? "保存中..." : "復習を完了する")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [viewModel.selectedReviewMethod.color, viewModel.selectedReviewMethod.color.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .disabled(viewModel.isSavingReview)
                }
                .padding(.horizontal, 20)
            } else {
                Button(action: viewModel.closeReviewFlow) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                        Text("確認完了")
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
            }
        }
        .padding(.bottom, 20)
    }
}

// MARK: - New Learning Flow Step Views（新規学習フローステップビュー）

/// ステップ0: 学習タイトル入力画面
struct LearningTitleInputStepView: View {
    @ObservedObject var viewModel: NewLearningFlowViewModel
    let allTags: [Tag]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("今日は何を学習しますか？")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        Text("学習内容のタイトルを入力してください")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("学習タイトル（必須）")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            TextField("例: 英単語の暗記、数学の微分積分", text: $viewModel.newLearningTitle)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.body)
                        }
                        
                        if !allTags.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("タグ（任意）")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(allTags) { tag in
                                            Button(action: {
                                                viewModel.toggleTag(tag)
                                            }) {
                                                HStack(spacing: 4) {
                                                    Circle()
                                                        .fill(tag.swiftUIColor())
                                                        .frame(width: 8, height: 8)
                                                    
                                                    Text(tag.name ?? "")
                                                        .font(.subheadline)
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(
                                                    viewModel.newLearningTags.contains(where: { $0.id == tag.id })
                                                    ? tag.swiftUIColor().opacity(0.2)
                                                    : Color.gray.opacity(0.15)
                                                )
                                                .foregroundColor(
                                                    viewModel.newLearningTags.contains(where: { $0.id == tag.id })
                                                    ? tag.swiftUIColor()
                                                    : .primary
                                                )
                                                .cornerRadius(16)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                                
                                if !viewModel.newLearningTags.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("選択中のタグ:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 8) {
                                                ForEach(viewModel.newLearningTags) { tag in
                                                    HStack(spacing: 4) {
                                                        Circle()
                                                            .fill(tag.swiftUIColor())
                                                            .frame(width: 6, height: 6)
                                                        
                                                        Text(tag.name ?? "")
                                                            .font(.caption)
                                                        
                                                        Button(action: {
                                                            viewModel.removeTag(tag)
                                                        }) {
                                                            Image(systemName: "xmark.circle.fill")
                                                                .font(.system(size: 12))
                                                                .foregroundColor(.gray)
                                                        }
                                                        .buttonStyle(PlainButtonStyle())
                                                    }
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(tag.swiftUIColor().opacity(0.1))
                                                    .cornerRadius(10)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(24)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.proceedToNextStep()
                }) {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 18))
                        Text("学習方法を選択する")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                .disabled(!viewModel.isInputValid)
            }
            .padding(.top, 20)
        }
    }
}

/// ステップ1: 学習方法選択画面
struct LearningMethodSelectionStepView: View {
    @ObservedObject var viewModel: NewLearningFlowViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Text("「\(viewModel.newLearningTitle)」")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text("どのように学習しますか？")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 16) {
                    ForEach(LearningMethod.allCases, id: \.self) { method in
                        LearningMethodCard(
                            method: method,
                            isSelected: viewModel.selectedLearningMethod == method,
                            onSelect: {
                                viewModel.selectedLearningMethod = method
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 40)
                
                Button(action: {
                    if viewModel.selectedLearningMethod == .recordOnly {
                        viewModel.jumpToStep(3)  // 理解度評価ステップへ直接進む
                    } else {
                        viewModel.activeRecallStep = 0
                        viewModel.startLearningTimer()
                        viewModel.proceedToNextStep()  // アクティブリコール指導ステップへ
                    }
                }) {
                    HStack {
                        Image(systemName: viewModel.selectedLearningMethod == .recordOnly ? "arrow.right.circle.fill" : "play.circle.fill")
                            .font(.system(size: 18))
                        Text(viewModel.selectedLearningMethod == .recordOnly ? "理解度を評価する" : "学習スタート！")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [viewModel.selectedLearningMethod.color, viewModel.selectedLearningMethod.color.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .padding(.top, 20)
        }
    }
}

/// ステップ2: アクティブリコール学習指導画面
struct ActiveLearningGuidanceStepView: View {
    @ObservedObject var viewModel: NewLearningFlowViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            LearningTimer(
                startTime: viewModel.activeRecallStartTime,
                color: viewModel.selectedLearningMethod.color,
                isActive: viewModel.showingNewLearningFlow && viewModel.newLearningStep == 2
            )
            .padding(.top, 20)
            
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.selectedLearningMethod == .thorough {
                        ActiveRecallGuidanceContent(
                            steps: getThoroughLearningSteps(),
                            currentStep: viewModel.activeRecallStep,
                            methodColor: viewModel.selectedLearningMethod.color
                        )
                    } else {
                        ActiveRecallGuidanceContent(
                            steps: getQuickLearningSteps(),
                            currentStep: viewModel.activeRecallStep,
                            methodColor: viewModel.selectedLearningMethod.color
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                if viewModel.activeRecallStep < (viewModel.selectedLearningMethod == .thorough ? 3 : 2) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.activeRecallStep += 1
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 18))
                            Text("次のステップへ")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [viewModel.selectedLearningMethod.color, viewModel.selectedLearningMethod.color.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                    }
                } else {
                    Button(action: {
                        viewModel.proceedToNextStep()  // 理解度評価ステップへ
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                            Text("学習完了！")
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
                }
                
                Button(action: {
                    viewModel.proceedToNextStep()  // 理解度評価ステップへ
                }) {
                    Text("学習をスキップして評価に進む")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .underline()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
}

/// ステップ3: 理解度評価画面
struct NewLearningInitialAssessmentStepView: View {
    @ObservedObject var viewModel: NewLearningFlowViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Text("学習内容の理解度を評価してください")
                    .font(.title3)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2), lineWidth: 12)
                        .frame(width: 180, height: 180)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.newLearningInitialScore) / 100)
                        .stroke(
                            getRetentionColor(for: viewModel.newLearningInitialScore),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 180, height: 180)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: viewModel.newLearningInitialScore)
                    
                    VStack(spacing: 4) {
                        Text("\(Int(viewModel.newLearningInitialScore))")
                            .font(.system(size: 48, weight: .bold))
                        Text("%")
                            .font(.system(size: 20))
                    }
                    .foregroundColor(getRetentionColor(for: viewModel.newLearningInitialScore))
                }
                
                Text(getRetentionDescription(for: viewModel.newLearningInitialScore))
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(getRetentionColor(for: viewModel.newLearningInitialScore))
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.newLearningInitialScore)
                
                VStack(spacing: 16) {
                    HStack {
                        Text("0%")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Slider(value: Binding(
                            get: { Double(viewModel.newLearningInitialScore) },
                            set: { newValue in
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                viewModel.newLearningInitialScore = Int16(newValue)
                            }
                        ), in: 0...100, step: 1)
                        .accentColor(getRetentionColor(for: viewModel.newLearningInitialScore))
                        
                        Text("100%")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                viewModel.proceedToNextStep()  // 復習日選択ステップへ
            }) {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 18))
                    Text("評価完了")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            getRetentionColor(for: viewModel.newLearningInitialScore),
                            getRetentionColor(for: viewModel.newLearningInitialScore).opacity(0.8)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
}

/// ステップ4: 復習日選択画面（新規学習用）
struct NewLearningDateSelectionStepView: View {
    @ObservedObject var viewModel: NewLearningFlowViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(.indigo)
                
                Text("初回復習日を選択してください")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("「\(viewModel.newLearningTitle)」")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 16))
                    
                    Text("理解度 \(Int(viewModel.newLearningInitialScore))% に基づく推奨復習日")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                Text(getInitialReviewDateExplanation(for: viewModel.newLearningInitialScore))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 8)
            }
            .padding(16)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                Text("復習日を選択")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                DatePicker(
                    "復習日",
                    selection: $viewModel.selectedNewLearningReviewDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(height: 200)
                
                Button(action: {
                    viewModel.selectedNewLearningReviewDate = viewModel.defaultNewLearningReviewDate
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14))
                        Text("推奨日に戻す")
                            .font(.subheadline)
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            Button(action: {
                viewModel.proceedToNextStep()  // 完了ステップへ
            }) {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 18))
                    Text("復習日を設定")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.indigo, Color.indigo.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
}

/// ステップ5: 学習記録完了画面
struct NewLearningCompletionStepView: View {
    @ObservedObject var viewModel: NewLearningFlowViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 20)
                
                VStack(spacing: 24) {
                    Image(systemName: viewModel.isSavingNewLearning ? "clock.fill" : (viewModel.newLearningSaveSuccess ? "checkmark.circle.fill" : "brain.head.profile"))
                        .font(.system(size: 80))
                        .foregroundColor(viewModel.isSavingNewLearning ? .orange : (viewModel.newLearningSaveSuccess ? .green : viewModel.selectedLearningMethod.color))
                        .scaleEffect(viewModel.isSavingNewLearning ? 0.8 : 1.0)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: viewModel.isSavingNewLearning)
                    
                    Text(viewModel.isSavingNewLearning ? "保存中..." : (viewModel.newLearningSaveSuccess ? "学習記録完了！" : "新規学習完了"))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("タイトル: \(viewModel.newLearningTitle)")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Text("初期理解度")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(Int(viewModel.newLearningInitialScore))%")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(getRetentionColor(for: viewModel.newLearningInitialScore))
                        }
                        
                        VStack(spacing: 4) {
                            Text("初回復習日")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(formatDateForDisplay(viewModel.selectedNewLearningReviewDate))
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6).opacity(0.5))
                    )
                    
                    if viewModel.selectedLearningMethod != .recordOnly {
                        Text("学習時間: \(formatElapsedTime(viewModel.learningElapsedTime))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if viewModel.newLearningSaveSuccess {
                        Text("学習記録が正常に保存されました")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .padding(.top, 8)
                    }
                }
                
                Spacer()
                    .frame(minHeight: 40)
            }
            .padding(.horizontal, 20)
        }
        
        VStack {
            Spacer()
            
            if !viewModel.newLearningSaveSuccess {
                Button(action: {
                    Task {
                        await viewModel.executeNewLearningCompletion()
                    }
                }) {
                    HStack {
                        if viewModel.isSavingNewLearning {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 18))
                        }
                        
                        Text(viewModel.isSavingNewLearning ? "保存中..." : "学習記録を保存する")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [viewModel.selectedLearningMethod.color, viewModel.selectedLearningMethod.color.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .disabled(viewModel.isSavingNewLearning)
                }
                .padding(.horizontal, 20)
            } else {
                Button(action: viewModel.closeNewLearningFlow) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                        Text("確認完了")
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
            }
        }
        .padding(.bottom, 20)
    }
}

// MARK: - Supporting View Components（サポートビューコンポーネント）

struct TagFilterSection: View {
    @Binding var selectedTags: [Tag]
    let allTags: [Tag]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button(action: {
                        selectedTags = []
                    }) {
                        Text("すべて")
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedTags.isEmpty ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(selectedTags.isEmpty ? .white : .primary)
                            .cornerRadius(16)
                    }
                    
                    ForEach(allTags, id: \.id) { tag in
                        TagFilterButton(
                            tag: tag,
                            isSelected: selectedTags.contains(where: { $0.id == tag.id }),
                            onToggle: { toggleTag(tag) }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
            
            if !selectedTags.isEmpty {
                SelectedTagsView(
                    selectedTags: selectedTags,
                    onClearAll: { selectedTags = [] }
                )
                .padding(.horizontal, 16)
            }
        }
    }
    
    private func toggleTag(_ tag: Tag) {
        if let index = selectedTags.firstIndex(where: { $0.id == tag.id }) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
        }
    }
}

struct TagFilterButton: View {
    let tag: Tag
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 4) {
                Circle()
                    .fill(tag.swiftUIColor())
                    .frame(width: 8, height: 8)
                
                Text(tag.name ?? "")
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isSelected
                ? tag.swiftUIColor().opacity(0.2)
                : Color.gray.opacity(0.15)
            )
            .foregroundColor(
                isSelected
                ? tag.swiftUIColor()
                : .primary
            )
            .cornerRadius(16)
        }
    }
}

struct SelectedTagsView: View {
    let selectedTags: [Tag]
    let onClearAll: () -> Void
    
    var body: some View {
        HStack {
            Text(selectedTags.count == 1 ? "フィルター:" : "フィルター（すべてを含む）:")
                .font(.caption)
                .foregroundColor(.gray)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(selectedTags, id: \.id) { tag in
                        HStack(spacing: 2) {
                            Circle()
                                .fill(tag.swiftUIColor())
                                .frame(width: 6, height: 6)
                            
                            Text(tag.name ?? "")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(tag.swiftUIColor().opacity(0.1))
                        .cornerRadius(10)
                    }
                }
            }
            .frame(height: 20)
            
            Button(action: onClearAll) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
    }
}

// MARK: - Method Selection Cards（方法選択カード）

struct ReviewMethodCard: View {
    let method: ReviewMethod
    let isSelected: Bool
    let onSelect: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                Image(systemName: method.icon)
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? .white : method.color)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(isSelected ? method.color : method.color.opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(method.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(method.description)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                        .lineLimit(2)
                    
                    Text(method.detail)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .lineLimit(3)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : method.color)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? method.color : (colorScheme == .dark ? Color(.systemGray6) : Color.white))
                    .shadow(
                        color: isSelected ? method.color.opacity(0.3) : Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05),
                        radius: isSelected ? 8 : 2,
                        x: 0,
                        y: isSelected ? 4 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LearningMethodCard: View {
    let method: LearningMethod
    let isSelected: Bool
    let onSelect: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                Image(systemName: method.icon)
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? .white : method.color)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(isSelected ? method.color : method.color.opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(method.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(method.description)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                        .lineLimit(2)
                    
                    Text(method.detail)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .lineLimit(3)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : method.color)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? method.color : (colorScheme == .dark ? Color(.systemGray6) : Color.white))
                    .shadow(
                        color: isSelected ? method.color.opacity(0.3) : Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05),
                        radius: isSelected ? 8 : 2,
                        x: 0,
                        y: isSelected ? 4 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Active Recall Components（アクティブリコールコンポーネント）

struct ActiveRecallStep {
    let title: String
    let description: String
    let tip: String
    let icon: String
    let color: Color
}

struct ActiveRecallGuidanceContent: View {
    let steps: [ActiveRecallStep]
    let currentStep: Int
    let methodColor: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            if currentStep < steps.count {
                let step = steps[currentStep]
                
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: step.icon)
                            .font(.system(size: 24))
                            .foregroundColor(step.color)
                        
                        Text("ステップ \(currentStep + 1)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(step.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(step.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Text(step.tip)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .padding(12)
                            .background(step.color.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                        .shadow(
                            color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05),
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                )
            }
            
            HStack(spacing: 12) {
                ForEach(0..<steps.count, id: \.self) { index in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(index <= currentStep ? methodColor : Color.gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                        
                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(index < currentStep ? methodColor : Color.gray.opacity(0.3))
                                .frame(height: 2)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("学習の流れ")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(spacing: 8) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(spacing: 12) {
                            Image(systemName: step.icon)
                                .font(.system(size: 16))
                                .foregroundColor(index <= currentStep ? step.color : Color.gray.opacity(0.6))
                                .frame(width: 24)
                            
                            Text(step.title)
                                .font(.subheadline)
                                .foregroundColor(index <= currentStep ? .primary : .secondary)
                                .strikethrough(index < currentStep)
                            
                            Spacer()
                            
                            if index < currentStep {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12))
                                    .foregroundColor(.green)
                            } else if index == currentStep {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(methodColor)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6).opacity(0.5))
            )
        }
    }
}

// MARK: - Helper Functions（ヘルパー関数）

private func getRetentionColor(for score: Int16) -> Color {
    switch score {
    case 81...100: return Color(red: 0.0, green: 0.7, blue: 0.3)
    case 61...80: return Color(red: 0.3, green: 0.7, blue: 0.0)
    case 41...60: return Color(red: 0.95, green: 0.6, blue: 0.1)
    case 21...40: return Color(red: 0.9, green: 0.45, blue: 0.0)
    default: return Color(red: 0.9, green: 0.2, blue: 0.2)
    }
}

private func getRetentionColorForLevel(_ level: Int) -> Color {
    switch level {
    case 4: return Color(red: 0.0, green: 0.7, blue: 0.3)
    case 3: return Color(red: 0.3, green: 0.7, blue: 0.0)
    case 2: return Color(red: 0.95, green: 0.6, blue: 0.1)
    case 1: return Color(red: 0.9, green: 0.45, blue: 0.0)
    default: return Color(red: 0.9, green: 0.2, blue: 0.2)
    }
}

private func getRetentionDescription(for score: Int16) -> String {
    switch score {
    case 91...100: return "完璧に覚えています！"
    case 81...90: return "十分に理解できています"
    case 71...80: return "だいたい理解しています"
    case 61...70: return "要点は覚えています"
    case 51...60: return "基本概念を思い出せます"
    case 41...50: return "断片的に覚えています"
    case 31...40: return "うっすらと覚えています"
    case 21...30: return "ほとんど忘れています"
    case 1...20: return "ほぼ完全に忘れています"
    default: return "全く覚えていません"
    }
}

private func formatElapsedTime(_ timeInterval: TimeInterval) -> String {
    let totalSeconds = Int(timeInterval)
    let minutes = totalSeconds / 60
    let seconds = totalSeconds % 60
    return String(format: "%02d:%02d", minutes, seconds)
}

private func formatDateForDisplay(_ date: Date) -> String {
    let calendar = Calendar.current
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ja_JP")
    formatter.timeZone = TimeZone.current
    
    if calendar.isDateInToday(date) {
        return "今日"
    } else if calendar.isDateInTomorrow(date) {
        return "明日"
    } else {
        let daysFromNow = calendar.dateComponents([.day], from: Date(), to: date).day ?? 0
        
        if daysFromNow <= 7 {
            formatter.dateFormat = "E曜日"
            return formatter.string(from: date)
        } else if daysFromNow <= 30 {
            formatter.dateFormat = "M月d日"
            return formatter.string(from: date)
        } else {
            formatter.dateFormat = "M月d日"
            let dateString = formatter.string(from: date)
            return "\(dateString) (\(daysFromNow)日後)"
        }
    }
}

private func getReviewDateExplanation(for score: Int16) -> String {
    switch score {
    case 90...100:
        return "優秀な記憶度のため、長めの間隔での復習が効果的です。忘却曲線に基づいて最適な復習タイミングを提案しています。"
    case 80...89:
        return "良好な記憶度です。記憶の定着を確実にするため、適度な間隔での復習を推奨します。"
    case 70...79:
        return "基本的な理解は十分です。記憶を強化するため、やや短めの間隔での復習が効果的です。"
    case 60...69:
        return "要点は理解されています。確実な定着のため、比較的短い間隔での復習をお勧めします。"
    case 50...59:
        return "基礎的な理解があります。記憶の定着を図るため、短い間隔での復習が必要です。"
    default:
        return "記憶を強化するため、短期間での復習を推奨します。繰り返し学習により確実な定着を目指しましょう。"
    }
}

private func getInitialReviewDateExplanation(for score: Int16) -> String {
    switch score {
    case 90...100:
        return "非常に高い理解度です。エビングハウスの忘却曲線を考慮し、効率的な復習間隔を設定しています。"
    case 80...89:
        return "良好な理解度です。分散学習の効果を最大化するため、科学的根拠に基づいた復習スケジュールを提案します。"
    case 70...79:
        return "基本的な理解は十分です。記憶の定着を確実にするため、適切な間隔での初回復習を設定しています。"
    case 60...69:
        return "要点は理解されています。長期記憶への移行を促進するため、最適なタイミングでの復習を推奨します。"
    case 50...59:
        return "基礎的な理解があります。忘却を防ぐため、比較的早めの復習スケジュールを設定しています。"
    default:
        return "学習内容の定着には反復が重要です。短い間隔での復習から始めて徐々に記憶を強化していきます。"
    }
}

private func getThoroughReviewSteps() -> [ActiveRecallStep] {
    return [
        ActiveRecallStep(
            title: "以前学んだ内容を思い出してみましょう",
            description: "教材を見る前に、まず記憶している内容を思い出してください",
            tip: "🧠 復習のコツ：何も見ずに思い出すことで、現在の記憶状態を正確に把握できます。思い出せない部分があっても心配しないでください。それが復習すべきポイントです。",
            icon: "brain.head.profile",
            color: .blue
        ),
        ActiveRecallStep(
            title: "思い出した内容を整理してみましょう",
            description: "覚えている内容を体系的に書き出してください",
            tip: "📝 整理の効果：思い出した内容を整理することで、知識の構造が明確になり、記憶がより強化されます。",
            icon: "square.and.pencil",
            color: .green
        ),
        ActiveRecallStep(
            title: "忘れていた部分を確認しましょう",
            description: "教材を見て、思い出せなかった部分を重点的に確認してください",
            tip: "🔍 重点復習：忘れていた部分こそが、今回の復習で最も重要な学習ポイントです。ここに時間をかけることで効率的に記憶を回復できます。",
            icon: "magnifyingglass",
            color: .orange
        ),
        ActiveRecallStep(
            title: "全体を通して再度思い出してみましょう",
            description: "確認した内容も含めて、全体を再度思い出してください",
            tip: "🎯 完全復習：最初から最後まで通して思い出すことで、知識が体系的に整理され、長期記憶への定着が促進されます。",
            icon: "arrow.clockwise",
            color: .purple
        )
    ]
}

private func getQuickReviewSteps() -> [ActiveRecallStep] {
    return [
        ActiveRecallStep(
            title: "重要ポイントを思い出してみましょう",
            description: "この内容の要点だけを思い出してください",
            tip: "⚡ 効率復習：全てを思い出そうとせず、重要なポイントに絞って復習しましょう。短時間でも効果的な復習ができます。",
            icon: "star.fill",
            color: .orange
        ),
        ActiveRecallStep(
            title: "思い出せない部分をチェックしましょう",
            description: "重要だけど思い出せなかった部分を確認してください",
            tip: "🎯 ピンポイント復習：思い出せなかった重要ポイントだけを集中的に確認することで、効率的に記憶を補強できます。",
            icon: "checkmark.circle",
            color: .green
        ),
        ActiveRecallStep(
            title: "キーポイントを再確認しましょう",
            description: "確認したキーポイントをもう一度思い出してください",
            tip: "🔄 確実な定着：重要ポイントを再度思い出すことで、短時間でも確実な記憶定着を図ることができます。",
            icon: "arrow.clockwise",
            color: .blue
        )
    ]
}

private func getThoroughLearningSteps() -> [ActiveRecallStep] {
    return [
        ActiveRecallStep(
            title: "教材をしっかり読み込みましょう",
            description: "まずは学習内容をじっくりと読み込んでください",
            tip: "💡 ポイント：ただ読むだけでなく、『これは重要そうだな』『ここは覚えておきたい』と意識しながら読むと効果的です。アクティブリコールの準備段階として、しっかりと内容を頭に入れましょう。",
            icon: "book.fill",
            color: .blue
        ),
        ActiveRecallStep(
            title: "思い出せるだけ書き出してみましょう",
            description: "教材を閉じて、覚えている内容を書き出してください",
            tip: "🧠 コツ：完璧を目指さなくて大丈夫！思い出せない部分があることで、脳は『これは重要な情報だ』と認識し、次回の記憶定着が向上します。これがアクティブリコールの核心部分です。",
            icon: "pencil.and.outline",
            color: .green
        ),
        ActiveRecallStep(
            title: "分からなかった部分を確認しましょう",
            description: "教材を見直して、思い出せなかった部分を確認してください",
            tip: "🔍 重要：思い出せなかった部分こそが、あなたの記憶の弱点です。ここをしっかり確認することで、次回は思い出せるようになります。",
                        icon: "magnifyingglass",
                        color: .orange
                    ),
                    ActiveRecallStep(
                        title: "わからなかった部分を再度書き出してみましょう",
                        description: "確認した内容を、再度思い出して書き出してください",
                        tip: "🎯 最終確認：一度確認した内容を再度思い出すことで、記憶がより強固になります。この繰り返しが長期記憶への定着につながります。",
                        icon: "arrow.clockwise",
                        color: .purple
                    )
                ]
            }

            private func getQuickLearningSteps() -> [ActiveRecallStep] {
                return [
                    ActiveRecallStep(
                        title: "教材をざっと眺めてみましょう",
                        description: "学習内容を軽く読み通してください",
                        tip: "⚡ さくっとモード：重要そうな部分に注目しながら、全体的な流れを把握しましょう。完璧でなくても大丈夫です。",
                        icon: "eye",
                        color: .orange
                    ),
                    ActiveRecallStep(
                        title: "思い出せるだけ書き出してみましょう",
                        description: "教材を閉じて、覚えている内容を書き出してください",
                        tip: "🧠 効率重視：時間は短くても、思い出す作業が記憶を強化します。思い出せた分だけでも十分効果的です。",
                        icon: "pencil.and.outline",
                        color: .green
                    ),
                    ActiveRecallStep(
                        title: "気になった部分だけ確認してみましょう",
                        description: "特に重要だと感じた部分や、思い出しにくかった部分を確認してください",
                        tip: "🎯 重点確認：全てを確認する必要はありません。重要な部分や不安な部分に絞って確認することで、効率的に学習できます。",
                        icon: "checkmark.circle",
                        color: .blue
                    )
                ]
            }
