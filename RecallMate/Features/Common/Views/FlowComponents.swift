import SwiftUI

// MARK: - Helper Functions for Memory Assessment
func getRetentionColor(for score: Int16) -> Color {
    switch score {
    case 0..<20:
        return .red
    case 20..<40:
        return .orange
    case 40..<60:
        return .yellow
    case 60..<80:
        return Color(red: 0.5, green: 0.8, blue: 0)
    case 80...100:
        return .green
    default:
        return .gray
    }
}

func formatElapsedTime(_ timeInterval: TimeInterval) -> String {
    let minutes = Int(timeInterval) / 60
    let seconds = Int(timeInterval) % 60
    return String(format: "%02d:%02d", minutes, seconds)
}

func formatDateForDisplay(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter.string(from: date)
}

// MARK: - 共通フローヘッダー
struct FlowHeaderView: View {
    let currentStep: Int
    let totalSteps: Int
    let stepTitle: String
    let stepColor: Color
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Text("ステップ \(currentStep + 1) / \(totalSteps)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                Text(stepTitle)
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
                            .fill(stepColor)
                            .frame(width: geometry.size.width * CGFloat(currentStep + 1) / CGFloat(totalSteps), height: 4)
                            .animation(.easeInOut(duration: 0.3), value: currentStep)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 20)
            }
        }
        .padding(.top, 20)
    }
}

// MARK: - 共通フローボタン
struct FlowActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let isLoading: Bool
    let action: () -> Void
    
    init(
        title: String,
        icon: String = "arrow.right.circle.fill",
        color: Color = .blue,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .tint(.white)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                }
                
                Text(title)
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [color, color.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(25)
        }
        .disabled(isLoading)
    }
}

// MARK: - 共通フローコンテナ
struct FlowContainerView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.height < 700 // SE第二世代対応
            
            if isCompact {
                // コンパクトデバイス用レイアウト
                ScrollView {
                    VStack(spacing: 0) {
                        content
                            .padding(.bottom, 20)
                    }
                }
                .scrollDismissesKeyboard(.immediately)
            } else {
                // 通常デバイス用レイアウト
                VStack(spacing: 0) {
                    content
                }
            }
        }
    }
}

// MARK: - メモリ評価ビュー（共通）
struct MemoryAssessmentView: View {
    @Binding var score: Int16
    let scoreLabel: String
    let color: (Int16) -> Color
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 24) {
            Text(scoreLabel)
                .font(.title3)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2), lineWidth: 12)
                    .frame(width: 180, height: 180)
                
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100)
                    .stroke(
                        color(score),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: score)
                
                VStack(spacing: 4) {
                    Text("\(Int(score))")
                        .font(.system(size: 48, weight: .bold))
                    Text("%")
                        .font(.system(size: 20))
                }
                .foregroundColor(color(score))
            }
            
            Text(getRetentionDescription(for: score))
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(color(score))
                .multilineTextAlignment(.center)
                .animation(.easeInOut(duration: 0.2), value: score)
            
            VStack(spacing: 16) {
                HStack {
                    Text("0%")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Slider(value: Binding(
                        get: { Double(score) },
                        set: { newValue in
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            score = Int16(newValue)
                        }
                    ), in: 0...100, step: 1)
                    .accentColor(color(score))
                    
                    Text("100%")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                HStack(spacing: 0) {
                    ForEach(0..<5) { i in
                        let level = i * 20
                        let isActive = score >= Int16(level)
                        
                        Rectangle()
                            .fill(isActive ? getRetentionColorForLevel(i) : Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2))
                            .frame(height: 6)
                            .cornerRadius(3)
                    }
                }
            }
        }
    }
}

// MARK: - 日付選択ビュー（共通）
struct DateSelectionView: View {
    @Binding var selectedDate: Date
    let defaultDate: Date
    let title: String
    let icon: String?
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 60))
                        .foregroundColor(.indigo)
                }
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                Text("日付を選択".localized)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                DatePicker(
                    "",
                    selection: $selectedDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(height: 200)
                
                Button(action: {
                    selectedDate = defaultDate
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14))
                        Text("推奨日に戻す".localized)
                            .font(.subheadline)
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - 完了ビュー（共通）
struct CompletionView: View {
    let title: String
    let subtitle: String?
    let icon: String
    let color: Color
    let isSaving: Bool
    let saveSuccess: Bool
    let additionalInfo: AnyView?
    
    init(
        title: String,
        subtitle: String? = nil,
        icon: String = "checkmark.circle.fill",
        color: Color = .green,
        isSaving: Bool = false,
        saveSuccess: Bool = false,
        @ViewBuilder additionalInfo: () -> some View = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.isSaving = isSaving
        self.saveSuccess = saveSuccess
        self.additionalInfo = AnyView(additionalInfo())
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: isSaving ? "clock.fill" : (saveSuccess ? icon : "sparkles"))
                .font(.system(size: 80))
                .foregroundColor(isSaving ? .orange : (saveSuccess ? color : color))
                .scaleEffect(isSaving ? 0.8 : 1.0)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isSaving)
            
            Text(isSaving ? "保存中...".localized : (saveSuccess ? title : title))
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            
            if let additionalInfo = additionalInfo {
                additionalInfo
            }
            
            if saveSuccess {
                Text("結果が正常に保存されました".localized)
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .padding(.top, 8)
            }
        }
    }
}

// MARK: - Helper Functions
func getRetentionDescription(for score: Int16) -> String {
    switch score {
    case 0..<20:
        return "ほとんど覚えていない".localized
    case 20..<40:
        return "少し覚えている".localized
    case 40..<60:
        return "半分くらい覚えている".localized
    case 60..<80:
        return "だいたい覚えている".localized
    case 80...100:
        return "しっかり覚えている".localized
    default:
        return ""
    }
}

func getRetentionColorForLevel(_ level: Int) -> Color {
    switch level {
    case 0: return .red
    case 1: return .orange
    case 2: return .yellow
    case 3: return Color(red: 0.5, green: 0.8, blue: 0)
    case 4: return .green
    default: return .gray
    }
}