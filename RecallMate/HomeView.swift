// HomeView.swift - 新規学習フロー統合版（アクティブリコール指導対応版）
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
    
    // 復習フロー用の状態管理
    @State private var showingReviewFlow = false
    @State private var selectedMemoForReview: Memo? = nil
    @State private var reviewStep: Int = 0
    @State private var recallScore: Int16 = 50
    @State private var sessionStartTime = Date()
    @State private var isSavingReview = false
    @State private var reviewSaveSuccess = false
    
    // 新規学習フロー用の状態管理（拡張版）
    @State private var showingNewLearningFlow = false
    @State private var newLearningStep: Int = 0
    @State private var newLearningTitle = ""
    @State private var newLearningTags: [Tag] = []
    @State private var newLearningInitialScore: Int16 = 70
    @State private var newLearningSessionStartTime = Date()
    @State private var isSavingNewLearning = false
    @State private var newLearningSaveSuccess = false
    
    // アクティブリコール指導用の状態管理
    @State private var selectedLearningMethod: LearningMethod = .thorough
    @State private var activeRecallStep: Int = 0
    @State private var activeRecallStartTime = Date()
    @State private var showActiveRecallGuidance = true
    
    @FetchRequest(
        entity: Tag.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)],
        animation: .default)
    private var allTags: FetchedResults<Tag>
    
    // 学習方法の種類を定義
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
    
    // dailyMemosの計算プロパティ
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
                // 学習タイマーセクション
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
                
                // カスタムカレンダーセクション
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
                
                // メインコンテンツエリア
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
        // 復習フローのシートモーダル
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
                
                // プログレスバー
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(index <= reviewStep ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: index == reviewStep ? 12 : 8, height: index == reviewStep ? 12 : 8)
                            .animation(.easeInOut(duration: 0.3), value: reviewStep)
                    }
                }
                .padding(.top, 16)
                
                // メインコンテンツ
                Group {
                    if reviewStep == 0 {
                        reviewContentStepView()
                    } else if reviewStep == 1 {
                        reviewMemoryAssessmentStepView()
                    } else if reviewStep == 2 {
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
        // 新規学習フローのシートモーダル（完全改良版）
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
                
                // プログレスバー（4つに変更）
                HStack(spacing: 8) {
                    ForEach(0..<4) { index in
                        Circle()
                            .fill(index <= newLearningStep ? selectedLearningMethod.color : Color.gray.opacity(0.3))
                            .frame(width: index == newLearningStep ? 12 : 8, height: index == newLearningStep ? 12 : 8)
                            .animation(.easeInOut(duration: 0.3), value: newLearningStep)
                    }
                }
                .padding(.top, 16)
                
                // メインコンテンツ
                Group {
                    if newLearningStep == 0 {
                        learningMethodSelectionStepView()
                    } else if newLearningStep == 1 {
                        if selectedLearningMethod == .recordOnly {
                            newLearningInitialAssessmentStepView()
                        } else {
                            activeRecallGuidanceStepView()
                        }
                    } else if newLearningStep == 2 {
                        newLearningInitialAssessmentStepView()
                    } else if newLearningStep == 3 {
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
    
    // MARK: - 新規学習フロー用ビューメソッド（完全改良版）
    
    private func getNewLearningStepTitle() -> String {
        switch newLearningStep {
        case 0: return "学習方法を選択"
        case 1:
            if selectedLearningMethod == .recordOnly {
                return "理解度の評価"
            } else {
                return "アクティブリコール学習"
            }
        case 2: return "理解度の評価"
        case 3: return "学習記録完了"
        default: return "新規学習フロー"
        }
    }
    
    // Step 0: 学習方法選択画面（カード型UI）
    @ViewBuilder
    private func learningMethodSelectionStepView() -> some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("今日は何を学習しますか？")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // タイトル入力
                        VStack(alignment: .leading, spacing: 8) {
                            Text("学習タイトル（必須）")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField("今日学習する内容のタイトルを入力", text: $newLearningTitle)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.body)
                        }
                        
                        // タグ選択
                        if !allTags.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("タグ（任意）")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
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
                            }
                        }
                    }
                }
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                // 学習方法選択カード
                VStack(alignment: .leading, spacing: 16) {
                    Text("学習方法を選択してください")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 12) {
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
                }
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                Spacer(minLength: 40)
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if selectedLearningMethod == .recordOnly {
                            // 記録のみコースの場合は評価画面に直接進む
                            newLearningStep = 2
                        } else {
                            // その他の場合はアクティブリコール指導に進む
                            activeRecallStep = 0
                            activeRecallStartTime = Date()
                            newLearningStep = 1
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
                .disabled(newLearningTitle.isEmpty)
            }
            .padding(.top, 20)
        }
    }
    
    // Step 1: アクティブリコール指導画面
    @ViewBuilder
    private func activeRecallGuidanceStepView() -> some View {
        VStack(spacing: 24) {
            // タイマー表示
            VStack(spacing: 12) {
                Text("学習時間")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(formatElapsedTime(Date().timeIntervalSince(activeRecallStartTime)))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(selectedLearningMethod.color)
            }
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
                            newLearningStep = 2
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
                        newLearningStep = 2
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
    }
    
    // Step 2: 理解度評価画面
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
                    newLearningStep = 3
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
    
    // Step 3: 完了画面
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
                
                Text("理解度: \(Int(newLearningInitialScore))%")
                    .font(.title2)
                    .foregroundColor(getRetentionColor(for: newLearningInitialScore))
                
                if selectedLearningMethod != .recordOnly {
                    Text("学習時間: \(formatElapsedTime(Date().timeIntervalSince(activeRecallStartTime)))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
    }
    
    // MARK: - 復習フロー用ビューメソッド（既存）
    
    private func getReviewStepTitle() -> String {
        switch reviewStep {
        case 0: return "内容の確認"
        case 1: return "記憶度の評価"
        case 2: return "復習完了"
        default: return "復習フロー"
        }
    }
    
    @ViewBuilder
    private func reviewContentStepView() -> some View {
        ScrollView {
            VStack(spacing: 24) {
                if let memo = selectedMemoForReview {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("復習する内容")
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
                            
                            Text(memo.content ?? "内容が記録されていません")
                                .font(.body)
                                .lineSpacing(4)
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
                        Image(systemName: "brain.head.profile")
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
    
    @ViewBuilder
    private func reviewMemoryAssessmentStepView() -> some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
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
                }
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    reviewStep = 2
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
    
    @ViewBuilder
    private func reviewCompletionStepView() -> some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: isSavingReview ? "clock.fill" : (reviewSaveSuccess ? "checkmark.circle.fill" : "sparkles"))
                    .font(.system(size: 80))
                    .foregroundColor(isSavingReview ? .orange : (reviewSaveSuccess ? .green : .blue))
                    .scaleEffect(isSavingReview ? 0.8 : 1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isSavingReview)
                
                Text(isSavingReview ? "保存中..." : (reviewSaveSuccess ? "復習完了！" : "復習完了"))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("記憶度: \(Int(recallScore))%")
                    .font(.title2)
                    .foregroundColor(getRetentionColor(for: recallScore))
                
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
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
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
        showingReviewFlow = false
        selectedMemoForReview = nil
        reviewStep = 0
        isSavingReview = false
        reviewSaveSuccess = false
        
        forceRefreshData()
    }
    
    private func closeNewLearningFlow() {
        print("🔚 新規学習フローを閉じます")
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
        
        isSavingReview = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let sessionDuration = Int(Date().timeIntervalSince(self.sessionStartTime))
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
            
            let _ = LearningActivity.recordActivityWithPrecision(
                type: .review,
                durationSeconds: max(sessionDuration, 60),
                memo: memo,
                note: "段階的システム復習: \(memo.title ?? "無題") (記憶度: \(recallScore)%)",
                in: viewContext
            )
            
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
            
            let _ = LearningActivity.recordActivityWithPrecision(
                type: .exercise,
                durationSeconds: max(sessionDuration, 60),
                memo: newMemo,
                note: noteText,
                in: viewContext
            )
            
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
    
    // アクティブリコール学習ステップの定義
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
    
    // MARK: - サポートコンポーネント
    
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

// MARK: - 学習方法選択カード
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

// MARK: - アクティブリコール指導コンテンツ
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
