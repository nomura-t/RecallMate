// HomeView.swift - 復習フローを5ステップに拡張した版
import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme
    
    // 既存の状態管理プロパティ
    @State private var selectedDate = Date()
    @Binding var isAddingMemo: Bool
    @State private var selectedTags: [Tag] = []
    @State private var refreshTrigger = UUID()
    
    // 復習フロー用の状態管理（5ステップに拡張）
    @State private var showingReviewFlow = false
    @State private var selectedMemoForReview: Memo? = nil
    @State private var reviewStep: Int = 0
    @State private var recallScore: Int16 = 50
    @State private var sessionStartTime = Date()
    @State private var isSavingReview = false
    @State private var reviewSaveSuccess = false
    
    // 復習用の新しい状態管理
    @State private var selectedReviewMethod: ReviewMethod = .thorough
    @State private var activeReviewStep: Int = 0
    @State private var activeReviewStartTime = Date()
    @State private var reviewElapsedTime: TimeInterval = 0
    @State private var reviewTimer: Timer?
    
    // 新規学習フロー用の状態管理（既存のまま）
    @State private var showingNewLearningFlow = false
    @State private var newLearningStep: Int = 0
    @State private var newLearningTitle = ""
    @State private var newLearningTags: [Tag] = []
    @State private var newLearningInitialScore: Int16 = 70
    @State private var newLearningSessionStartTime = Date()
    @State private var isSavingNewLearning = false
    @State private var newLearningSaveSuccess = false
    
    // アクティブリコール指導用の状態管理（既存のまま）
    @State private var selectedLearningMethod: LearningMethod = .thorough
    @State private var activeRecallStep: Int = 0
    @State private var activeRecallStartTime = Date()
    @State private var showActiveRecallGuidance = true
    
    @State private var learningElapsedTime: TimeInterval = 0
    @State private var learningTimer: Timer?
    
    @FetchRequest(
        entity: Tag.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)],
        animation: .default)
    private var allTags: FetchedResults<Tag>
    
    // 復習方法の種類を定義（新規追加）
    enum ReviewMethod: String, CaseIterable {
        case thorough = "じっくり復習コース"
        case quick = "さくっと復習コース"
        case assessment = "理解度確認のみ"
        
        var icon: String {
            switch self {
            case .thorough: return "brain.head.profile"
            case .quick: return "bolt.fill"
            case .assessment: return "checkmark.circle.fill"
            }
        }
        
        var description: String {
            switch self {
            case .thorough: return "しっかりと時間をかけて復習したい時に"
            case .quick: return "時間がない時や軽く復習したい時に"
            case .assessment: return "記憶度だけを確認したい時に"
            }
        }
        
        var detail: String {
            switch self {
            case .thorough: return "4ステップのアクティブリコールで完全復習"
            case .quick: return "3ステップの効率的復習"
            case .assessment: return "素早く記憶度をチェックして次回の復習日を最適化"
            }
        }
        
        var color: Color {
            switch self {
            case .thorough: return .blue
            case .quick: return .orange
            case .assessment: return .purple
            }
        }
    }
    
    // 学習方法の種類を定義（既存のまま）
    enum LearningMethod: String, CaseIterable {
        case thorough = "じっくり学習コース"
        case quick = "さくっと学習コース"
        case recordOnly = "記録のみコース"
        
        var icon: String {
            switch self {
            case .thorough: return "brain.head.profile"
            case .quick: return "bolt.fill"
            case .recordOnly: return "doc.text.fill"
            }
        }
        
        var description: String {
            switch self {
            case .thorough: return "しっかりと時間をかけて学習したい時に"
            case .quick: return "時間がない時や軽く学習したい時に"
            case .recordOnly: return "既に学習済みの内容を記録して、効果的な復習計画を立てたい時に"
            }
        }
        
        var detail: String {
            switch self {
            case .thorough: return "4ステップのアクティブリコールで完全習得"
            case .quick: return "3ステップの効率的アクティブリコール"
            case .recordOnly: return "学習記録から最適な復習タイミングを自動計算。分散学習の効果で長期記憶への定着をサポートします"
            }
        }
        
        var color: Color {
            switch self {
            case .thorough: return .blue
            case .quick: return .orange
            case .recordOnly: return .green
            }
        }
    }
    
    // dailyMemosの計算プロパティ（既存のまま）
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
            print("Error fetching daily memos: \(error)")
            return []
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 学習タイマーセクション（既存のまま）
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("今日の学習時間")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TodayStudyTimeCard()
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
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
                
                // カスタムカレンダーセクション（既存のまま）
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
                
                // メインコンテンツエリア（既存のまま）
                VStack(spacing: 0) {
                    if !allTags.isEmpty {
                        TagFilterSection(
                            selectedTags: $selectedTags,
                            allTags: Array(allTags)
                        )
                        .padding(.top, 16)
                    }
                    
                    DayInfoHeader(
                        selectedDate: selectedDate,
                        memoCount: dailyMemos.count,
                        selectedTags: selectedTags
                    )
                    
                    // 新規学習ボタンを追加（今日の場合のみ表示）
                    if Calendar.current.isDateInToday(selectedDate) {
                        NewLearningButton(onStartNewLearning: {
                            startNewLearning()
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
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(dailyMemos, id: \.id) { memo in
                                    ReviewListItemSimplified(
                                        memo: memo,
                                        selectedDate: selectedDate,
                                        onStartReview: {
                                            startReview(memo: memo)
                                        },
                                        onOpenMemo: {
                                            // NavigationLinkの処理
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
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(Color(.systemGroupedBackground))
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
        // 復習フローのシートモーダル（5ステップに拡張）
        .sheet(isPresented: $showingReviewFlow) {
            VStack(spacing: 0) {
                // ヘッダー部分
                HStack {
                    Text(getReviewStepTitle())
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: closeReviewFlow) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // プログレスバー（5つに変更）
                HStack(spacing: 8) {
                    ForEach(0..<5) { index in
                        Circle()
                            .fill(index <= reviewStep ? getReviewStepColor(step: index) : Color.gray.opacity(0.3))
                            .frame(width: index == reviewStep ? 12 : 8, height: index == reviewStep ? 12 : 8)
                            .animation(.easeInOut(duration: 0.3), value: reviewStep)
                    }
                }
                .padding(.top, 16)
                
                // メインコンテンツ（5ステップに拡張）
                Group {
                    if reviewStep == 0 {
                        reviewContentConfirmationStepView()
                    } else if reviewStep == 1 {
                        reviewMethodSelectionStepView()
                    } else if reviewStep == 2 {
                        if selectedReviewMethod == .assessment {
                            reviewMemoryAssessmentStepView()
                        } else {
                            activeReviewGuidanceStepView()
                        }
                    } else if reviewStep == 3 {
                        reviewMemoryAssessmentStepView()
                    } else if reviewStep == 4 {
                        reviewCompletionStepView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.easeInOut(duration: 0.3), value: reviewStep)
            }
            .background(Color(.systemGroupedBackground))
            .onAppear {
                setupReviewSession()
            }
        }
        // 新規学習フローのシートモーダル（既存のまま）
        .sheet(isPresented: $showingNewLearningFlow) {
            VStack(spacing: 0) {
                // ヘッダー部分
                HStack {
                    Text(getNewLearningStepTitle())
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: closeNewLearningFlow) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // プログレスバー（5つに変更）
                HStack(spacing: 8) {
                    ForEach(0..<5) { index in
                        Circle()
                            .fill(index <= newLearningStep ? getStepColor(step: index) : Color.gray.opacity(0.3))
                            .frame(width: index == newLearningStep ? 12 : 8, height: index == newLearningStep ? 12 : 8)
                            .animation(.easeInOut(duration: 0.3), value: newLearningStep)
                    }
                }
                .padding(.top, 16)
                
                // メインコンテンツ
                Group {
                    if newLearningStep == 0 {
                        learningTitleInputStepView()
                    } else if newLearningStep == 1 {
                        learningMethodSelectionStepView()
                    } else if newLearningStep == 2 {
                        if selectedLearningMethod == .recordOnly {
                            newLearningInitialAssessmentStepView()
                        } else {
                            activeRecallGuidanceStepView()
                        }
                    } else if newLearningStep == 3 {
                        newLearningInitialAssessmentStepView()
                    } else if newLearningStep == 4 {
                        newLearningCompletionStepView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.easeInOut(duration: 0.3), value: newLearningStep)
            }
            .background(Color(.systemGroupedBackground))
            .onAppear {
                setupNewLearningSession()
            }
        }
        // 状態変更の監視
        .onChange(of: showingReviewFlow) { oldValue, newValue in
            if newValue {
                reviewStep = 0
                sessionStartTime = Date()
                isSavingReview = false
                reviewSaveSuccess = false
                if let memo = selectedMemoForReview {
                    recallScore = memo.recallScore
                }
            }
        }
        .onChange(of: showingNewLearningFlow) { oldValue, newValue in
            if newValue {
                newLearningStep = 0
                newLearningSessionStartTime = Date()
                isSavingNewLearning = false
                newLearningSaveSuccess = false
                resetNewLearningForm()
            }
        }
    }
    
    // MARK: - 復習フロー用ビューメソッド（5ステップに拡張）
    
    private func getReviewStepTitle() -> String {
        switch reviewStep {
        case 0: return "復習内容の確認"
        case 1: return "復習方法を選択"
        case 2:
            if selectedReviewMethod == .assessment {
                return "記憶度の評価"
            } else {
                return "アクティブリコール復習"
            }
        case 3: return "記憶度の評価"
        case 4: return "復習完了"
        default: return "復習フロー"
        }
    }
    
    private func getReviewStepColor(step: Int) -> Color {
        switch step {
        case 0: return .blue  // 確認
        case 1: return .purple  // 選択
        case 2: return selectedReviewMethod.color  // 復習/評価
        case 3: return .orange  // 評価
        case 4: return .green  // 完了
        default: return .gray
        }
    }
    
    // Step 0: 復習内容確認画面（改良版）
    @ViewBuilder
    private func reviewContentConfirmationStepView() -> some View {
        ScrollView {
            VStack(spacing: 24) {
                if let memo = selectedMemoForReview {
                    VStack(spacing: 16) {
                        // アイコンと説明
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
                    withAnimation(.easeInOut(duration: 0.3)) {
                        reviewStep = 1
                    }
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
    
    // Step 1: 復習方法選択画面（新規追加）
    @ViewBuilder
    private func reviewMethodSelectionStepView() -> some View {
        ScrollView {
            VStack(spacing: 32) {
                // ヘッダー情報
                VStack(spacing: 16) {
                    if let memo = selectedMemoForReview {
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
                
                // 復習方法選択カード
                VStack(spacing: 16) {
                    ForEach(ReviewMethod.allCases, id: \.self) { method in
                        ReviewMethodCard(
                            method: method,
                            isSelected: selectedReviewMethod == method,
                            onSelect: {
                                selectedReviewMethod = method
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 40)
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if selectedReviewMethod == .assessment {
                            // 理解度確認のみの場合は評価画面に直接進む（ステップ3）
                            reviewStep = 3
                        } else {
                            // その他の場合はアクティブリコール指導に進む（ステップ2）
                            activeReviewStep = 0
                            activeReviewStartTime = Date()
                            reviewStep = 2
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: selectedReviewMethod == .assessment ? "arrow.right.circle.fill" : "play.circle.fill")
                            .font(.system(size: 18))
                        Text(selectedReviewMethod == .assessment ? "記憶度を評価する" : "復習スタート！")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [selectedReviewMethod.color, selectedReviewMethod.color.opacity(0.8)]),
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
    
    // Step 2: アクティブリコール復習指導画面（新規追加）
    @ViewBuilder
    private func activeReviewGuidanceStepView() -> some View {
        VStack(spacing: 24) {
            // リアルタイムタイマー表示
            LearningTimer(
                startTime: activeReviewStartTime,
                color: selectedReviewMethod.color,
                isActive: showingReviewFlow && reviewStep == 2
            )
            .padding(.top, 20)
            
            // アクティブリコール指導コンテンツ
            ScrollView {
                VStack(spacing: 20) {
                    if selectedReviewMethod == .thorough {
                        ActiveRecallGuidanceContent(
                            steps: getThoroughReviewSteps(),
                            currentStep: activeReviewStep,
                            methodColor: selectedReviewMethod.color
                        )
                    } else {
                        ActiveRecallGuidanceContent(
                            steps: getQuickReviewSteps(),
                            currentStep: activeReviewStep,
                            methodColor: selectedReviewMethod.color
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            
            Spacer()
            
            // コントロールボタン
            VStack(spacing: 16) {
                if activeReviewStep < (selectedReviewMethod == .thorough ? 3 : 2) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            activeReviewStep += 1
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
                                gradient: Gradient(colors: [selectedReviewMethod.color, selectedReviewMethod.color.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                    }
                } else {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            reviewStep = 3  // 記憶度評価ステップへ
                        }
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
                    withAnimation(.easeInOut(duration: 0.3)) {
                        reviewStep = 3  // 記憶度評価ステップへ
                    }
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
        .onAppear {
            // 復習タイマー開始
            startReviewTimer()
        }
        .onDisappear {
            // 復習タイマー停止
            stopReviewTimer()
        }
    }
    
    // Step 3: 記憶度評価画面（既存から改良）
    @ViewBuilder
    private func reviewMemoryAssessmentStepView() -> some View {
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
                        .trim(from: 0, to: CGFloat(recallScore) / 100)
                        .stroke(
                            getRetentionColor(for: recallScore),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 180, height: 180)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: recallScore)
                    
                    VStack(spacing: 4) {
                        Text("\(Int(recallScore))")
                            .font(.system(size: 48, weight: .bold))
                        Text("%")
                            .font(.system(size: 20))
                    }
                    .foregroundColor(getRetentionColor(for: recallScore))
                }
                
                Text(getRetentionDescription(for: recallScore))
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(getRetentionColor(for: recallScore))
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 0.2), value: recallScore)
                
                VStack(spacing: 16) {
                    HStack {
                        Text("0%")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Slider(value: Binding(
                            get: { Double(recallScore) },
                            set: { newValue in
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                recallScore = Int16(newValue)
                            }
                        ), in: 0...100, step: 1)
                        .accentColor(getRetentionColor(for: recallScore))
                        
                        Text("100%")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    HStack(spacing: 0) {
                        ForEach(0..<5) { i in
                            let level = i * 20
                            let isActive = recallScore >= Int16(level)
                            
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
                withAnimation(.easeInOut(duration: 0.3)) {
                    reviewStep = 4  // 完了ステップへ
                }
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
                            getRetentionColor(for: recallScore),
                            getRetentionColor(for: recallScore).opacity(0.8)
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
    
    // Step 4: 復習完了画面（次回復習日表示を追加）
    @ViewBuilder
    private func reviewCompletionStepView() -> some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: isSavingReview ? "clock.fill" : (reviewSaveSuccess ? "checkmark.circle.fill" : "sparkles"))
                    .font(.system(size: 80))
                    .foregroundColor(isSavingReview ? .orange : (reviewSaveSuccess ? .green : selectedReviewMethod.color))
                    .scaleEffect(isSavingReview ? 0.8 : 1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isSavingReview)
                
                Text(isSavingReview ? "保存中..." : (reviewSaveSuccess ? "復習完了！" : "復習完了"))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                if let memo = selectedMemoForReview {
                    Text("「\(memo.title ?? "無題")」")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                }
                
                // 記憶度表示
                HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("記憶度")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(Int(recallScore))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(getRetentionColor(for: recallScore))
                    }
                    
                    // 次回復習日表示（新規追加）
                    if reviewSaveSuccess, let memo = selectedMemoForReview, let nextReviewDate = memo.nextReviewDate {
                        VStack(spacing: 4) {
                            Text("次回復習日")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(formatDateForDisplay(nextReviewDate))
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6).opacity(0.5))
                )
                
                // 次回復習日の詳細説明（新規追加）
                if reviewSaveSuccess, let memo = selectedMemoForReview, let nextReviewDate = memo.nextReviewDate {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(.blue)
                                .font(.system(size: 16))
                            
                            Text(getNextReviewMessage(for: nextReviewDate, score: recallScore))
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Text(getReviewIntervalExplanation(for: recallScore))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                
                if selectedReviewMethod != .assessment {
                    // リアルタイム更新される復習時間表示
                    Text("復習時間: \(formatElapsedTime(reviewElapsedTime))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                            if showingReviewFlow && reviewStep == 4 && selectedReviewMethod != .assessment {
                                reviewElapsedTime = Date().timeIntervalSince(activeReviewStartTime)
                            }
                        }
                }
                
                if reviewSaveSuccess {
                    Text("復習結果が正常に保存されました")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .padding(.top, 8)
                }
            }
            
            Spacer()
            
            if !reviewSaveSuccess {
                Button(action: executeReviewCompletion) {
                    HStack {
                        if isSavingReview {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "sparkles")
                                .font(.system(size: 18))
                        }
                        
                        Text(isSavingReview ? "保存中..." : "復習を完了する")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [selectedReviewMethod.color, selectedReviewMethod.color.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .disabled(isSavingReview)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            } else {
                Button(action: closeReviewFlow) {
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
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            // 最終的な時間を設定
            if selectedReviewMethod != .assessment {
                reviewElapsedTime = Date().timeIntervalSince(activeReviewStartTime)
            }
        }
    }

    // MARK: - 次回復習日関連のヘルパーメソッド（新規追加）

    /// 次回復習日を表示用にフォーマットする
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

    /// 次回復習日に関するメッセージを生成する
    private func getNextReviewMessage(for date: Date, score: Int16) -> String {
        let calendar = Calendar.current
        let daysFromNow = calendar.dateComponents([.day], from: Date(), to: date).day ?? 0
        
        if daysFromNow <= 1 {
            return "記憶が新鮮なうちに再度復習しましょう"
        } else if daysFromNow <= 3 {
            return "短期間での復習で記憶を強化します"
        } else if daysFromNow <= 7 {
            return "1週間後の復習で定着度を確認します"
        } else if daysFromNow <= 14 {
            return "2週間間隔で長期記憶への移行を促します"
        } else if daysFromNow <= 30 {
            return "1ヶ月間隔で記憶の持続性を確認します"
        } else {
            return "長期間隔での復習で完全な定着を目指します"
        }
    }

    /// 復習間隔の科学的根拠を説明する
    private func getReviewIntervalExplanation(for score: Int16) -> String {
        switch score {
        case 90...100:
            return "excellent な理解度のため、長めの間隔で効率的に記憶を維持できます。"
        case 80...89:
            return "良好な理解度です。適度な間隔で確実に長期記憶に定着させていきます。"
        case 70...79:
            return "基本的な理解は十分です。少し短めの間隔で記憶を強化していきます。"
        case 60...69:
            return "要点を理解しています。やや頻繁な復習で記憶の定着を図ります。"
        case 50...59:
            return "基礎的な理解があります。短い間隔での復習で記憶を強化します。"
        default:
            return "復習により記憶を強化し、次回はより良い結果を目指しましょう。"
        }
    }
    
    // 新規学習フロー用ビューメソッド（既存のまま）
    
    private func getNewLearningStepTitle() -> String {
        switch newLearningStep {
        case 0: return "学習内容を入力"
        case 1: return "学習方法を選択"
        case 2:
            if selectedLearningMethod == .recordOnly {
                return "理解度の評価"
            } else {
                return "アクティブリコール学習"
            }
        case 3: return "理解度の評価"
        case 4: return "学習記録完了"
        default: return "新規学習フロー"
        }
    }
    
    private func getStepColor(step: Int) -> Color {
        switch step {
        case 0: return .blue  // 入力
        case 1: return .purple  // 選択
        case 2: return selectedLearningMethod.color  // 学習/評価
        case 3: return .orange  // 評価
        case 4: return .green  // 完了
        default: return .gray
        }
    }
    
    // Step 0: 学習タイトル入力画面（既存のまま）
    @ViewBuilder
    private func learningTitleInputStepView() -> some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                
                VStack(spacing: 24) {
                    // アイコンと説明
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
                    
                    // 入力フィールド
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("学習タイトル（必須）")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            TextField("例: 英単語の暗記、数学の微分積分", text: $newLearningTitle)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.body)
                        }
                        
                        // タグ選択
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
                                                toggleNewLearningTag(tag)
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
                                                    newLearningTags.contains(where: { $0.id == tag.id })
                                                    ? tag.swiftUIColor().opacity(0.2)
                                                    : Color.gray.opacity(0.15)
                                                )
                                                .foregroundColor(
                                                    newLearningTags.contains(where: { $0.id == tag.id })
                                                    ? tag.swiftUIColor()
                                                    : .primary
                                                )
                                                .cornerRadius(16)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                                
                                // 選択されたタグの表示
                                if !newLearningTags.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("選択中のタグ:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 8) {
                                                ForEach(newLearningTags) { tag in
                                                    HStack(spacing: 4) {
                                                        Circle()
                                                            .fill(tag.swiftUIColor())
                                                            .frame(width: 6, height: 6)
                                                        
                                                        Text(tag.name ?? "")
                                                            .font(.caption)
                                                        
                                                        Button(action: {
                                                            removeNewLearningTag(tag)
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
                    withAnimation(.easeInOut(duration: 0.3)) {
                        newLearningStep = 1
                    }
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
                .disabled(newLearningTitle.isEmpty)
            }
            .padding(.top, 20)
        }
    }
    
    // Step 1: 学習方法選択画面（既存のまま）
    @ViewBuilder
    private func learningMethodSelectionStepView() -> some View {
        ScrollView {
            VStack(spacing: 32) {
                // ヘッダー情報
                VStack(spacing: 16) {
                    Text("「\(newLearningTitle)」")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text("どのように学習しますか？")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                // 学習方法選択カード
                VStack(spacing: 16) {
                    ForEach(LearningMethod.allCases, id: \.self) { method in
                        LearningMethodCard(
                            method: method,
                            isSelected: selectedLearningMethod == method,
                            onSelect: {
                                selectedLearningMethod = method
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 40)
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if selectedLearningMethod == .recordOnly {
                            // 記録のみコースの場合は評価画面に直接進む（ステップ3）
                            newLearningStep = 3
                        } else {
                            // その他の場合はアクティブリコール指導に進む（ステップ2）
                            activeRecallStep = 0
                            activeRecallStartTime = Date()
                            newLearningStep = 2
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: selectedLearningMethod == .recordOnly ? "arrow.right.circle.fill" : "play.circle.fill")
                            .font(.system(size: 18))
                        Text(selectedLearningMethod == .recordOnly ? "理解度を評価する" : "学習スタート！")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [selectedLearningMethod.color, selectedLearningMethod.color.opacity(0.8)]),
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
    
    // Step 2: アクティブリコール指導画面（既存のまま）
    @ViewBuilder
    private func activeRecallGuidanceStepView() -> some View {
        VStack(spacing: 24) {
            // リアルタイムタイマー表示
            LearningTimer(
                startTime: activeRecallStartTime,
                color: selectedLearningMethod.color,
                isActive: showingNewLearningFlow && newLearningStep == 2
            )
            .padding(.top, 20)
            // アクティブリコール指導コンテンツ
            ScrollView {
                VStack(spacing: 20) {
                    if selectedLearningMethod == .thorough {
                        ActiveRecallGuidanceContent(
                            steps: getThoroughLearningSteps(),
                            currentStep: activeRecallStep,
                            methodColor: selectedLearningMethod.color
                        )
                    } else {
                        ActiveRecallGuidanceContent(
                            steps: getQuickLearningSteps(),
                            currentStep: activeRecallStep,
                            methodColor: selectedLearningMethod.color
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            
            Spacer()
            
            // コントロールボタン
            VStack(spacing: 16) {
                if activeRecallStep < (selectedLearningMethod == .thorough ? 3 : 2) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            activeRecallStep += 1
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
                                gradient: Gradient(colors: [selectedLearningMethod.color, selectedLearningMethod.color.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                    }
                } else {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            newLearningStep = 3  // 理解度評価ステップへ
                        }
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
                    withAnimation(.easeInOut(duration: 0.3)) {
                        newLearningStep = 3  // 理解度評価ステップへ
                    }
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
        .onAppear {
            // 学習タイマー開始
            startLearningTimer()
        }
        .onDisappear {
            // 学習タイマー停止
            stopLearningTimer()
        }
    }
    
    // Step 3: 理解度評価画面（既存のまま）
    @ViewBuilder
    private func newLearningInitialAssessmentStepView() -> some View {
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
                        .trim(from: 0, to: CGFloat(newLearningInitialScore) / 100)
                        .stroke(
                            getRetentionColor(for: newLearningInitialScore),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 180, height: 180)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: newLearningInitialScore)
                    
                    VStack(spacing: 4) {
                        Text("\(Int(newLearningInitialScore))")
                            .font(.system(size: 48, weight: .bold))
                        Text("%")
                            .font(.system(size: 20))
                    }
                    .foregroundColor(getRetentionColor(for: newLearningInitialScore))
                }
                
                Text(getRetentionDescription(for: newLearningInitialScore))
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(getRetentionColor(for: newLearningInitialScore))
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 0.2), value: newLearningInitialScore)
                
                VStack(spacing: 16) {
                    HStack {
                        Text("0%")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Slider(value: Binding(
                            get: { Double(newLearningInitialScore) },
                            set: { newValue in
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                newLearningInitialScore = Int16(newValue)
                            }
                        ), in: 0...100, step: 1)
                        .accentColor(getRetentionColor(for: newLearningInitialScore))
                        
                        Text("100%")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    newLearningStep = 4  // 完了ステップへ
                }
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
                            getRetentionColor(for: newLearningInitialScore),
                            getRetentionColor(for: newLearningInitialScore).opacity(0.8)
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
    
    // Step 4: 完了画面（次回復習日表示を追加）
    @ViewBuilder
    private func newLearningCompletionStepView() -> some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: isSavingNewLearning ? "clock.fill" : (newLearningSaveSuccess ? "checkmark.circle.fill" : "brain.head.profile"))
                    .font(.system(size: 80))
                    .foregroundColor(isSavingNewLearning ? .orange : (newLearningSaveSuccess ? .green : selectedLearningMethod.color))
                    .scaleEffect(isSavingNewLearning ? 0.8 : 1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isSavingNewLearning)
                
                Text(isSavingNewLearning ? "保存中..." : (newLearningSaveSuccess ? "学習記録完了！" : "新規学習完了"))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("タイトル: \(newLearningTitle)")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                // 理解度と次回復習日を横並びで表示
                HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("初期理解度")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(Int(newLearningInitialScore))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(getRetentionColor(for: newLearningInitialScore))
                    }
                    
                    // 次回復習日表示（新規追加：保存成功後のみ表示）
                    if newLearningSaveSuccess {
                        VStack(spacing: 4) {
                            Text("初回復習日")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(getCalculatedNextReviewDate())
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6).opacity(0.5))
                )
                
                // 初回復習の重要性を説明（新規追加：保存成功後のみ表示）
                if newLearningSaveSuccess {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 16))
                            
                            Text(getInitialReviewMessage(for: newLearningInitialScore))
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Text(getInitialReviewExplanation(for: newLearningInitialScore))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.orange.opacity(0.1))
                    )
                }
                
                if selectedLearningMethod != .recordOnly {
                    // リアルタイム更新される学習時間表示
                    Text("学習時間: \(formatElapsedTime(learningElapsedTime))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                            if showingNewLearningFlow && newLearningStep == 4 && selectedLearningMethod != .recordOnly {
                                learningElapsedTime = Date().timeIntervalSince(activeRecallStartTime)
                            }
                        }
                }
                
                if newLearningSaveSuccess {
                    Text("学習記録が正常に保存されました")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .padding(.top, 8)
                }
            }
            
            Spacer()
            
            if !newLearningSaveSuccess {
                Button(action: executeNewLearningCompletion) {
                    HStack {
                        if isSavingNewLearning {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 18))
                        }
                        
                        Text(isSavingNewLearning ? "保存中..." : "学習記録を保存する")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [selectedLearningMethod.color, selectedLearningMethod.color.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .disabled(isSavingNewLearning)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            } else {
                Button(action: closeNewLearningFlow) {
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
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            // 最終的な時間を設定
            if selectedLearningMethod != .recordOnly {
                learningElapsedTime = Date().timeIntervalSince(activeRecallStartTime)
            }
        }
    }

    // MARK: - 新規学習用の次回復習日関連ヘルパーメソッド（新規追加）

    /// 新規学習の場合の次回復習日を計算して表示形式で返す
    private func getCalculatedNextReviewDate() -> String {
        // ReviewCalculatorを使用して次回復習日を計算
        let nextReviewDate = ReviewCalculator.calculateNextReviewDate(
            recallScore: newLearningInitialScore,
            lastReviewedDate: Date(),
            perfectRecallCount: 0
        )
        
        return formatDateForDisplay(nextReviewDate)
    }

    /// 初回復習に関するメッセージを生成する（新規学習用）
    private func getInitialReviewMessage(for score: Int16) -> String {
        let nextReviewDate = ReviewCalculator.calculateNextReviewDate(
            recallScore: score,
            lastReviewedDate: Date(),
            perfectRecallCount: 0
        )
        
        let calendar = Calendar.current
        let daysFromNow = calendar.dateComponents([.day], from: Date(), to: nextReviewDate).day ?? 0
        
        switch daysFromNow {
        case 0...1:
            return "新しい記憶は忘れやすいため、明日までに復習しましょう"
        case 2...3:
            return "学習直後の記憶を定着させる重要な復習です"
        case 4...7:
            return "1週間以内の復習で短期記憶から長期記憶への移行を促します"
        case 8...14:
            return "2週間間隔での復習で記憶の定着度を確認します"
        default:
            return "良好な理解度のため、長めの間隔での復習が効果的です"
        }
    }

    /// 初回復習間隔の科学的根拠を説明する（新規学習用）
    private func getInitialReviewExplanation(for score: Int16) -> String {
        switch score {
        case 90...100:
            return "非常に高い理解度のため、エビングハウスの忘却曲線を考慮した長めの間隔で効率的に記憶を維持できます。"
        case 80...89:
            return "良好な理解度です。分散学習の原理に基づき、適切な間隔で長期記憶への定着を図ります。"
        case 70...79:
            return "基本的な理解は十分です。忘却曲線の急激な低下を防ぐため、やや短めの間隔で復習します。"
        case 60...69:
            return "要点を理解しています。記憶の定着を確実にするため、短い間隔での復習が効果的です。"
        case 50...59:
            return "基礎的な理解があります。忘却を防ぐため、頻繁な復習で記憶を強化していきます。"
        default:
            return "学習内容の定着には反復が重要です。短い間隔での復習から始めて徐々に記憶を強化しましょう。"
        }
    }
    
    // MARK: - アクションメソッド
    
    private func startReview(memo: Memo) {
        print("🚀 HomeView: 復習開始処理を開始")
        print("🚀   対象記録: \(memo.title ?? "無題")")
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        selectedMemoForReview = memo
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showingReviewFlow = true
        }
    }
    
    private func startNewLearning() {
        print("🚀 HomeView: 新規学習開始処理を開始")
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showingNewLearningFlow = true
        }
    }
    
    private func closeReviewFlow() {
        print("🔚 復習フローを閉じます")
        
        // 復習タイマーを停止
        stopReviewTimer()
        
        showingReviewFlow = false
        selectedMemoForReview = nil
        reviewStep = 0
        isSavingReview = false
        reviewSaveSuccess = false
        
        forceRefreshData()
    }
    
    private func closeNewLearningFlow() {
        print("🔚 新規学習フローを閉じます")
        
        // 学習タイマーを停止
        stopLearningTimer()
        
        showingNewLearningFlow = false
        newLearningStep = 0
        isSavingNewLearning = false
        newLearningSaveSuccess = false
        resetNewLearningForm()
        
        forceRefreshData()
    }
    
    private func forceRefreshData() {
        viewContext.rollback()
        viewContext.refreshAllObjects()
        refreshTrigger = UUID()
    }
    
    // MARK: - セットアップメソッド
    
    private func setupReviewSession() {
        print("🔧 復習セッションを初期化します")
        reviewStep = 0
        sessionStartTime = Date()
        isSavingReview = false
        reviewSaveSuccess = false
        
        // デフォルト値の設定
        selectedReviewMethod = .thorough
        activeReviewStep = 0
        
        if let memo = selectedMemoForReview {
            recallScore = memo.recallScore
            print("📊 記録「\(memo.title ?? "無題")」の復習を開始")
            print("📊 現在の記憶度: \(recallScore)%")
        }
    }
    
    private func setupNewLearningSession() {
        print("🔧 新規学習セッションを初期化します")
        newLearningStep = 0
        newLearningSessionStartTime = Date()
        isSavingNewLearning = false
        newLearningSaveSuccess = false
        resetNewLearningForm()
        
        // デフォルト値の設定
        selectedLearningMethod = .thorough
        activeRecallStep = 0
        newLearningInitialScore = 70
    }
    
    private func resetNewLearningForm() {
        newLearningTitle = ""
        newLearningTags = []
        selectedLearningMethod = .thorough
        activeRecallStep = 0
        newLearningInitialScore = 70
    }
    
    // MARK: - タグ管理メソッド
    
    private func toggleNewLearningTag(_ tag: Tag) {
        if newLearningTags.contains(where: { $0.id == tag.id }) {
            removeNewLearningTag(tag)
        } else {
            newLearningTags.append(tag)
        }
    }
    
    private func removeNewLearningTag(_ tag: Tag) {
        if let index = newLearningTags.firstIndex(where: { $0.id == tag.id }) {
            newLearningTags.remove(at: index)
        }
    }
    
    // MARK: - 完了処理メソッド
    
    private func executeReviewCompletion() {
        guard let memo = selectedMemoForReview else {
            print("❌ 復習対象の記録が見つかりません")
            return
        }
        
        guard !isSavingReview else {
            print("⚠️ 既に保存処理中です")
            return
        }
        
        print("💾 復習完了処理を開始します")
        print("📊 最終記憶度: \(recallScore)%")
        print("📊 復習方法: \(selectedReviewMethod.rawValue)")
        
        isSavingReview = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let sessionDuration: Int
            if self.selectedReviewMethod == .assessment {
                // 理解度確認のみの場合は最小時間を設定
                sessionDuration = Int(Date().timeIntervalSince(self.sessionStartTime))
            } else {
                // アクティブリコール復習を行った場合はその時間を使用
                sessionDuration = Int(Date().timeIntervalSince(self.activeReviewStartTime))
            }
            
            print("⏱️ 復習セッション時間: \(sessionDuration)秒")
            
            DispatchQueue.main.async {
                self.performReviewDataUpdate(memo: memo, sessionDuration: sessionDuration)
            }
        }
    }
    
    private func executeNewLearningCompletion() {
        guard !newLearningTitle.isEmpty else {
            print("❌ タイトルが入力されていません")
            return
        }
        
        guard !isSavingNewLearning else {
            print("⚠️ 既に保存処理中です")
            return
        }
        
        print("💾 新規学習完了処理を開始します")
        print("📊 タイトル: \(newLearningTitle)")
        print("📊 理解度: \(newLearningInitialScore)%")
        print("📊 学習方法: \(selectedLearningMethod.rawValue)")
        
        isSavingNewLearning = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let sessionDuration: Int
            if self.selectedLearningMethod == .recordOnly {
                // 記録のみの場合は最小時間を設定
                sessionDuration = Int(Date().timeIntervalSince(self.newLearningSessionStartTime))
            } else {
                // アクティブリコール指導を行った場合はその時間を使用
                sessionDuration = Int(Date().timeIntervalSince(self.activeRecallStartTime))
            }
            
            print("⏱️ 新規学習セッション時間: \(sessionDuration)秒")
            
            DispatchQueue.main.async {
                self.performNewLearningDataSave(sessionDuration: sessionDuration)
            }
        }
    }
    
    // MARK: - データ永続化メソッド
    
    private func performReviewDataUpdate(memo: Memo, sessionDuration: Int) {
        do {
            print("💾 段階的システムによる復習データ更新を開始")
            
            memo.recallScore = recallScore
            memo.lastReviewedDate = Date()
            
            let historyEntry = MemoHistoryEntry(context: viewContext)
            historyEntry.id = UUID()
            historyEntry.date = Date()
            historyEntry.recallScore = recallScore
            historyEntry.memo = memo
            
            let existingEntries = memo.historyEntriesArray
            let allEntries = [historyEntry] + existingEntries
            
            let nextReviewDate = ReviewCalculator.calculateProgressiveNextReviewDate(
                recallScore: recallScore,
                lastReviewedDate: Date(),
                historyEntries: allEntries
            )
            
            memo.nextReviewDate = nextReviewDate
            
            // 復習活動を記録
            let actualDuration = max(sessionDuration, 1) // 最低1秒のみ保証
            let noteText: String
            if selectedReviewMethod == .assessment {
                noteText = "記憶度確認: \(memo.title ?? "無題") (記憶度: \(recallScore)%)"
            } else {
                noteText = "アクティブリコール復習: \(memo.title ?? "無題") (\(selectedReviewMethod.rawValue), 記憶度: \(recallScore)%)"
            }
            
            let _ = LearningActivity.recordActivityWithPrecision(
                type: .review,
                durationSeconds: actualDuration,
                memo: memo,
                note: noteText,
                in: viewContext
            )
            
            print("⏱️ 記録された復習時間: \(actualDuration)秒")
            
            try viewContext.save()
            
            isSavingReview = false
            reviewSaveSuccess = true
            
            print("✅ 段階的システムによる復習完了")
            
        } catch {
            print("❌ エラー: \(error)")
            isSavingReview = false
        }
    }
    
    private func performNewLearningDataSave(sessionDuration: Int) {
        do {
            print("💾 新規学習データの保存を開始")
            
            let newMemo = Memo(context: viewContext)
            newMemo.id = UUID()
            newMemo.title = newLearningTitle
            newMemo.pageRange = ""
            newMemo.content = ""
            newMemo.recallScore = newLearningInitialScore
            newMemo.createdAt = Date()
            newMemo.lastReviewedDate = Date()
            
            let nextReviewDate = ReviewCalculator.calculateNextReviewDate(
                recallScore: newLearningInitialScore,
                lastReviewedDate: Date(),
                perfectRecallCount: 0
            )
            newMemo.nextReviewDate = nextReviewDate
            
            for tag in newLearningTags {
                newMemo.addTag(tag)
            }
            
            let historyEntry = MemoHistoryEntry(context: viewContext)
            historyEntry.id = UUID()
            historyEntry.date = Date()
            historyEntry.recallScore = newLearningInitialScore
            historyEntry.memo = newMemo
            
            let noteText: String
            if selectedLearningMethod == .recordOnly {
                noteText = "学習記録: \(newLearningTitle) (理解度: \(newLearningInitialScore)%)"
            } else {
                noteText = "アクティブリコール学習: \(newLearningTitle) (\(selectedLearningMethod.rawValue), 理解度: \(newLearningInitialScore)%)"
            }
            
            // 学習活動を記録
            let actualDuration = max(sessionDuration, 1) // 最低1秒のみ保証
            let _ = LearningActivity.recordActivityWithPrecision(
                type: .exercise,
                durationSeconds: actualDuration,
                memo: newMemo,
                note: noteText,
                in: viewContext
            )
            
            print("⏱️ 記録された学習時間: \(actualDuration)秒")
            
            try viewContext.save()
            
            isSavingNewLearning = false
            newLearningSaveSuccess = true
            
            NotificationCenter.default.post(
                name: NSNotification.Name("ForceRefreshMemoData"),
                object: nil
            )
            
            print("✅ 新規学習記録の保存完了")
            
        } catch {
            print("❌ エラー: \(error)")
            isSavingNewLearning = false
        }
    }
    
    // MARK: - タイマー管理メソッド
    
    // 学習タイマーの開始
    private func startLearningTimer() {
        // 初期値を設定
        learningElapsedTime = Date().timeIntervalSince(activeRecallStartTime)
        
        // 既存のタイマーがあれば停止
        stopLearningTimer()
        
        // 1秒ごとに更新するタイマーを開始
        learningTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if showingNewLearningFlow && newLearningStep == 2 {
                learningElapsedTime = Date().timeIntervalSince(activeRecallStartTime)
            }
        }
        
        // タイマーをRunLoopに追加（バックグラウンドでも動作するように）
        if let timer = learningTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    // 学習タイマーの停止
    private func stopLearningTimer() {
        learningTimer?.invalidate()
        learningTimer = nil
    }
    
    // 復習タイマーの開始
    private func startReviewTimer() {
        // 初期値を設定
        reviewElapsedTime = Date().timeIntervalSince(activeReviewStartTime)
        
        // 既存のタイマーがあれば停止
        stopReviewTimer()
        
        // 1秒ごとに更新するタイマーを開始
        reviewTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if showingReviewFlow && reviewStep == 2 {
                reviewElapsedTime = Date().timeIntervalSince(activeReviewStartTime)
            }
        }
        
        // タイマーをRunLoopに追加（バックグラウンドでも動作するように）
        if let timer = reviewTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    // 復習タイマーの停止
    private func stopReviewTimer() {
        reviewTimer?.invalidate()
        reviewTimer = nil
    }
    
    // MARK: - ヘルパーメソッド
    
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
    
    // アクティブリコール学習ステップの定義（既存のまま）
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
    
    // 復習用アクティブリコールステップの定義（新規追加）
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
    
    // MARK: - サポートコンポーネント（既存のまま）
    
    struct NewLearningButton: View {
        let onStartNewLearning: () -> Void
        @Environment(\.colorScheme) var colorScheme
        
        var body: some View {
            Button(action: onStartNewLearning) {
                HStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("新規学習を始める！")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("今日学んだ内容を記録しましょう")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.green,
                            Color.green.opacity(0.8)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(
                    color: Color.green.opacity(0.3),
                    radius: 8,
                    x: 0,
                    y: 4
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
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
                    
                    struct DayInfoHeader: View {
                        let selectedDate: Date
                        let memoCount: Int
                        let selectedTags: [Tag]
                        
                        private var dateText: String {
                            let formatter = DateFormatter()
                            formatter.locale = Locale(identifier: "ja_JP")
                            
                            if Calendar.current.isDateInToday(selectedDate) {
                                return "今日の復習"
                            } else {
                                formatter.dateStyle = .medium
                                return formatter.string(from: selectedDate) + "の復習"
                            }
                        }
                        
                        var body: some View {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(dateText)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    
                                    if !selectedTags.isEmpty || memoCount > 0 {
                                        Text("\(memoCount)件の記録")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                    }
                    
                    struct EmptyStateView: View {
                        let selectedDate: Date
                        let hasTagFilter: Bool
                        
                        var body: some View {
                            VStack(spacing: 16) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray.opacity(0.6))
                                
                                Text(emptyStateMessage)
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                if hasTagFilter {
                                    Text("フィルターを解除すると、他の記録も表示されます")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .padding(.vertical, 40)
                            .frame(maxWidth: .infinity)
                        }
                        
                        private var emptyStateMessage: String {
                            if Calendar.current.isDateInToday(selectedDate) {
                                return hasTagFilter ? "選択されたタグの復習記録がありません" : "今日の復習記録はありません"
                            } else {
                                return hasTagFilter ? "選択されたタグの復習記録がありません" : "この日の復習記録はありません"
                            }
                        }
                    }
                }

                // MARK: - 復習方法選択カード（新規追加）
                struct ReviewMethodCard: View {
                    let method: HomeView.ReviewMethod
                    let isSelected: Bool
                    let onSelect: () -> Void
                    @Environment(\.colorScheme) var colorScheme
                    
                    var body: some View {
                        Button(action: onSelect) {
                            HStack(spacing: 16) {
                                // アイコン部分
                                Image(systemName: method.icon)
                                    .font(.system(size: 28))
                                    .foregroundColor(isSelected ? .white : method.color)
                                    .frame(width: 50, height: 50)
                                    .background(
                                        Circle()
                                            .fill(isSelected ? method.color : method.color.opacity(0.1))
                                    )
                                
                                // テキスト部分
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
                                
                                // 選択インジケーター
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

                // MARK: - 学習方法選択カード（既存のまま）
                struct LearningMethodCard: View {
                    let method: HomeView.LearningMethod
                    let isSelected: Bool
                    let onSelect: () -> Void
                    @Environment(\.colorScheme) var colorScheme
                    
                    var body: some View {
                        Button(action: onSelect) {
                            HStack(spacing: 16) {
                                // アイコン部分
                                Image(systemName: method.icon)
                                    .font(.system(size: 28))
                                    .foregroundColor(isSelected ? .white : method.color)
                                    .frame(width: 50, height: 50)
                                    .background(
                                        Circle()
                                            .fill(isSelected ? method.color : method.color.opacity(0.1))
                                    )
                                
                                // テキスト部分
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
                                
                                // 選択インジケーター
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

                // MARK: - アクティブリコール指導コンテンツ（既存のまま）
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
                            // 現在のステップを強調表示
                            if currentStep < steps.count {
                                let step = steps[currentStep]
                                
                                VStack(spacing: 16) {
                                    // ステップタイトル
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
                                        
                                        // 教育的ヒント
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
                            
                            // ステップ進行状況
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
                            
                            // 全ステップの概要
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
