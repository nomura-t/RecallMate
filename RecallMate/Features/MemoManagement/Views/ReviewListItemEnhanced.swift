// ReviewListItemEnhanced.swift - Modern enhanced review list item with responsive design
import SwiftUI

struct ReviewListItemEnhanced: View {
    let memo: Memo
    let selectedDate: Date
    let isCompact: Bool
    let onStartReview: () -> Void
    let onOpenMemo: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false
    
    // レスポンシブデザイン用の計算プロパティ
    private var cardPadding: CGFloat {
        isCompact ? 16 : 20
    }
    
    private var verticalSpacing: CGFloat {
        isCompact ? 12 : 16
    }
    
    private var buttonHeight: CGFloat {
        isCompact ? 44 : 52
    }
    
    private var iconSize: CGFloat {
        isCompact ? 18 : 20
    }
    
    // 日付関連の計算プロパティ
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
    
    private var priorityLevel: Int {
        if isOverdue && daysOverdue > 3 { return 3 } // 高優先度
        if isOverdue || isDueToday { return 2 } // 中優先度
        return 1 // 通常
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // メインコンテンツカード
            mainContentCard
            
            // アクションボタンエリア
            actionButtonsArea
        }
        .background(cardBackground)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
    
    // MARK: - Main Content Card
    private var mainContentCard: some View {
        Button(action: onOpenMemo) {
            VStack(spacing: verticalSpacing) {
                // ヘッダー行（タイトル + 記憶度）
                headerSection
                
                // メタ情報行（ページ範囲 + 復習日）
                metaInfoSection
                
                // タグセクション（もしある場合）
                if !memo.tagsArray.isEmpty {
                    tagsSection
                }
                
                // プログレスバー
                progressBarSection
            }
            .padding(cardPadding)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0) {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
        } onPressingChanged: { pressing in
            if !pressing {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                // 優先度インジケーター + タイトル
                HStack(spacing: 8) {
                    if priorityLevel > 1 {
                        priorityIndicator
                    }
                    
                    Text(memo.title ?? "無題".localized)
                        .font(isCompact ? .subheadline : .headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                // 学習統計のサブ情報
                if memo.perfectRecallCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        
                        Text("完璧な復習: %d回".localizedWithInt(Int(memo.perfectRecallCount)))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // 記憶度サークル
            memoryScoreCircle
        }
    }
    
    // MARK: - Priority Indicator
    private var priorityIndicator: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(priorityColor.opacity(0.8))
            .frame(width: 4, height: isCompact ? 20 : 24)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(priorityColor, lineWidth: 1)
            )
    }
    
    // MARK: - Memory Score Circle
    private var memoryScoreCircle: some View {
        ZStack {
            // 背景サークル
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: isCompact ? 3 : 4)
            
            // プログレス サークル
            Circle()
                .trim(from: 0, to: CGFloat(memo.recallScore) / 100)
                .stroke(
                    progressColor(for: memo.recallScore),
                    style: StrokeStyle(
                        lineWidth: isCompact ? 3 : 4,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: memo.recallScore)
            
            // 中央のテキスト
            VStack(spacing: 0) {
                Text("\(memo.recallScore)")
                    .font(isCompact ? .caption : .caption)
                    .fontWeight(.bold)
                    .foregroundColor(progressColor(for: memo.recallScore))
                
                Text("%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: isCompact ? 44 : 52, height: isCompact ? 44 : 52)
    }
    
    // MARK: - Meta Info Section
    private var metaInfoSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                // ページ範囲
                if let pageRange = memo.pageRange, !pageRange.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(pageRange)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 復習日情報
                HStack(spacing: 4) {
                    Image(systemName: reviewDateIcon)
                        .font(.caption2)
                        .foregroundColor(reviewDateColor)
                    
                    Text(reviewDateText)
                        .font(.caption)
                        .foregroundColor(reviewDateColor)
                }
                
                // 期限超過情報
                if isOverdue && daysOverdue > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        
                        Text("復習期限 %d日超過".localizedWithInt(daysOverdue))
                            .font(.caption)
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                    }
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Tags Section
    private var tagsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(memo.tagsArray.prefix(isCompact ? 3 : 5), id: \.id) { tag in
                    tagChip(for: tag)
                }
                
                if memo.tagsArray.count > (isCompact ? 3 : 5) {
                    HStack(spacing: 2) {
                        Image(systemName: "ellipsis")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("+\(memo.tagsArray.count - (isCompact ? 3 : 5))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 1) // スクロール時の切れ防止
        }
    }
    
    private func tagChip(for tag: Tag) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(tag.swiftUIColor())
                .frame(width: 6, height: 6)
            
            Text(tag.name ?? "")
                .font(.caption2)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tag.swiftUIColor().opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Progress Bar Section
    private var progressBarSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("記憶定着度".localized)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(memo.recallScore)%")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(progressColor(for: memo.recallScore))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景バー
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                    
                    // プログレスバー
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    progressColor(for: memo.recallScore),
                                    progressColor(for: memo.recallScore).opacity(0.7)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * CGFloat(memo.recallScore) / 100,
                            height: 6
                        )
                        .animation(.easeInOut(duration: 0.8), value: memo.recallScore)
                }
            }
            .frame(height: 6)
        }
    }
    
    // MARK: - Action Buttons Area
    private var actionButtonsArea: some View {
        HStack(spacing: 12) {
            // メイン復習ボタン
            Button(action: onStartReview) {
                HStack(spacing: 8) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: iconSize))
                    
                    Text(actionButtonText)
                        .font(isCompact ? .subheadline : .headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: buttonHeight)
                .background(actionButtonGradient)
                .cornerRadius(buttonHeight / 2)
                .shadow(
                    color: actionButtonShadowColor,
                    radius: 4,
                    x: 0,
                    y: 2
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // 詳細ボタン
            Button(action: onOpenMemo) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: iconSize - 2))
                    .foregroundColor(.blue)
                    .frame(width: buttonHeight, height: buttonHeight)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(buttonHeight / 2)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, cardPadding)
        .padding(.bottom, cardPadding)
    }
    
    // MARK: - Card Background
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: isCompact ? 16 : 20)
            .fill(cardBackgroundColor)
            .shadow(
                color: cardShadowColor,
                radius: isPressed ? 1 : (colorScheme == .dark ? 4 : 3),
                x: 0,
                y: isPressed ? 1 : (colorScheme == .dark ? 3 : 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: isCompact ? 16 : 20)
                    .stroke(cardBorderColor, lineWidth: priorityLevel > 2 ? 2 : 0)
            )
    }
    
    // MARK: - Computed Properties for Styling
    
    private var priorityColor: Color {
        switch priorityLevel {
        case 3: return .red
        case 2: return .orange
        default: return .blue
        }
    }
    
    private var reviewDateIcon: String {
        if isOverdue { return "clock.badge.exclamationmark" }
        if isDueToday { return "calendar.badge.clock" }
        return "calendar"
    }
    
    private var reviewDateColor: Color {
        if isOverdue { return .red }
        if isDueToday { return .orange }
        return .secondary
    }
    
    private var reviewDateText: String {
        if isOverdue {
            return "復習期限: %@".localizedFormat(formattedDate(memo.nextReviewDate))
        } else if isDueToday {
            return "今日が復習日".localized
        } else {
            return "復習予定: %@".localizedFormat(formattedDate(memo.nextReviewDate))
        }
    }
    
    private var actionButtonText: String {
        if isOverdue && daysOverdue > 0 {
            return "復習する".localized
        } else if isDueToday {
            return "復習開始".localized
        } else {
            return "復習する".localized
        }
    }
    
    private var actionButtonGradient: LinearGradient {
        let baseColor = priorityColor
        return LinearGradient(
            gradient: Gradient(colors: [baseColor, baseColor.opacity(0.8)]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var actionButtonShadowColor: Color {
        priorityColor.opacity(0.3)
    }
    
    private var cardBackgroundColor: Color {
        if priorityLevel > 2 {
            return Color.red.opacity(colorScheme == .dark ? 0.15 : 0.05)
        } else if priorityLevel > 1 {
            return Color.orange.opacity(colorScheme == .dark ? 0.15 : 0.05)
        } else {
            return colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground)
        }
    }
    
    private var cardShadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.4) : Color.black.opacity(0.1)
    }
    
    private var cardBorderColor: Color {
        if priorityLevel > 2 {
            return Color.red.opacity(0.3)
        } else {
            return Color.clear
        }
    }
    
    // MARK: - Helper Methods
    
    private func progressColor(for score: Int16) -> Color {
        switch score {
        case 85...100: return Color.green
        case 70...84: return Color.blue
        case 50...69: return Color.orange
        case 30...49: return Color.red.opacity(0.8)
        default: return Color.red
        }
    }
    
    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "未定".localized }
        
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "今日".localized
        } else if calendar.isDateInTomorrow(date) {
            return "明日".localized
        } else if calendar.isDateInYesterday(date) {
            return "昨日".localized
        } else {
            let daysFromNow = calendar.dateComponents([.day], from: Date(), to: date).day ?? 0
            
            if abs(daysFromNow) <= 7 {
                formatter.dateStyle = .none
                formatter.setLocalizedDateFormatFromTemplate("EEEE")
                return formatter.string(from: date)
            } else {
                formatter.dateStyle = .short
                return formatter.string(from: date)
            }
        }
    }
}