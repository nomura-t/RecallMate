// NewLearningSheet.swift - 新規学習4ステップフロー
import SwiftUI
import CoreData

private enum NewLearningSheetType: String, Identifiable {
    case guide
    case presetEdit
    var id: String { rawValue }
}

struct NewLearningSheet: View {
    @ObservedObject var viewModel: NewLearningSheetViewModel
    @StateObject private var presetManager = TitlePresetManager.shared
    @FocusState private var titleFocused: Bool
    @State private var activeSheet: NewLearningSheetType?

    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()

            FlowContainerView {
                VStack(spacing: 0) {
                    // ヘッダー
                    headerView

                    // ステップコンテンツ
                    Group {
                        switch viewModel.currentStep {
                        case 0:
                            step0InputView
                        case 1:
                            step1ActiveRecallView
                        case 2:
                            step2AssessmentView
                        case 3:
                            step3CompletionView
                        default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                }
            }
        }
        .onChange(of: viewModel.showingGuide) { showing in
            if showing {
                activeSheet = .guide
                viewModel.showingGuide = false
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .guide:
                ActiveRecallGuideSheet()
                    .presentationDetents([.medium])
            case .presetEdit:
                TitlePresetEditSheet(presetManager: presetManager)
                    .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { viewModel.dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()

                if viewModel.currentStep == 0 {
                    Button(action: { activeSheet = .guide }) {
                        Image(systemName: "questionmark.circle")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }

                Text("ステップ \(viewModel.currentStep + 1) / 4")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)

            VStack(spacing: 12) {
                Text(viewModel.currentStepTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 4)

                        Rectangle()
                            .fill(viewModel.currentStepColor)
                            .frame(width: geometry.size.width * CGFloat(viewModel.currentStep + 1) / 4, height: 4)
                            .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 20)
            }
        }
        .padding(.top, 20)
    }

    // MARK: - Step 0: タイトル入力

    private var step0InputView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // プリセットチップ
                    presetChipsSection

                    // タイトル入力 + サジェスト
                    titleInputSection

                    // 章・ページ入力
                    chapterPageSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .scrollDismissesKeyboard(.interactively)

            // 次へボタン
            FlowActionButton(
                title: "次へ".localized,
                icon: "arrow.right.circle.fill",
                color: .blue,
                action: {
                    viewModel.showSuggestions = false
                    viewModel.proceedToStep1()
                }
            )
            .disabled(!viewModel.isTitleValid)
            .opacity(viewModel.isTitleValid ? 1.0 : 0.5)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .onAppear {
            titleFocused = true
        }
    }

    // MARK: - プリセットチップ

    private var presetChipsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "books.vertical.fill")
                    .foregroundColor(.blue)
                    .font(.caption)
                Text("教材プリセット".localized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Spacer()

                Button(action: { activeSheet = .presetEdit }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(presetManager.presets, id: \.self) { preset in
                        presetChip(preset)
                    }

                    // ＋追加ボタン
                    if viewModel.isTitleValid && !presetManager.presets.contains(viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines)) {
                        Button(action: {
                            presetManager.addPreset(viewModel.title)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.caption2)
                                Text("追加".localized)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                                    .foregroundColor(.blue.opacity(0.3))
                            )
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func presetChip(_ title: String) -> some View {
        let isSelected = viewModel.title == title
        return Button(action: {
            viewModel.title = title
            viewModel.showSuggestions = false
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
        .contextMenu {
            Button(role: .destructive, action: {
                presetManager.removePreset(title)
            }) {
                Label("削除".localized, systemImage: "trash")
            }
        }
    }

    // MARK: - タイトル入力 + サジェスト

    private var titleInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "pencil")
                    .foregroundColor(.blue)
                    .font(.caption)
                Text("学習タイトル".localized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }

            TextField("例: 英単語の暗記、数学の微分積分".localized, text: $viewModel.title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.body)
                .focused($titleFocused)
                .onChange(of: viewModel.title) { newValue in
                    viewModel.showSuggestions = !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                }

            // サジェスト候補
            let suggestions = viewModel.filteredSuggestions(for: viewModel.title)
            if viewModel.showSuggestions && !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button(action: {
                            viewModel.title = suggestion
                            viewModel.showSuggestions = false
                            titleFocused = false
                        }) {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(suggestion)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                        }

                        if suggestion != suggestions.last {
                            Divider()
                                .padding(.leading, 32)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
            }
        }
    }

    // MARK: - 章・ページ入力（ドラムロール）

    @State private var showChapterPagePicker = false

    private var chapterPageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 現在の選択をサマリー表示 + タップで展開
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showChapterPagePicker.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "book.pages")
                        .foregroundColor(.purple)
                        .font(.subheadline)

                    Text("章・ページ（任意）".localized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Spacer()

                    Text(chapterPageSummary)
                        .font(.subheadline)
                        .foregroundColor(.purple)

                    Image(systemName: showChapterPagePicker ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color(.systemBackground))
                .cornerRadius(10)
            }

            if showChapterPagePicker {
                HStack(spacing: 0) {
                    // 章ピッカー
                    VStack(spacing: 2) {
                        Text("章".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("", selection: $viewModel.selectedChapter) {
                            Text("-").tag(0)
                            ForEach(1...50, id: \.self) { n in
                                Text("\(n)").tag(n)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80, height: 120)
                        .clipped()
                    }

                    // 開始ページピッカー
                    VStack(spacing: 2) {
                        Text("開始p.".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("", selection: $viewModel.pageStart) {
                            Text("-").tag(0)
                            ForEach(1...500, id: \.self) { n in
                                Text("\(n)").tag(n)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80, height: 120)
                        .clipped()
                    }

                    Text("〜")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 16)

                    // 終了ページピッカー
                    VStack(spacing: 2) {
                        Text("終了p.".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("", selection: $viewModel.pageEnd) {
                            Text("-").tag(0)
                            ForEach(1...500, id: \.self) { n in
                                Text("\(n)").tag(n)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80, height: 120)
                        .clipped()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var chapterPageSummary: String {
        let result = viewModel.buildPageRangeString()
        return result.isEmpty ? "未設定".localized : result
    }

    // MARK: - Step 1: アクティブリコール

    private var step1ActiveRecallView: some View {
        ActiveRecallStepView(
            memoTitle: viewModel.title,
            microStep: $viewModel.microStep,
            elapsedTime: viewModel.elapsedTime,
            onComplete: { viewModel.proceedToStep2() }
        )
    }

    // MARK: - Step 2: 理解度評価

    private var step2AssessmentView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // メモリ評価スライダー
                    MemoryAssessmentView(
                        score: $viewModel.recallScore,
                        scoreLabel: "理解度を評価してください".localized,
                        color: getRetentionColor
                    )

                    // 復習日表示
                    reviewDateSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }

            // 保存ボタン
            FlowActionButton(
                title: "保存する".localized,
                icon: "checkmark.circle.fill",
                color: .orange,
                action: { Task { await viewModel.save() } }
            )
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

    // MARK: - Step 3: 保存完了

    private var step3CompletionView: some View {
        VStack(spacing: 24) {
            Spacer()

            // アイコン
            Image(systemName: viewModel.isSaving ? "clock.fill" : "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(viewModel.isSaving ? .orange : .green)
                .scaleEffect(viewModel.isSaving ? 0.8 : 1.0)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: viewModel.isSaving)

            Text(viewModel.isSaving ? "保存中...".localized : "学習を記録しました！".localized)
                .font(.title)
                .fontWeight(.bold)

            if viewModel.saveSuccess {
                VStack(spacing: 12) {
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

                    // 理解度スコア
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(getRetentionColor(for: viewModel.recallScore))
                        Text("理解度".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(viewModel.recallScore))%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(getRetentionColor(for: viewModel.recallScore))
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

            // 閉じるボタン
            if viewModel.saveSuccess {
                FlowActionButton(
                    title: "閉じる".localized,
                    icon: "checkmark.circle.fill",
                    color: .green,
                    action: { viewModel.dismiss() }
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
}
