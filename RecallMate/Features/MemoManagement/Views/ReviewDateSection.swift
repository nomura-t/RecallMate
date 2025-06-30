import SwiftUI

struct ReviewDateSection: View {
    @ObservedObject var viewModel: ContentViewModel
    @Binding var showDatePicker: Bool
    
    var body: some View {
        Section(header: Text("復習日".localized)) {
            HStack {
                Text(viewModel.reviewDate != nil ? viewModel.formattedDate(viewModel.reviewDate) : "未設定".localized)
                Spacer()
                Button(action: { showDatePicker.toggle() }) {
                    Image(systemName: "calendar")
                }
            }
            if showDatePicker {
                DatePicker("復習日を選択".localized, selection: Binding(
                    get: { viewModel.reviewDate ?? Date() },
                    set: { viewModel.reviewDate = $0 }
                ), displayedComponents: .date)
                .datePickerStyle(.graphical)
            }
        }
    }
}
