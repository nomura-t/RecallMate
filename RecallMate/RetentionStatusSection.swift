import SwiftUI

struct RetentionStatusSection: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        Section {
            // 記憶度ステータスカード
            RetentionStatusCard(retentionPercentage: Int(viewModel.recallScore))
                .padding(.vertical, 8)
            
            // 次回の復習日の表示
            if let nextReviewDate = viewModel.reviewDate {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(.blue)
                    
                    Text("次回の推奨復習日:")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(viewModel.formattedDate(nextReviewDate))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        } header: {
            Text("記憶定着状況")
        }
    }
}
