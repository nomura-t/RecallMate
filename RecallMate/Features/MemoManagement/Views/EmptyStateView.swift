// EmptyStateView.swift - シンプルな抽出版
import SwiftUI

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
