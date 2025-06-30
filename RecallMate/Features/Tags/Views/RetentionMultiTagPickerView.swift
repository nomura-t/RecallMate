import SwiftUI
import CoreData

// タグ選択ビュー（複数選択対応）
struct RetentionMultiTagPickerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTags: [Tag]
    
    // 選択状態を管理するための一時的な状態
    @State private var tempSelectedTags: [Tag] = []
    @State private var searchText = ""
    
    @FetchRequest(
        entity: Tag.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)],
        animation: .default)
    private var allTags: FetchedResults<Tag>
    
    // 検索フィルター適用済みのタグ
    private var filteredTags: [Tag] {
        if searchText.isEmpty {
            return Array(allTags)
        } else {
            return allTags.filter {
                ($0.name ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // 操作ボタン
                VStack(spacing: 0) {
                    Button(action: {
                        tempSelectedTags = []
                    }) {
                        Text("すべてクリア".localized)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12)
                    }
                    
                    Divider()
                    
                    Button(action: {
                        tempSelectedTags = Array(allTags)
                    }) {
                        Text("すべて選択".localized)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal)
                .background(Color(.systemBackground))
                
                Divider()
                
                Text("利用可能なタグ".localized)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 4)
                
                // タグリスト
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredTags) { tag in
                            RetentionTagRowItem(
                                tag: tag,
                                isSelected: isTagSelected(tag),
                                onToggle: { toggleTag(tag) }
                            )
                            
                            if tag.id != filteredTags.last?.id {
                                Divider()
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("タグを選択".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル".localized) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("適用".localized) {
                        // 選択されたタグの配列を親ビューに渡す
                        DispatchQueue.main.async {
                            selectedTags = tempSelectedTags
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                // 初期表示時に現在の選択状態をコピー
                tempSelectedTags = selectedTags
            }
        }
    }
    
    // タグの選択状態をトグル
    private func toggleTag(_ tag: Tag) {
        if let index = tempSelectedTags.firstIndex(where: { $0.id == tag.id }) {
            tempSelectedTags.remove(at: index)
        } else {
            tempSelectedTags.append(tag)
        }
    }
    
    // タグが選択されているか確認
    private func isTagSelected(_ tag: Tag) -> Bool {
        return tempSelectedTags.contains(where: { $0.id == tag.id })
    }
}

// タグ行アイテム - タップ可能な領域を最大化
struct RetentionTagRowItem: View {
    let tag: Tag
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                // タグ色のインジケーター
                Circle()
                    .fill(tag.swiftUIColor())
                    .frame(width: 12, height: 12)
                
                // タグ名
                Text(tag.name ?? "タグ名なし".localized)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 選択状態のチェックマーク
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .contentShape(Rectangle())
            .padding(.vertical, 12)
        }
    }
}
