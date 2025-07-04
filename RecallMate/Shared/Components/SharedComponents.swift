// SharedComponents.swift
import SwiftUI
import CoreData

// MARK: - 日付情報ヘッダー
struct DayInfoHeader: View {
    let selectedDate: Date
    let memoCount: Int
    let selectedTags: [Tag]
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(dayDescription())
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("復習予定: \(memoCount)件")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if !selectedTags.isEmpty {
                HStack {
                    Text("フィルター適用中")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func dayDescription() -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(selectedDate) {
            return "今日の復習"
        } else if calendar.isDateInTomorrow(selectedDate) {
            return "明日の復習"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "昨日の復習"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日の復習"
            return formatter.string(from: selectedDate)
        }
    }
}

// MARK: - フローティング追加ボタン
struct FloatingAddButton: View {
    @Binding var isAddingMemo: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                Button(action: {
                    // ハプティックフィードバック
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    isAddingMemo = true
                }) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 64, height: 64)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(
                            color: Color.blue.opacity(colorScheme == .dark ? 0.4 : 0.3),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                }
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 0.2), value: isAddingMemo)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
    }
}
