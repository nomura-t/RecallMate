// HomeView.swift
import SwiftUI
import CoreData

// HomeView.swift - モーダル管理を上位に移動
// HomeView.swift - 安全で確実な復習完了処理の実装
struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme
    
    // 既存の状態管理プロパティ
    @State private var selectedDate = Date()
    @Binding var isAddingMemo: Bool
    @State private var selectedTags: [Tag] = []
    @State private var refreshTrigger = UUID()
    
    // 復習フロー用の状態管理（TabViewを使わない安全な設計）
    @State private var showingReviewFlow = false
    @State private var selectedMemoForReview: Memo? = nil
    @State private var reviewStep: Int = 0
    @State private var recallScore: Int16 = 50
    @State private var sessionStartTime = Date()
    
    // 処理中状態の管理（ユーザーフィードバック用）
    @State private var isSavingReview = false
    @State private var reviewSaveSuccess = false
    
    @FetchRequest(
        entity: Tag.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)],
        animation: .default)
    private var allTags: FetchedResults<Tag>
    
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
                                            // NavigationLinkの処理は既存のまま
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
            .overlay(
                FloatingAddButton(isAddingMemo: $isAddingMemo)
            )
        }
        .onAppear {
            forceRefreshData()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ForceRefreshMemoData"))) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                forceRefreshData()
            }
        }
        .fullScreenCover(isPresented: $isAddingMemo) {
            ContentView(memo: nil)
        }
        // 復習フローのモーダル - TabViewを使わない安全な実装
        .sheet(isPresented: $showingReviewFlow) {
            // 条件分岐による明示的なView切り替えで安全性を確保
            VStack(spacing: 0) {
                // ヘッダー部分（全ステップ共通）
                reviewFlowHeader()
                
                // プログレスインジケーター
                reviewProgressBar()
                    .padding(.top, 16)
                
                // メインコンテンツ - 条件分岐で安全に制御
                Group {
                    if reviewStep == 0 {
                        contentReviewStepView()
                    } else if reviewStep == 1 {
                        memoryAssessmentStepView()
                    } else if reviewStep == 2 {
                        completionStepView()
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
                // モーダル表示時の初期化処理
                setupReviewSession()
            }
        }
        .onChange(of: showingReviewFlow) { oldValue, newValue in
            print("🔍 HomeView: showingReviewFlow状態変更 \(oldValue) -> \(newValue)")
            if newValue {
                // モーダルが開かれた時の初期化
                reviewStep = 0
                sessionStartTime = Date()
                isSavingReview = false
                reviewSaveSuccess = false
                if let memo = selectedMemoForReview {
                    recallScore = memo.recallScore  // 現在の記憶度を初期値として設定
                    print("📊 初期記憶度を設定: \(recallScore)%")
                }
            }
        }
    }
    
    // MARK: - 復習フローのビューコンポーネント
    
    // ヘッダー部分（共通）
    @ViewBuilder
    private func reviewFlowHeader() -> some View {
        HStack {
            Text(getStepTitle())
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
    }
    
    // プログレスバー
    @ViewBuilder
    private func reviewProgressBar() -> some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(index <= reviewStep ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: index == reviewStep ? 12 : 8, height: index == reviewStep ? 12 : 8)
                    .animation(.easeInOut(duration: 0.3), value: reviewStep)
            }
        }
    }
    
    // ステップ0：内容確認ビュー
    @ViewBuilder
    private func contentReviewStepView() -> some View {
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
                            
                            // キーワード表示の実装
                            if let keywords = memo.keywords, !keywords.isEmpty {
                                let keywordList = keywords.components(separatedBy: ",").filter { !$0.isEmpty }
                                if !keywordList.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("重要キーワード:")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                            .padding(.top, 16)
                                        
                                        LazyVGrid(columns: [
                                            GridItem(.adaptive(minimum: 80))
                                        ], spacing: 8) {
                                            ForEach(keywordList, id: \.self) { keyword in
                                                Text(keyword.trimmingCharacters(in: .whitespacesAndNewlines))
                                                    .font(.caption)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(Color.blue.opacity(0.1))
                                                    .foregroundColor(.blue)
                                                    .cornerRadius(8)
                                            }
                                        }
                                    }
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
                
                // 次へボタン
                Button(action: {
                    print("📖 内容確認完了 - 記憶度評価に進みます")
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
                            startPoint: UnitPoint.leading,
                            endPoint: UnitPoint.trailing
                        )
                    )
                    .cornerRadius(25)
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 20)
        }
    }
    
    // ステップ1：記憶度評価ビュー
    @ViewBuilder
    private func memoryAssessmentStepView() -> some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                // 円形プログレス表示
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
                
                // スライダー
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
                                print("📊 記憶度を更新: \(recallScore)%")
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
            
            // 評価完了ボタン
            Button(action: {
                print("📊 記憶度評価完了: \(recallScore)% - 完了画面に進みます")
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
                        startPoint: UnitPoint.leading,
                        endPoint: UnitPoint.trailing
                    )
                )
                .cornerRadius(25)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
    
    // ステップ2：完了ビュー（修正版）
    @ViewBuilder
    private func completionStepView() -> some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                // 成功アイコン
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
                
                // 次回復習日の表示（計算結果を表示）
                if let memo = selectedMemoForReview {
                    VStack(spacing: 8) {
                        Text("次回復習予定日")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(calculateAndFormatNextReviewDate(for: memo))
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                
                // 処理結果の表示
                if reviewSaveSuccess {
                    Text("復習結果が正常に保存されました")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .padding(.top, 8)
                }
            }
            
            Spacer()
            
            // ★★★ ボタンの動作を修正 ★★★
            if !reviewSaveSuccess {
                // まだ保存処理が完了していない場合は保存ボタンを表示
                Button(action: {
                    print("🎯 復習完了ボタンがタップされました")
                    executeReviewCompletion()
                }) {
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
                            startPoint: UnitPoint.leading,
                            endPoint: UnitPoint.trailing
                        )
                    )
                    .cornerRadius(25)
                    .disabled(isSavingReview)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            } else {
                // 保存完了後は手動で閉じるボタンを表示
                Button(action: {
                    print("📱 ユーザーが手動で復習フローを閉じました")
                    closeReviewFlow()
                }) {
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
                            startPoint: UnitPoint.leading,
                            endPoint: UnitPoint.trailing
                        )
                    )
                    .cornerRadius(25)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - ヘルパーメソッド
    
    // ステップタイトルの取得
    private func getStepTitle() -> String {
        switch reviewStep {
        case 0: return "内容の確認"
        case 1: return "記憶度の評価"
        case 2: return "復習完了"
        default: return "復習フロー"
        }
    }
    
    // 復習セッションの初期化
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
    
    // 次回復習日の計算と表示用フォーマット
    private func calculateAndFormatNextReviewDate(for memo: Memo) -> String {
        // 現在評価された記憶度を使用して次回復習日を計算
        let nextReviewDate = ReviewCalculator.calculateNextReviewDate(
            recallScore: recallScore,  // ユーザーが評価した最新の記憶度を使用
            lastReviewedDate: Date(),  // 現在の日時を最終復習日として設定
            perfectRecallCount: memo.perfectRecallCount  // 既存の完璧な復習回数を考慮
        )
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ja_JP")
        
        // 日数の差を計算して表示に含める
        let calendar = Calendar.current
        let daysUntilNext = calendar.dateComponents([.day], from: Date(), to: nextReviewDate).day ?? 0
        
        let formattedDate = formatter.string(from: nextReviewDate)
        
        if daysUntilNext <= 1 {
            return "\(formattedDate) (明日)"
        } else if daysUntilNext <= 7 {
            return "\(formattedDate) (\(daysUntilNext)日後)"
        } else {
            return formattedDate
        }
    }
    
    // 復習完了処理の実行（確実で安全な実装）
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
        
        // バックグラウンドで処理を実行してUIの応答性を保つ
        DispatchQueue.global(qos: .userInitiated).async {
            // 復習セッション時間を計算
            let sessionDuration = Int(Date().timeIntervalSince(self.sessionStartTime))
            print("⏱️ 復習セッション時間: \(sessionDuration)秒")
            
            // メインスレッドでCoreDataの操作を実行
            DispatchQueue.main.async {
                self.performReviewDataUpdate(memo: memo, sessionDuration: sessionDuration)
            }
        }
    }
    
    // CoreDataの更新処理（統合システム対応版）
    // CoreDataの更新処理（段階的システム対応版）
    private func performReviewDataUpdate(memo: Memo, sessionDuration: Int) {
        do {
            print("💾 段階的システムによる復習データ更新を開始")
            
            // 基本情報の更新
            memo.recallScore = recallScore
            memo.lastReviewedDate = Date()
            
            // 履歴エントリの作成
            let historyEntry = MemoHistoryEntry(context: viewContext)
            historyEntry.id = UUID()
            historyEntry.date = Date()
            historyEntry.recallScore = recallScore
            historyEntry.memo = memo
            
            // 既存の履歴を取得（新しいエントリを含む）
            let existingEntries = memo.historyEntriesArray
            let allEntries = [historyEntry] + existingEntries
            
            // 新しい段階的システムで次回復習日を計算
            let nextReviewDate = ReviewCalculator.calculateProgressiveNextReviewDate(
                recallScore: recallScore,
                lastReviewedDate: Date(),
                historyEntries: allEntries
            )
            
            memo.nextReviewDate = nextReviewDate
            
            // 学習アクティビティの記録
            let activity = LearningActivity.recordActivityWithPrecision(
                type: .review,
                durationSeconds: max(sessionDuration, 60),
                memo: memo,
                note: "段階的システム復習: \(memo.title ?? "無題") (記憶度: \(recallScore)%)",
                in: viewContext
            )
            
            try viewContext.save()
            
            // 成功処理
            isSavingReview = false
            reviewSaveSuccess = true
            
            print("✅ 段階的システムによる復習完了")
            
        } catch {
            print("❌ エラー: \(error)")
            isSavingReview = false
        }
    }
    // 記憶度に応じた色計算（既存のメソッド）
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
    
    // 復習開始処理（既存のメソッド）
    private func startReview(memo: Memo) {
        print("🚀 HomeView: 復習開始処理を開始")
        print("🚀   対象記録: \(memo.title ?? "無題")")
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        selectedMemoForReview = memo
        print("🚀   selectedMemoForReview設定完了: \(selectedMemoForReview?.title ?? "nil")")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showingReviewFlow = true
            print("🚀   showingReviewFlow = \(self.showingReviewFlow)")
        }
    }
    
    // 復習フロー終了処理
    private func closeReviewFlow() {
        print("🔚 復習フローを閉じます")
        showingReviewFlow = false
        selectedMemoForReview = nil
        reviewStep = 0
        isSavingReview = false
        reviewSaveSuccess = false
        
        // データを更新して画面に反映
        forceRefreshData()
    }
    
    // データの強制リフレッシュ（既存のメソッド）
    private func forceRefreshData() {
        viewContext.rollback()
        viewContext.refreshAllObjects()
        refreshTrigger = UUID()
    }
}

// MARK: - 拡張された復習カード（ボタン付き）
struct EnhancedReviewListItemWithButtons: View {
    let memo: Memo
    let selectedDate: Date
    let onStartReview: () -> Void
    let onCompleteReview: () -> Void
    let onOpenMemo: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    // State変数を明示的に初期化
    @State private var showingReviewFlow: Bool = false
    
    // デバッグ用の状態（後で削除可能）
    @State private var debugTapCount = 0
    
    // 日付の状態を判定するプロパティ（既存のまま）
    private var isOverdue: Bool {
        guard let reviewDate = memo.nextReviewDate else { return false }
        return Calendar.current.startOfDay(for: reviewDate) < Calendar.current.startOfDay(for: Date())
    }
    
    private var isDueToday: Bool {
        guard let reviewDate = memo.nextReviewDate else { return false }
        return Calendar.current.isDateInToday(reviewDate)
    }
    
    private var daysOverdue: Int {
        guard let reviewDate = memo.nextReviewDate, isOverdue else { return 0 }
        return Calendar.current.dateComponents([.day], from: reviewDate, to: Date()).day ?? 0
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // メインコンテンツエリア（既存と同じ）
            Button(action: onOpenMemo) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        // タイトルとページ範囲を表示
                        HStack {
                            Text(memo.title ?? "無題".localized)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        
                        HStack {
                            if let pageRange = memo.pageRange, !pageRange.isEmpty {
                                Text("(\(pageRange))")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }

                        HStack {
                            // 復習日ラベル - 状態によって表示を変更
                            Text(reviewDateText)
                                .font(.subheadline)
                                .foregroundColor(isOverdue ? .blue : (isDueToday ? .blue : .gray))
                            
                            // 遅延日数を表示（遅延の場合のみ）
                            if isOverdue && daysOverdue > 0 {
                                Text("(%d日経過)".localizedWithInt(daysOverdue))
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // タグ表示
                        if !memo.tagsArray.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 4) {
                                    ForEach(memo.tagsArray.prefix(3), id: \.id) { tag in
                                        HStack(spacing: 2) {
                                            Circle()
                                                .fill(tag.swiftUIColor())
                                                .frame(width: 6, height: 6)
                                            
                                            Text(tag.name ?? "")
                                                .font(.caption2)
                                                .foregroundColor(tag.swiftUIColor())
                                        }
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(tag.swiftUIColor().opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                    
                                    if memo.tagsArray.count > 3 {
                                        Text("+\(memo.tagsArray.count - 3)")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                            .padding(.horizontal, 4)
                                    }
                                }
                            }
                            .frame(height: 20)
                        }
                    }

                    Spacer()

                    // 記憶度表示
                    VStack(spacing: 4) {
                        Text("\(memo.recallScore)%")
                            .font(.headline)
                            .foregroundColor(progressColor(for: memo.recallScore))
                        
                        Text("記憶度")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 復習ボタンエリア - ここが重要な修正箇所
            HStack(spacing: 16) {
                // 復習開始ボタン（メインアクション）
                Button(action: {
                    // デバッグ情報を追加
                    debugTapCount += 1
                    print("復習ボタンがタップされました: \(debugTapCount)回目")
                    print("現在のshowingReviewFlow状態: \(showingReviewFlow)")
                    
                    // ハプティックフィードバック
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    // 状態を明示的に更新
                    showingReviewFlow = true
                    print("showingReviewFlowを更新: \(showingReviewFlow)")
                    
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 18))
                        Text("復習を始める")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(22)
                    .shadow(
                        color: Color.blue.opacity(0.3),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // 詳細表示ボタン（サブアクション）
                Button(action: onOpenMemo) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                        .frame(width: 44, height: 44)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(22)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(backgroundColorForState)
                .shadow(
                    color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1),
                    radius: colorScheme == .dark ? 3 : 2,
                    x: 0,
                    y: colorScheme == .dark ? 2 : 1
                )
        )
        // モーダル表示の修正 - 複数の方法を試す
        .sheet(isPresented: $showingReviewFlow) {
            // シンプルなテスト用のモーダルビュー（まず動作確認）
            NavigationView {
                VStack {
                    Text("復習フローテスト")
                        .font(.title)
                        .padding()
                    
                    Text("記録: \(memo.title ?? "無題")")
                        .padding()
                    
                    Button("閉じる") {
                        showingReviewFlow = false
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    Spacer()
                }
                .navigationTitle("復習")
                .navigationBarItems(trailing: Button("完了") {
                    showingReviewFlow = false
                })
            }
        }
        // デバッグ用の状態変更監視
        .onChange(of: showingReviewFlow) { oldValue, newValue in
            print("showingReviewFlowが変更されました: \(oldValue) -> \(newValue)")
        }
    }
    
    // 既存のヘルパーメソッド
    private var backgroundColorForState: Color {
        if isOverdue {
            return Color.blue.opacity(colorScheme == .dark ? 0.2 : 0.1)
        } else if isDueToday {
            return Color.blue.opacity(colorScheme == .dark ? 0.2 : 0.1)
        } else {
            return colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground)
        }
    }
    
    private var reviewDateText: String {
        if isOverdue {
            return "復習予定日: %@".localizedFormat(formattedDate(memo.nextReviewDate))
        } else if isDueToday {
            return "今日が復習日".localized
        } else {
            return "復習日: %@".localizedFormat(formattedDate(memo.nextReviewDate))
        }
    }

    private func progressColor(for score: Int16) -> Color {
        switch score {
        case 0..<40:
            return Color.red
        case 40..<70:
            return Color.yellow
        default:
            return Color.green
        }
    }

    private func formattedDate(_ date: Date?) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return date != nil ? formatter.string(from: date!) : "未定".localized
    }
}

// MARK: - タグフィルタリングセクション
struct TagFilterSection: View {
    @Binding var selectedTags: [Tag]
    let allTags: [Tag]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // タグ選択のための水平スクロールビュー
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // 「すべて」ボタン
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
                    
                    // 個別のタグボタン
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
            
            // 選択されたタグの表示
            if !selectedTags.isEmpty {
                SelectedTagsView(
                    selectedTags: selectedTags,
                    onClearAll: { selectedTags = [] }
                )
                .padding(.horizontal, 16)
            }
        }
    }
    
    // タグの選択/解除をトグル
    private func toggleTag(_ tag: Tag) {
        if let index = selectedTags.firstIndex(where: { $0.id == tag.id }) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
        }
    }
}

// MARK: - タグフィルターボタン
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

// MARK: - 選択されたタグの表示
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
            
            // フィルタークリアボタン
            Button(action: onClearAll) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
    }
}
