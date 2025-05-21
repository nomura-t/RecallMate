// ContentView.swift - 学習タブを削除した版
import SwiftUI
import CoreData
import PencilKit
import UIKit

class ViewSettings: ObservableObject {
    @Published var keyboardAvoiding = true
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var appSettings: AppSettings
    
    var memo: Memo?
    
    @StateObject private var viewModel: ContentViewModel
    @State private var showCustomQuestionCreator = false
    @State private var showQuestionEditor = false
    @State private var isDrawing = false
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    @State private var showTagSelection = false
    @State private var sessionId: UUID? = nil
    
    // UIKitスクロール用のトリガー
    @State private var triggerScroll = false
    
    // フォーカス状態
    @FocusState private var titleFieldFocused: Bool
    @FocusState private var contentFieldFocused: Bool
    
    // 「使い方」ボタンと状態変数
    @State private var showUsageModal = false
    
    // リセット確認アラート用
    @State private var showContentResetAlert = false
    
    // コンテンツフィールド用のID
    @Namespace var contentField
    @Namespace var titleField
    @Namespace var recallSliderSection

    @State private var showUnsavedChangesAlert = false

    // すべてのタグを取得
    @FetchRequest(
        entity: Tag.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)],
        animation: .default)
    private var allTags: FetchedResults<Tag>
    
    init(memo: Memo? = nil) {
        self.memo = memo
        self._viewModel = StateObject(wrappedValue: ContentViewModel(viewContext: PersistenceController.shared.container.viewContext, memo: memo))
    }
    
    var body: some View {
        ZStack {
            // 背景
            AppColors.groupedBackground
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // カスタムヘッダー - スタイリッシュな透明感のあるデザイン
                HStack {
                    Button(action: handleBackButton) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("戻る".localized)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(AppColors.accent)
                        .padding(12)
                        .background(colorScheme == .dark ? Color(.systemGray5) : Color.white.opacity(0.8))
                        .cornerRadius(20)
                        .shadow(
                            color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.05),
                            radius: 2,
                            x: 0,
                            y: 1
                        )
                    }
                    
                    Spacer()
                    
                    // タブインジケーターを削除
                    TodayStudyTimeCard()
                    
                    Spacer()
                    
                    // 使い方ボタン
                    Button(action: {
                        showUsageModal = true
                    }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.accent)
                            .frame(width: 40, height: 40)
                            .background(colorScheme == .dark ? Color(.systemGray5) : Color.white.opacity(0.8))
                            .clipShape(Circle())
                            .shadow(
                                color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.05),
                                radius: 2,
                                x: 0,
                                y: 1
                            )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)
                
                // 記録タブのコンテンツを直接表示（TabViewを削除）
                recordTab
            }
            
            // フローティングボタン - 保存ボタン
            VStack {
                Spacer()
                
                Button {
                    // ハプティックフィードバックを追加
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    // 保存アクション
                    viewModel.saveMemoWithTracking {
                        dismiss()
                    }
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                        Text("記録完了！".localized)
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(height: 56)
                    .frame(minWidth: 180)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [AppColors.accent, AppColors.accent.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(28)
                    .shadow(
                        color: AppColors.accent.opacity(colorScheme == .dark ? 0.4 : 0.3),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                    .padding(.bottom, 16)
                }
                .padding(.horizontal)
                .transition(.scale)
            }
        }
        .navigationBarHidden(true)
        .onAppear(perform: handleOnAppear)
        .onDisappear(perform: handleOnDisappear)
        // モーダル画面の設定
        .fullScreenCover(isPresented: $isDrawing) {
            FullScreenCanvasView(isDrawing: $isDrawing, canvas: $canvasView, toolPicker: $toolPicker)
                .onDisappear {
                    viewModel.contentChanged = true
                    viewModel.recordActivityOnSave = true
                }
        }
        .sheet(isPresented: $showTagSelection, onDismiss: handleTagSelectionDismiss) {
            NavigationView {
                TagSelectionView(
                    selectedTags: $viewModel.selectedTags,
                    onTagsChanged: memo != nil ? {
                        viewModel.contentChanged = true
                        viewModel.recordActivityOnSave = true
                    } : nil
                )
                .environment(\.managedObjectContext, viewContext)
                .navigationTitle("タグを選択".localized)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("完了".localized) { showTagSelection = false }
                    }
                }
            }
        }
        .sheet(isPresented: $showQuestionEditor, onDismiss: handleQuestionEditorDismiss) {
        }
        .environmentObject(ViewSettings())
        // アラート設定
        .alert("タイトルが必要です".localized, isPresented: $viewModel.showTitleAlert) {
            Button("OK") { viewModel.showTitleAlert = false }
        } message: {
            Text("続行するには記録のタイトルを入力してください。".localized)
        }
        .alert("内容をリセット".localized, isPresented: $showContentResetAlert) {
            Button("キャンセル".localized, role: .cancel) {}
            Button("リセット".localized, role: .destructive) {
                DispatchQueue.main.async {
                    viewModel.content = ""
                    viewModel.contentChanged = true
                }
            }
        } message: {
            Text("記録の内容をクリアしますか？この操作は元に戻せません。".localized)
        }
        .alert("変更が保存されていません".localized, isPresented: $showUnsavedChangesAlert) {
            Button("キャンセル".localized, role: .cancel) {}
            Button("保存".localized, role: .none) {
                viewModel.saveMemoWithTracking {
                    dismiss()
                }
            }
            Button("保存せずに戻る".localized, role: .destructive) {
                if memo == nil {
                    viewModel.cleanupOrphanedQuestions()
                }
                dismiss()
            }
        } message: {
            Text("記録の変更内容を保存しますか？".localized)
        }
        // ここに「使い方」モーダルのオーバーレイを追加
        .overlay(
            Group {
                if showUsageModal {
                    UsageModalView(isPresented: $showUsageModal)
                        .transition(.opacity)
                        .animation(.easeInOut, value: showUsageModal)
                }
            }
        )
    }
    
    // 記録タブ - ダークモード対応
    private var recordTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // タイトルとページ範囲 - エレガントなフォームデザイン
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 12) {
                        // タイトル入力
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("タイトル".localized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                if viewModel.shouldFocusTitle {
                                    Text("(必須)".localized)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            
                            TextField("学習内容のタイトルを入力".localized, text: $viewModel.title)
                                .font(.headline)
                                .padding()
                                .background(AppColors.background)
                                .cornerRadius(12)
                                .shadow(
                                    color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.05),
                                    radius: 2,
                                    x: 0,
                                    y: 1
                                )
                                .focused($titleFieldFocused)
                                .id(titleField)
                                .onChange(of: viewModel.title) { _, _ in
                                    viewModel.contentChanged = true
                                }
                                .onChange(of: titleFieldFocused) { _, newValue in
                                    viewModel.onTitleFocusChanged(isFocused: newValue)
                                }
                        }
                    }
                    .padding(16)
                    .background(AppColors.cardBackground)
                    .cornerRadius(16)
                    .shadow(
                        color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.05),
                        radius: 3,
                        x: 0,
                        y: 2
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // タグセクション - ダークモード対応
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("タグ".localized, systemImage: "tag.fill")
                            .font(.headline)
                            .foregroundColor(AppColors.primaryText)
                        
                        Spacer()
                        
                        Button(action: {
                            showTagSelection = true
                        }) {
                            Label("新規タグ".localized, systemImage: "plus")
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(AppColors.accent.opacity(0.1))
                                .foregroundColor(AppColors.accent)
                                .cornerRadius(12)
                        }
                    }
                    
                    // タグリスト - 水平スクロール（ダークモード対応）
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(allTags) { tag in
                                Button(action: {
                                    toggleTag(tag)
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
                                        viewModel.selectedTags.contains(where: { $0.id == tag.id })
                                        ? tag.swiftUIColor().opacity(0.2)
                                        : (colorScheme == .dark ? Color(.systemGray5) : Color.white)
                                    )
                                    .foregroundColor(
                                        viewModel.selectedTags.contains(where: { $0.id == tag.id })
                                        ? tag.swiftUIColor()
                                        : AppColors.primaryText
                                    )
                                    .cornerRadius(16)
                                    .shadow(
                                        color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.05),
                                        radius: 2,
                                        x: 0,
                                        y: 1
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    
                    // 選択されたタグ - ダークモード対応
                    VStack(alignment: .leading, spacing: 8) {
                        if viewModel.selectedTags.isEmpty {
                            Text("選択中: なし".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("選択中:".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            // FlowLayoutではなく通常のScrollViewを使用
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(viewModel.selectedTags) { tag in
                                        HStack(spacing: 4) {
                                            Circle()
                                                .fill(tag.swiftUIColor())
                                                .frame(width: 8, height: 8)
                                            
                                            Text(tag.name ?? "")
                                                .font(.caption)
                                            
                                            Button(action: {
                                                removeTag(tag)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.gray)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(tag.swiftUIColor().opacity(colorScheme == .dark ? 0.15 : 0.1))
                                        .cornerRadius(10)
                                    }
                                }
                            }
                            .frame(height: 30) // 固定高さを設定
                        }
                    }
                    .padding(.top, 4) // 少し余白を追加
                }
                .padding(16)
                .background(AppColors.cardBackground)
                .cornerRadius(16)
                .shadow(
                    color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.05),
                    radius: 3,
                    x: 0,
                    y: 2
                )
                .padding(.horizontal, 16)
                
                // 記憶定着度セクション
                VStack(alignment: .leading, spacing: 12) {
                    Label("記憶定着度振り返り".localized, systemImage: "brain.head.profile")
                        .font(.headline)
                        .foregroundColor(AppColors.primaryText)
                    
                    ModernRecallSection(viewModel: viewModel)
                        .id("recallSliderSection")
                        .onChange(of: viewModel.recallScore) { _, _ in
                            viewModel.contentChanged = true
                            viewModel.recordActivityOnSave = true
                        }
                }
                .padding(16)
                .background(AppColors.cardBackground)
                .cornerRadius(16)
                .shadow(
                    color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.05),
                    radius: 3,
                    x: 0,
                    y: 2
                )
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 20)
        }
        .background(AppColors.groupedBackground)
        .onTapGesture {
            // キーボードを閉じる
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    // MARK: - ヘルパーメソッド
    
    // タグ選択のトグル
    private func toggleTag(_ tag: Tag) {
        if viewModel.selectedTags.contains(where: { $0.id == tag.id }) {
            // 解除
            removeTag(tag)
        } else {
            // 選択
            viewModel.selectedTags.append(tag)
            viewModel.contentChanged = true
            viewModel.recordActivityOnSave = true
            
            // タグ変更時に即時保存
            if memo != nil {
                DispatchQueue.main.async {
                    viewModel.updateAndSaveTags()
                }
            }
        }
    }
    
    // タグ削除
    private func removeTag(_ tag: Tag) {
        if let index = viewModel.selectedTags.firstIndex(where: { $0.id == tag.id }) {
            viewModel.selectedTags.remove(at: index)
            viewModel.contentChanged = true
            viewModel.recordActivityOnSave = true
            
            // タグ変更時に即時保存
            if memo != nil {
                DispatchQueue.main.async {
                    viewModel.updateAndSaveTags()
                }
            }
        }
    }
    
    // 戻るボタンのハンドリング
    private func handleBackButton() {
        if viewModel.contentChanged {
            showUnsavedChangesAlert = true
        } else {
            if memo == nil {
                viewModel.cleanupOrphanedQuestions()
            }
            dismiss()
        }
    }
    
    // 画面表示時の初期化
    private func handleOnAppear() {
        if let memo = memo {
            viewModel.startLearningSession()
        }
    }
    
    // 画面終了時の処理
    private func handleOnDisappear() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        if let memo = memo, let sessionId = viewModel.currentSessionId {
            if viewModel.contentChanged {
                let noteText = "復習セッション: %@".localizedFormat(memo.title ?? "無題".localized)
                
                let context = PersistenceController.shared.container.viewContext
                LearningActivity.recordActivityWithPrecision(
                    type: ActivityType.review,  // 完全修飾名を使用
                    durationSeconds: ActivityTracker.shared.getCurrentSessionDuration(sessionId: sessionId),  // 分から秒に変換
                    memo: memo,
                    note: noteText,
                    in: context
                )
            }
        }
    }

    // タグ選択画面閉じた後の処理
    private func handleTagSelectionDismiss() {
        if memo != nil {
            viewModel.updateAndSaveTags()
            viewModel.contentChanged = true
        }
    }

    // 問題エディタ閉じた後の処理
    private func handleQuestionEditorDismiss() {
        if let memo = memo {
            viewModel.loadComparisonQuestions(for: memo)
            viewModel.contentChanged = true
            viewModel.recordActivityOnSave = true
        }
    }
}

// フローレイアウト - タグ表示用の自動折り返しレイアウト
struct FlowLayout: Layout {
    var spacing: CGFloat = 10
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for view in subviews {
            let viewSize = view.sizeThatFits(.unspecified)
            if lineWidth + viewSize.width > width {
                height += lineHeight + spacing
                lineWidth = viewSize.width
                lineHeight = viewSize.height
            } else {
                lineWidth += viewSize.width + spacing
                lineHeight = max(lineHeight, viewSize.height)
            }
        }
        
        height += lineHeight
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        var lineStartIndex = 0
        
        for (index, view) in subviews.enumerated() {
            let viewSize = view.sizeThatFits(.unspecified)
            
            if lineWidth + viewSize.width > bounds.width && index > lineStartIndex {
                placeLine(in: bounds, from: lineStartIndex, to: index, subviews: subviews, lineHeight: lineHeight, y: lineWidth)
                lineWidth = viewSize.width + spacing
                lineHeight = viewSize.height
                lineStartIndex = index
            } else {
                lineWidth += viewSize.width + spacing
                lineHeight = max(lineHeight, viewSize.height)
            }
        }
        
        placeLine(in: bounds, from: lineStartIndex, to: subviews.count, subviews: subviews, lineHeight: lineHeight, y: lineWidth)
    }
    
    private func placeLine(in bounds: CGRect, from startIndex: Int, to endIndex: Int, subviews: Subviews, lineHeight: CGFloat, y: CGFloat) {
        var x = bounds.minX
        let yPosition = bounds.minY + y - lineHeight
        
        for index in startIndex..<endIndex {
            let viewSize = subviews[index].sizeThatFits(.unspecified)
            subviews[index].place(
                at: CGPoint(x: x, y: yPosition),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: viewSize.width, height: viewSize.height)
            )
            x += viewSize.width + spacing
        }
    }
}

// モダンな記憶定着度セクション
struct ModernRecallSection: View {
    @ObservedObject var viewModel: ContentViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            // パーセンテージと記憶状態
            HStack(alignment: .center) {
                // 記憶度表示 - より視覚的に魅力的なデザイン
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.recallScore) / 100)
                        .stroke(
                            AppColors.retentionColor(for: viewModel.recallScore),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 0) {
                        Text("\(Int(viewModel.recallScore))")
                            .font(.system(size: 24, weight: .bold))
                        Text("%")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(AppColors.retentionColor(for: viewModel.recallScore))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(retentionDescription(for: viewModel.recallScore))
                        .font(.headline)
                        .foregroundColor(AppColors.retentionColor(for: viewModel.recallScore))
                    
                    Text(retentionShortDescription(for: viewModel.recallScore))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                .padding(.leading, 8)
            }
            
            // 記憶度のスライダー - モダンでスタイリッシュなデザイン
            VStack(spacing: 12) {
                HStack {
                    Text("0%".localized)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Slider(value: Binding(
                        get: { Double(viewModel.recallScore).isNaN ? 50.0 : Double(viewModel.recallScore) },
                        set: {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            
                            viewModel.recallScore = Int16($0)
                            viewModel.contentChanged = true
                            viewModel.recordActivityOnSave = true
                            viewModel.updateNextReviewDate()
                        }
                    ), in: 0...100, step: 1)
                    .accentColor(AppColors.retentionColor(for: viewModel.recallScore))
                    
                    Text("100%".localized)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // スライダー下部のインジケーター
                HStack(spacing: 0) {
                    ForEach(0..<5) { i in
                        let level = i * 20
                        let isActive = viewModel.recallScore >= Int16(level)
                        
                        Rectangle()
                            .fill(isActive ? retentionColorForLevel(i) : Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2))
                            .frame(height: 4)
                            .cornerRadius(2)
                    }
                }
            }
            
            // 次回復習日があれば表示 - よりスタイリッシュなデザイン
            if let nextReviewDate = viewModel.reviewDate {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(AppColors.accent)
                        .font(.system(size: 16))
                    
                    Text("次回の推奨復習日:".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(viewModel.formattedDate(nextReviewDate))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.primaryText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppColors.accent.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(12)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    // レベルごとの色を返す
    private func retentionColorForLevel(_ level: Int) -> Color {
        switch level {
        case 4:
            return Color(red: 0.0, green: 0.7, blue: 0.3) // 緑
        case 3:
            return Color(red: 0.3, green: 0.7, blue: 0.0) // 黄緑
        case 2:
            return Color(red: 0.95, green: 0.6, blue: 0.1) // オレンジ
        case 1:
            return Color(red: 0.9, green: 0.45, blue: 0.0) // 濃いオレンジ
        default:
            return Color(red: 0.9, green: 0.2, blue: 0.2) // 赤
        }
    }
    
    // 記憶度に応じた簡潔な説明テキストを返す
    private func retentionDescription(for score: Int16) -> String {
        switch score {
        case 91...100:
            return "完璧に覚えた！".localized
        case 81...90:
            return "十分に理解できる".localized
        case 71...80:
            return "だいたい理解している".localized
        case 61...70:
            return "要点は覚えている".localized
        case 51...60:
            return "基本概念を思い出せる".localized
        case 41...50:
            return "断片的に覚えている".localized
        case 31...40:
            return "うっすらと覚えている".localized
        case 21...30:
            return "ほとんど忘れている".localized
        case 1...20:
            return "ほぼ完全に忘れている".localized
        default:
            return "全く覚えていない".localized
        }
    }
    
    // 記憶度に応じた短い説明テキストを返す
    private func retentionShortDescription(for score: Int16) -> String {
        switch score {
        case 81...100:
            return "長期記憶に定着しています".localized
        case 61...80:
            return "基本的な理解は定着しています".localized
        case 41...60:
            return "より頻繁な復習が必要です".localized
        case 21...40:
            return "基礎から再確認しましょう".localized
        default:
            return "もう一度学び直しましょう".localized
        }
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
