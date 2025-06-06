// NewLearningFlowContent.swift - 新規学習フロー専用コンテンツ
import SwiftUI

struct NewLearningFlowContent: View {
    @Binding var newLearningStep: Int
    @Binding var newLearningTitle: String
    @Binding var newLearningContent: String
    @Binding var newLearningPageRange: String
    @Binding var newLearningTags: [Tag]
    @Binding var newLearningInitialScore: Int16
    @Binding var isSavingNewLearning: Bool
    @Binding var newLearningSaveSuccess: Bool
    let allTags: [Tag]
    let onClose: () -> Void
    let onExecuteCompletion: () -> Void
    let onSetupSession: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー部分
            HStack {
                Text(getNewLearningStepTitle())
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: onClose) {
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
                    contentInputStepView()
                } else if newLearningStep == 1 {
                    initialAssessmentStepView()
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
        .onAppear(perform: onSetupSession)
    }
    
    private func getNewLearningStepTitle() -> String {
        switch newLearningStep {
        case 0: return "学習内容の入力"
        case 1: return "理解度の評価"
        case 2: return "学習記録完了"
        default: return "新規学習フロー"
        }
    }
    
    @ViewBuilder
    private func contentInputStepView() -> some View {
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
                        VStack(alignment: .leading, spacing: 8) {
                            Text("タグ（任意）")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            if !allTags.isEmpty {
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
                            startPoint: UnitPoint.leading,
                            endPoint: UnitPoint.trailing
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
    private func initialAssessmentStepView() -> some View {
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
                    
                    HStack(spacing: 0) {
                        ForEach(0..<5) { i in
                            let level = i * 20
                            let isActive = newLearningInitialScore >= Int16(level)
                            
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
                Button(action: onExecuteCompletion) {
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
                            startPoint: UnitPoint.leading,
                            endPoint: UnitPoint.trailing
                        )
                    )
                    .cornerRadius(25)
                    .disabled(isSavingNewLearning)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            } else {
                Button(action: onClose) {
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
    
    // Helper methods
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
        case 91...100: return "完璧に理解しています！"
        case 81...90: return "十分に理解できています"
        case 71...80: return "だいたい理解しています"
        case 61...70: return "要点は理解しています"
        case 51...60: return "基本概念を理解しています"
        case 41...50: return "断片的に理解しています"
        case 31...40: return "うっすらと理解しています"
        case 21...30: return "ほとんど理解できていません"
        case 1...20: return "ほぼ理解できていません"
        default: return "全く理解できていません"
        }
    }
}
