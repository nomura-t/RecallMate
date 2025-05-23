// HomeView.swift - 新規学習フロー統合版（完全修正版）
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
    
    // 新規学習フロー用の状態管理
    @State private var showingNewLearningFlow = false
    @State private var newLearningStep: Int = 0
    @State private var newLearningTitle = ""
    @State private var newLearningContent = ""
    @State private var newLearningPageRange = ""
    @State private var newLearningTags: [Tag] = []
    @State private var newLearningInitialScore: Int16 = 50
    @State private var newLearningSessionStartTime = Date()
    @State private var isSavingNewLearning = false
    @State private var newLearningSaveSuccess = false
    
    @FetchRequest(
        entity: Tag.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)],
        animation: .default)
    private var allTags: FetchedResults<Tag>
    
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
        // 新規学習フローのシートモーダル
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
                
                // プログレスバー
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(index <= newLearningStep ? Color.green : Color.gray.opacity(0.3))
                            .frame(width: index == newLearningStep ? 12 : 8, height: index == newLearningStep ? 12 : 8)
                            .animation(.easeInOut(duration: 0.3), value: newLearningStep)
                    }
                }
                .padding(.top, 16)
                
                // メインコンテンツ
                Group {
                    if newLearningStep == 0 {
                        newLearningContentInputStepView()
                    } else if newLearningStep == 1 {
                        newLearningInitialAssessmentStepView()
                    } else if newLearningStep == 2 {
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
    
    // MARK: - 復習フロー用ビューメソッド
    
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
    
    // MARK: - 新規学習フロー用ビューメソッド
    
    private func getNewLearningStepTitle() -> String {
        switch newLearningStep {
        case 0: return "学習内容の入力"
        case 1: return "理解度の評価"
        case 2: return "学習記録完了"
        default: return "新規学習フロー"
        }
    }
    
    @ViewBuilder
    private func newLearningContentInputStepView() -> some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("学習内容を入力してください")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // タイトル入力
                        VStack(alignment: .leading, spacing: 8) {
                            Text("タイトル（必須）")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField("学習内容のタイトルを入力", text: $newLearningTitle)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.body)
                        }
                        
                        // ページ範囲入力
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ページ範囲（任意）")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField("例: p.24-32", text: $newLearningPageRange)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.body)
                        }
                        
                        // 内容入力
                        VStack(alignment: .leading, spacing: 8) {
                            Text("学習内容")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextEditor(text: $newLearningContent)
                                .frame(minHeight: 120)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .overlay(
                                    Group {
                                        if newLearningContent.isEmpty {
                                            Text("学習した内容を自分の言葉で書いてみましょう...")
                                                .foregroundColor(.gray)
                                                .padding(12)
                                                .allowsHitTesting(false)
                                        }
                                    }, alignment: .topLeading
                                )
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
                
                Spacer(minLength: 40)
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        newLearningStep = 1
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 18))
                        Text("内容を入力しました")
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
                .disabled(newLearningTitle.isEmpty)
            }
            .padding(.top, 20)
        }
    }
    
    @ViewBuilder
    private func newLearningInitialAssessmentStepView() -> some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Text("学習直後の理解度を評価してください")
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
                    newLearningStep = 2
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
    
    @ViewBuilder
    private func newLearningCompletionStepView() -> some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: isSavingNewLearning ? "clock.fill" : (newLearningSaveSuccess ? "checkmark.circle.fill" : "brain.head.profile"))
                    .font(.system(size: 80))
                    .foregroundColor(isSavingNewLearning ? .orange : (newLearningSaveSuccess ? .green : .green))
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
                
                Text("初期理解度: \(Int(newLearningInitialScore))%")
                    .font(.title2)
                    .foregroundColor(getRetentionColor(for: newLearningInitialScore))
                
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
                            gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
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
    }
    
    private func resetNewLearningForm() {
        newLearningTitle = ""
        newLearningContent = ""
        newLearningPageRange = ""
        newLearningTags = []
        newLearningInitialScore = 50
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
        print("📊 初期記憶度: \(newLearningInitialScore)%")
        
        isSavingNewLearning = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let sessionDuration = Int(Date().timeIntervalSince(self.newLearningSessionStartTime))
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
            newMemo.pageRange = newLearningPageRange
            newMemo.content = newLearningContent
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
            
            let _ = LearningActivity.recordActivityWithPrecision(
                type: .exercise,
                durationSeconds: max(sessionDuration, 60),
                memo: newMemo,
                note: "新規学習記録作成: \(newLearningTitle) (初期理解度: \(newLearningInitialScore)%)",
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
