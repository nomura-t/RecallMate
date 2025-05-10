// HomeView.swift
import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // 複数タグ選択をサポートするため配列に変更
    @State private var selectedTags: [Tag] = []
    // 日付フォーマッター
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    // UIの更新を強制するためのトリガー
    @State private var refreshTrigger = UUID()
    
    // メモの取得リクエスト
    @FetchRequest(
        entity: Memo.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Memo.nextReviewDate, ascending: true)],
        animation: .default)
    private var memos: FetchedResults<Memo>
    
    // タグのFetchRequest
    @FetchRequest(
        entity: Tag.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)],
        animation: .default)
    private var allTags: FetchedResults<Tag>

    @Binding var isAddingMemo: Bool

    // 表示するメモのリスト（タグによるフィルタリング適用）
    private var displayedMemos: [Memo] {
        if selectedTags.isEmpty {
            return Array(memos)
        } else {
            // 「かつ」条件 - 選択したすべてのタグを持つメモだけを表示
            return Array(memos).filter { memo in
                // すべての選択されたタグを含むかチェック
                for tag in selectedTags {
                    if !memo.tagsArray.contains(where: { $0.id == tag.id }) {
                        return false  // 1つでも含まれていないタグがあればこのメモは除外
                    }
                }
                return true  // すべての選択タグを含む場合のみtrue
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                // タグリスト（水平スクロール）
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // 「すべて」ボタン（タグをクリア）
                        Button(action: {
                            selectedTags = []
                        }) {
                            Text("すべて".localized)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedTags.isEmpty ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(selectedTags.isEmpty ? .white : .primary)
                                .cornerRadius(16)
                        }
                        
                        // タグボタン（複数選択を可能に）
                        ForEach(allTags) { tag in
                            Button(action: {
                                // タグの選択/解除のトグル
                                if let index = selectedTags.firstIndex(where: { $0.id == tag.id }) {
                                    // 既に選択されている場合は解除
                                    selectedTags.remove(at: index)
                                } else {
                                    // 選択されていない場合は追加
                                    selectedTags.append(tag)
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(tag.swiftUIColor())
                                        .frame(width: 8, height: 8)
                                    
                                    Text(tag.name ?? "")
                                        .font(.subheadline)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    selectedTags.contains(where: { $0.id == tag.id })
                                    ? tag.swiftUIColor().opacity(0.2)
                                    : Color.gray.opacity(0.15)
                                )
                                .foregroundColor(
                                    selectedTags.contains(where: { $0.id == tag.id })
                                    ? tag.swiftUIColor()
                                    : .primary
                                )
                                .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                // 選択されたタグの表示（複数選択されている場合）
                if selectedTags.count > 0 {
                    HStack {
                        if selectedTags.count == 1 {
                            Text("フィルター:".localized)
                                .font(.caption)
                                .foregroundColor(.gray)
                        } else {
                            Text("フィルター（すべてを含む）:".localized)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(selectedTags) { tag in
                                    HStack(spacing: 2) {
                                        Circle()
                                            .fill(tag.swiftUIColor())
                                            .frame(width: 6, height: 6)
                                        
                                        Text(tag.name ?? "")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(tag.swiftUIColor().opacity(0.1))
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .frame(height: 20)
                        
                        // タグ選択クリアボタン
                        Button(action: {
                            selectedTags = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 4)
                }
                
                HStack(spacing: 8) {
                    StreakCardView()
                        .frame(maxWidth: .infinity)
                        .frame(width: 100)
                    HabitChallengeCardView()
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 5)
                
                if displayedMemos.isEmpty {
                    // フィルター適用後メモがない場合の表示
                    if !selectedTags.isEmpty {
                        VStack(spacing: 20) {
                            Text("条件に一致するメモがありません".localized)
                                .font(.headline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                            
                            Button(action: {
                                selectedTags = []
                            }) {
                                Text("フィルターをクリア".localized)
                                    .foregroundColor(.blue)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    } else {
                        // そもそもメモがない場合
                        VStack(spacing: 20) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text("メモはまだありません".localized)
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Text("右下のボタンからメモを追加できます".localized)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    }
                } else {
                    // メモリスト
                    List {
                        ForEach(displayedMemos, id: \.id) { memo in
                            NavigationLink(destination: ContentView(memo: memo)) {
                                ReviewListItem(memo: memo)
                            }
                        }
                        .onDelete(perform: deleteMemo)
                    }
                    .id(refreshTrigger) // リストの強制リフレッシュ用
                    .listStyle(.plain)
                    .padding(.bottom, 20)
                    .refreshable {
                        // リストを手動で更新
                        forceRefreshData()
                    }
                }
            }
            .onAppear {
                forceRefreshData()
            }
            .overlay(
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            isAddingMemo = true
                        }) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 40))
                                .padding()
                                .background(Color.blue.opacity(0.8))
                                .foregroundColor(.white)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding()
                    }
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ForceRefreshMemoData"))) { _ in
            // 更新処理の前に少し遅延を入れる
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                forceRefreshData()
            }
        }
    }
    
    // データを強制的に更新するメソッド
    private func forceRefreshData() {
        // 習慣化チャレンジの進捗をチェック
        HabitChallengeManager.shared.checkDailyProgress()
        
        // 進行中のタスクがあれば明示的にキャンセル
        viewContext.rollback()
        
        viewContext.refreshAllObjects()
        
        // UI更新トリガー
        refreshTrigger = UUID()
    }
    
    private func deleteMemo(offsets: IndexSet) {
        withAnimation {
            offsets.map { displayedMemos[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
                
                // 削除後に表示を更新
                refreshTrigger = UUID()
            } catch {
                // エラー処理
            }
        }
    }
}
