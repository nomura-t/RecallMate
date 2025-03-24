import SwiftUI

struct RecallSliderSection: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        Section(header: Text("記憶度")) {
            Text("記憶度: \(viewModel.recallScore)%")
            Slider(value: Binding(
                get: { Double(viewModel.recallScore).isNaN ? 50.0 : Double(viewModel.recallScore) },
                set: { viewModel.recallScore = Int16($0) }
            ), in: 0...100, step: 1)
        }
    }
}
