// TodayStudyTimeSection.swift - 新規作成
import SwiftUI

struct TodayStudyTimeSection: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("今日の学習時間".localized)
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
    }
}
