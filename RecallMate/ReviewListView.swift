import SwiftUI

struct ReviewListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isAddingMemo = false

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Memo.nextReviewDate, ascending: true)],
        animation: .default)
    private var memos: FetchedResults<Memo>

    var body: some View {
        NavigationStack {
            ZStack {
                List(memos) { memo in
                    NavigationLink(destination: ContentView(memo: memo)) {
                        ReviewListItem(memo: memo)
                    }
                }
                .navigationTitle("復習リスト")
                .onAppear {
                    viewContext.refreshAllObjects()  // 🔄 データをリロード！
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { isAddingMemo = true }) {
                            Image(systemName: "brain.head.profile")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding()
                        .fullScreenCover(isPresented: $isAddingMemo) {
                            ContentView(memo: nil)
                        }
                    }
                }
            }
        }
    }
}
