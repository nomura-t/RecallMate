import SwiftUI
import CoreData
import Charts

struct RetentionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // タグフィルタリング用
    @State private var selectedTag: Tag? = nil
    
    // 「かつ/または」条件は残しつつも、UI簡素化のため初期表示では隠す
    @State private var isAndCondition = true
    @State private var showAdvancedFilter = false
    
    // 高度なフィルタリング用（複数タグ）
    @State private var selectedTags: [Tag] = []
    @State private var showingTagPicker = false
    
    enum ChartType {
        case bar
        case pie
    }
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Memo.lastReviewedDate, ascending: false)],
        animation: .default)
    private var memos: FetchedResults<Memo>
    
    // タグのFetchRequest
    @FetchRequest(
        entity: Tag.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)],
        animation: .default)
    private var allTags: FetchedResults<Tag>
    
    // フィルタリングされたメモ
    private var filteredMemos: [Memo] {
        if selectedTag != nil {
            // 単一タグフィルタリング（シンプルモード）
            return Array(memos).filter { memo in
                memo.tagsArray.contains { $0.id == selectedTag!.id }
            }
        } else if !selectedTags.isEmpty && showAdvancedFilter {
            // 複数タグフィルタリング（高度なモード）
            return Array(memos).filter { memo in
                if isAndCondition {
                    // 「かつ」条件 - 選択されたすべてのタグを持つメモを表示
                    for tag in selectedTags {
                        if !memo.tagsArray.contains(where: { $0.id == tag.id }) {
                            return false  // 1つでも含まれていないタグがあれば除外
                        }
                    }
                    return true  // すべてのタグを含む
                } else {
                    // 「または」条件 - いずれかのタグを持つメモを表示
                    for tag in selectedTags {
                        if memo.tagsArray.contains(where: { $0.id == tag.id }) {
                            return true
                        }
                    }
                    return false
                }
            }
        } else {
            return Array(memos)
        }
    }
    
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if memos.isEmpty {
                    emptyStateView
                } else {
                    // タグリスト（水平スクロール）
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // 「すべて」ボタン
                            Button(action: {
                                selectedTag = nil
                                // 複数選択モードのタグもクリア
                                if showAdvancedFilter {
                                    selectedTags = []
                                }
                            }) {
                                Text("すべて".localized)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedTag == nil && selectedTags.isEmpty ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedTag == nil && selectedTags.isEmpty ? .white : .primary)
                                    .cornerRadius(16)
                            }
                            
                            // タグボタン
                            ForEach(allTags) { tag in
                                Button(action: {
                                    if showAdvancedFilter {
                                        // 高度なフィルターモードでは複数選択を許可
                                        if let index = selectedTags.firstIndex(where: { $0.id == tag.id }) {
                                            selectedTags.remove(at: index)
                                        } else {
                                            selectedTags.append(tag)
                                        }
                                    } else {
                                        // 単一タグモード
                                        if selectedTag?.id == tag.id {
                                            // 同じタグをタップしたらフィルターを解除
                                            selectedTag = nil
                                        } else {
                                            // タグを選択
                                            selectedTag = tag
                                        }
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
                                        showAdvancedFilter
                                            ? (selectedTags.contains(where: { $0.id == tag.id }) ? tag.swiftUIColor().opacity(0.2) : Color.gray.opacity(0.15))
                                            : (selectedTag?.id == tag.id ? tag.swiftUIColor().opacity(0.2) : Color.gray.opacity(0.15))
                                    )
                                    .foregroundColor(
                                        showAdvancedFilter
                                            ? (selectedTags.contains(where: { $0.id == tag.id }) ? tag.swiftUIColor() : .primary)
                                            : (selectedTag?.id == tag.id ? tag.swiftUIColor() : .primary)
                                    )
                                    .cornerRadius(16)
                                }
                            }
                            
                            // 高度なフィルターモードの切り替えボタン
                            Button(action: {
                                showAdvancedFilter.toggle()
                                if showAdvancedFilter {
                                    // 高度なモードに切り替え時、現在選択中のタグがあればそれを初期選択に
                                    if let tag = selectedTag {
                                        selectedTags = [tag]
                                        selectedTag = nil
                                    }
                                } else {
                                    // シンプルモードに戻す時、複数選択の場合は最初のタグだけを選択
                                    if let firstTag = selectedTags.first {
                                        selectedTag = firstTag
                                    }
                                    selectedTags = []
                                }
                            }) {
                                Image(systemName: showAdvancedFilter ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 22))
                            }
                            .padding(.leading, 4)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    
                    // 高度なフィルターモードの追加コントロール
                    if showAdvancedFilter && !selectedTags.isEmpty {
                        HStack(spacing: 12) {
                            Text("フィルター条件:".localized)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Picker("", selection: $isAndCondition) {
                                Text("すべて含む (AND)".localized).tag(true)
                                Text("いずれか含む (OR)".localized).tag(false)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 220)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                    
                    // メモリスト
                    List {
                        // メモリスト
                        Section(header: Text("メモの記憶定着度".localized)
                            .frame(maxWidth: .infinity, alignment: .trailing)  // 右寄せにする
                            .padding(.trailing, 16)  // 右側に少し余白を追加
                        ) {
                            if filteredMemos.isEmpty {
                                Text("条件に一致するメモがありません".localized)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .italic()
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                ForEach(filteredMemos) { memo in
                                    retentionRow(for: memo)
                                        .padding(.vertical, 4)
                                }
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)) // リスト行のインセットを最小限に
                    }
                    .listStyle(PlainListStyle()) // プレーンスタイルを使用
                    .environment(\.horizontalSizeClass, .regular) // 横幅を広く見せる

                }
            }
            .navigationTitle("")
        }
    }
    
    // 空の状態表示
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("メモがありません".localized)
                .font(.title2)
                .fontWeight(.medium)
            
            Text("「ホーム」タブから新しいメモを追加して\n学習を記録しましょう".localized)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding(.top, 100)
    }
    
    // 各メモの記憶定着度表示行
    private func retentionRow(for memo: Memo) -> some View {
        // NavigationLinkをHStackに変更
        HStack {
            // タイトルとページ範囲を表示
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    // タイトルとページ範囲を表示
                    Text(memo.title ?? "無題".localized)
                        .font(.subheadline)
                    
                    // ページ範囲を表示（存在する場合のみ）
                    if let pageRange = memo.pageRange, !pageRange.isEmpty {
                        Text("(\(pageRange))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // 記憶定着度
                    Text("%d%%".localizedWithInt(retentionScore(for: memo)))
                        .font(.subheadline)
                        .foregroundColor(progressColor(for: Int16(retentionScore(for: memo))))
                }
                
                // プログレスバー
                ProgressView(value: Double(retentionScore(for: memo)) / 100.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .tint(progressColor(for: Int16(retentionScore(for: memo))))
                
                HStack {
                    // 最終復習日
                    Text("最終復習: %@".localizedFormat(formattedDate(memo.lastReviewedDate)))
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    // タグ表示
                    if !memo.tagsArray.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(memo.tagsArray.prefix(2)) { tag in
                                    HStack(spacing: 2) {
                                        Circle()
                                            .fill(tag.swiftUIColor())
                                            .frame(width: 6, height: 6)
                                        
                                        Text(tag.name ?? "タグ名なし".localized)
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                if memo.tagsArray.count > 2 {
                                    Text("+%d".localizedWithInt(memo.tagsArray.count - 2))
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .frame(width: 80)
                    }
                }
            }
            .padding(.vertical, 6)
        }
        .padding(.horizontal, 8)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
        .frame(maxWidth: .infinity) // カードの幅を最大に
        .padding(.horizontal, 8)  // カード自体の左右マージンを追加
    }
    
    // 各種ヘルパー関数
    private func retentionScore(for memo: Memo) -> Int {
        let entries = memo.historyEntriesArray
        if let latest = entries.first {
            return Int(latest.retentionScore)
        } else {
            return Int(MemoryRetentionCalculator.calculateRetentionScore(
                recallScore: memo.recallScore,
                perfectRecallCount: memo.perfectRecallCount
            ))
        }
    }
    
    private func progressColor(for score: Int16) -> Color {
        if score > 70 {
            return .green
        } else if score > 40 {
            return .yellow
        } else {
            return .red
        }
    }
    
    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "未定".localized }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
