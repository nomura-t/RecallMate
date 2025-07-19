import SwiftUI

struct LoadingOverlay: View {
    let message: String
    
    init(message: String = "読み込み中...") {
        self.message = message
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle())
                    .tint(.white)
                
                Text(message)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(Color.black.opacity(0.8))
            .cornerRadius(16)
        }
    }
}

// MARK: - View Extension

extension View {
    func loadingOverlay(isLoading: Bool, message: String = "読み込み中...") -> some View {
        self.overlay {
            if isLoading {
                LoadingOverlay(message: message)
            }
        }
    }
}

// MARK: - Preview

struct LoadingOverlay_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("Background Content")
        }
        .loadingOverlay(isLoading: true)
    }
}