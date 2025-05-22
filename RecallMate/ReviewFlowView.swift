// ReviewFlowView.swift (修正版)
import SwiftUI
import CoreData

// 復習フローの段階を定義
enum ReviewStep: Int, CaseIterable {
    case preparation = 0    // 準備：内容確認
    case reflection = 1     // 振り返り：記憶度評価
    case completion = 2     // 完了：結果確認
    
    var title: String {
        switch self {
        case .preparation: return "復習内容の確認"
        case .reflection: return "記憶定着度の振り返り"
        case .completion: return "復習完了"
        }
    }
    
    var subtitle: String {
        switch self {
        case .preparation: return "学習した内容を思い出してみましょう"
        case .reflection: return "どのくらい覚えていましたか？"
        case .completion: return "お疲れ様でした！"
        }
    }
}

struct ReviewFlowView: View {
    let memo: Memo
    let onCompletion: () -> Void
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    // 復習フローの状態管理
    @State private var currentStep: ReviewStep = .preparation
    @State private var recallScore: Int16 = 50
    @State private var sessionStartTime = Date()
    @State private var isSubmitting = false
    
    // アニメーション用の状態
    @State private var showContent = false
    @State private var isViewAppeared = false
    
    var body: some View {
        // NavigationStackを削除し、シンプルなVStackベースの構造に変更
        ZStack {
            // 背景
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // ヘッダーエリア
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // プログレスインジケーター
                ReviewProgressIndicator(currentStep: currentStep)
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                
                // メインコンテンツエリア
                Group {
                    switch currentStep {
                    case .preparation:
                        PreparationStepView(
                            memo: memo,
                            showContent: $showContent,
                            onNext: { moveToNextStep() }
                        )
                    case .reflection:
                        ReflectionStepView(
                            memo: memo,
                            recallScore: $recallScore,
                            onNext: { moveToNextStep() }
                        )
                    case .completion:
                        CompletionStepView(
                            memo: memo,
                            recallScore: recallScore,
                            isSubmitting: $isSubmitting,
                            onComplete: { completeReview() }
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .onAppear {
            // 安全な初期化処理
            if !isViewAppeared {
                isViewAppeared = true
                setupInitialState()
            }
        }
    }
    
    // 初期状態の設定
    private func setupInitialState() {
        recallScore = memo.recallScore
        
        // コンテンツを段階的に表示
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.8)) {
                showContent = true
            }
        }
    }
    
    // 次のステップに進む
    private func moveToNextStep() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        withAnimation(.easeInOut(duration: 0.4)) {
            if let nextStep = ReviewStep(rawValue: currentStep.rawValue + 1) {
                currentStep = nextStep
            }
        }
    }
    
    // 復習完了処理
    private func completeReview() {
        guard !isSubmitting else { return }
        isSubmitting = true
        
        // バックグラウンドで処理を実行
        DispatchQueue.global(qos: .userInitiated).async {
            let reviewDuration = Int(Date().timeIntervalSince(sessionStartTime))
            
            // メインスレッドでCoreDataの操作を実行
            DispatchQueue.main.async {
                self.performCoreDataUpdate(reviewDuration: reviewDuration)
            }
        }
    }
    
    // CoreDataの更新処理（メインスレッドで実行）
    private func performCoreDataUpdate(reviewDuration: Int) {
        do {
            // 記憶度を更新
            memo.recallScore = recallScore
            memo.lastReviewedDate = Date()
            
            // 次回復習日を計算
            let nextReviewDate = ReviewCalculator.calculateNextReviewDate(
                recallScore: recallScore,
                lastReviewedDate: Date(),
                perfectRecallCount: memo.perfectRecallCount
            )
            memo.nextReviewDate = nextReviewDate
            
            // 復習アクティビティを記録
            let activity = LearningActivity.recordActivityWithPrecision(
                type: .review,
                durationSeconds: max(reviewDuration, 60),
                memo: memo,
                note: "復習完了: \(memo.title ?? "無題")",
                in: viewContext
            )
            
            // 変更を保存
            try viewContext.save()
            
            // 成功フィードバック
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            SoundManager.shared.playMemoryCompletedSound()
            
            // データ更新通知
            NotificationCenter.default.post(
                name: NSNotification.Name("ForceRefreshMemoData"),
                object: nil
            )
            
            // 完了処理（遅延を短縮）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                self.onCompletion()
                self.dismiss()
            }
            
        } catch {
            print("Error saving review completion: \(error)")
            isSubmitting = false
        }
    }
}

// ... 他のコンポーネント（ReviewProgressIndicator, PreparationStepView, ReflectionStepView, CompletionStepView）は同じですが、
// NavigationStackに依存する部分は削除します

// MARK: - プログレスインジケーター
struct ReviewProgressIndicator: View {
    let currentStep: ReviewStep
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            // ステップタイトル
            Text(currentStep.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(currentStep.subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // プログレスバー
            HStack(spacing: 8) {
                ForEach(ReviewStep.allCases, id: \.rawValue) { step in
                    let isActive = step.rawValue <= currentStep.rawValue
                    let isCurrent = step == currentStep
                    
                    Circle()
                        .fill(isActive ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: isCurrent ? 12 : 8, height: isCurrent ? 12 : 8)
                        .scaleEffect(isCurrent ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                    
                    if step != ReviewStep.allCases.last {
                        Rectangle()
                            .fill(isActive ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 30, height: 2)
                            .animation(.easeInOut(duration: 0.3), value: currentStep)
                    }
                }
            }
        }
    }
}

// MARK: - Step 1: 準備段階
struct PreparationStepView: View {
    let memo: Memo
    @Binding var showContent: Bool
    let onNext: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 学習内容カード
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 20))
                        
                        Text("学習内容")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    if showContent {
                        VStack(alignment: .leading, spacing: 12) {
                            // タイトル
                            Text(memo.title ?? "無題")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            // ページ範囲
                            if let pageRange = memo.pageRange, !pageRange.isEmpty {
                                Text("ページ: \(pageRange)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Divider()
                                .padding(.vertical, 8)
                            
                            // 学習内容
                            Text(memo.content ?? "")
                                .font(.body)
                                .foregroundColor(.primary)
                                .lineSpacing(4)
                            
                            // キーワード表示
                            if let keywords = memo.keywords, !keywords.isEmpty {
                                let keywordList = keywords.components(separatedBy: ",").filter { !$0.isEmpty }
                                if !keywordList.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("重要キーワード:")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                        
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
                                    .padding(.top, 8)
                                }
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .animation(.easeInOut(duration: 0.8), value: showContent)
                    } else {
                        // ローディング状態
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("内容を読み込んでいます...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 100)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
                        .shadow(
                            color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1),
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                )
                
                Spacer(minLength: 40)
                
                // 次へボタン
                if showContent {
                    Button(action: onNext) {
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
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.easeInOut(duration: 0.5).delay(1.0), value: showContent)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
}

// MARK: - Step 2: 振り返り段階
struct ReflectionStepView: View {
    let memo: Memo
    @Binding var recallScore: Int16
    let onNext: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // 記憶度評価エリア
            VStack(spacing: 24) {
                // 円形プログレス
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2), lineWidth: 12)
                        .frame(width: 180, height: 180)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(recallScore) / 100)
                        .stroke(
                            retentionColor(for: recallScore),
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
                    .foregroundColor(retentionColor(for: recallScore))
                }
                
                // 記憶状態の説明
                Text(retentionDescription(for: recallScore))
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(retentionColor(for: recallScore))
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
                            }
                        ), in: 0...100, step: 1)
                        .accentColor(retentionColor(for: recallScore))
                        
                        Text("100%")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    // スライダー下部のインジケーター
                    HStack(spacing: 0) {
                        ForEach(0..<5) { i in
                            let level = i * 20
                            let isActive = recallScore >= Int16(level)
                            
                            Rectangle()
                                .fill(isActive ? retentionColorForLevel(i) : Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2))
                                .frame(height: 6)
                                .cornerRadius(3)
                        }
                    }
                }
            }
            
            Spacer()
            
            // 次へボタン
            Button(action: onNext) {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 18))
                    Text("振り返り完了")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [retentionColor(for: recallScore), retentionColor(for: recallScore).opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 20)
    }
    
    // 記憶度に応じた色を返す
    private func retentionColor(for score: Int16) -> Color {
        switch score {
        case 81...100: return Color(red: 0.0, green: 0.7, blue: 0.3)
        case 61...80: return Color(red: 0.3, green: 0.7, blue: 0.0)
        case 41...60: return Color(red: 0.95, green: 0.6, blue: 0.1)
        case 21...40: return Color(red: 0.9, green: 0.45, blue: 0.0)
        default: return Color(red: 0.9, green: 0.2, blue: 0.2)
        }
    }
    
    private func retentionColorForLevel(_ level: Int) -> Color {
        switch level {
        case 4: return Color(red: 0.0, green: 0.7, blue: 0.3)
        case 3: return Color(red: 0.3, green: 0.7, blue: 0.0)
        case 2: return Color(red: 0.95, green: 0.6, blue: 0.1)
        case 1: return Color(red: 0.9, green: 0.45, blue: 0.0)
        default: return Color(red: 0.9, green: 0.2, blue: 0.2)
        }
    }
    
    private func retentionDescription(for score: Int16) -> String {
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
}

// MARK: - Step 3: 完了段階
struct CompletionStepView: View {
    let memo: Memo
    let recallScore: Int16
    @Binding var isSubmitting: Bool
    let onComplete: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // 完了アニメーション
            VStack(spacing: 24) {
                // 成功アイコン
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .scaleEffect(isSubmitting ? 0.8 : 1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isSubmitting)
                
                Text("復習完了！")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("記憶度: \(Int(recallScore))%")
                    .font(.title2)
                    .foregroundColor(retentionColor(for: recallScore))
                
                // 次回復習日の表示
                if let nextReviewDate = memo.nextReviewDate {
                    VStack(spacing: 8) {
                        Text("次回復習予定日")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(formattedDate(nextReviewDate))
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
            }
            
            Spacer()
            
            // 完了ボタン
            Button(action: onComplete) {
                HStack {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18))
                    }
                    
                    Text(isSubmitting ? "保存中..." : "復習を完了する")
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
                .disabled(isSubmitting)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
    
    private func retentionColor(for score: Int16) -> Color {
        switch score {
        case 81...100: return Color(red: 0.0, green: 0.7, blue: 0.3)
        case 61...80: return Color(red: 0.3, green: 0.7, blue: 0.0)
        case 41...60: return Color(red: 0.95, green: 0.6, blue: 0.1)
        case 21...40: return Color(red: 0.9, green: 0.45, blue: 0.0)
        default: return Color(red: 0.9, green: 0.2, blue: 0.2)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}
