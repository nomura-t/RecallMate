// SharedComponents.swift
import SwiftUI
import CoreData

//// MARK: - 日付選択カレンダー
//struct DatePickerCalendarView: View {
//    @Binding var selectedDate: Date
//    @Environment(\.colorScheme) var colorScheme
//    
//    var body: some View {
//        VStack(spacing: 12) {
//            Text(formattedSelectedDate())
//                .font(.title2)
//                .fontWeight(.bold)
//                .foregroundColor(.primary)
//            
//            DatePicker(
//                "",
//                selection: $selectedDate,
//                displayedComponents: .date
//            )
//            .datePickerStyle(.compact)
//            .accentColor(.blue)
//        }
//    }
//    
//    private func formattedSelectedDate() -> String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "M月d日 (E)"
//        formatter.locale = Locale(identifier: "ja_JP")
//        return formatter.string(from: selectedDate)
//    }
//}

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

// MARK: - 空の状態ビュー
struct EmptyStateView: View {
    let selectedDate: Date
    let hasTagFilter: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.6))
            
            VStack(spacing: 8) {
                Text(emptyStateTitle())
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(emptyStateMessage())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 60)
        .padding(.horizontal, 32)
    }
    
    private func emptyStateTitle() -> String {
        if hasTagFilter {
            return "該当する記録がありません"
        } else if Calendar.current.isDateInToday(selectedDate) {
            return "今日の復習はありません"
        } else {
            return "この日の復習予定はありません"
        }
    }
    
    private func emptyStateMessage() -> String {
        if hasTagFilter {
            return "選択されたタグの組み合わせに一致する記録がありません。フィルターを変更してみてください。"
        } else if Calendar.current.isDateInToday(selectedDate) {
            return "素晴らしいです！今日の復習は完了しています。新しい記録を作成して学習を続けましょう。"
        } else {
            return "この日は復習予定の記録がありません。"
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
