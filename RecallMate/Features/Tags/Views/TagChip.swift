// TagChip.swift を修正
import SwiftUI

// 改良版タグチップ - タップ可能な領域を最大化
struct TagChip: View {
    let tag: Tag
    let isSelected: Bool
    var onTap: (() -> Void)? = nil
    var showDeleteButton: Bool = false
    var onDelete: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 4) {
                Circle()
                    .fill(tag.swiftUIColor())
                    .frame(width: 8, height: 8)
                
                Text(tag.name ?? "")
                    .font(.caption)
                    .lineLimit(1)
                
                // 削除ボタンを条件付きで表示
                if showDeleteButton {
                    Button(action: { onDelete?() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(isSelected ? tag.swiftUIColor().opacity(0.2) : Color(.systemGray6))
                    .overlay(
                        Capsule()
                            .strokeBorder(isSelected ? tag.swiftUIColor() : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(BorderlessButtonStyle())
    }
}

// タグ行アイテム - タップ可能な領域を最大化
struct TagRowItem: View {
    let tag: Tag
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                TagChip(tag: tag, isSelected: isSelected, onTap: onToggle)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
        }
        .contentShape(Rectangle())
    }
}

// タグ選択ビュー（複数選択対応）
struct MultiTagPickerView: View {
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
                // 検索バー
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("タグを検索".localized, text: $searchText)
                        .disableAutocorrection(true)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // 選択したタグの表示
                if !tempSelectedTags.isEmpty {
                    VStack(alignment: .leading) {
                        Text("選択中のタグ:".localized)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                            .padding(.top, 4)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(tempSelectedTags) { tag in
                                    TagChip(
                                        tag: tag,
                                        isSelected: true,
                                        showDeleteButton: true,
                                        onDelete: {
                                            if let index = tempSelectedTags.firstIndex(where: { $0.id == tag.id }) {
                                                tempSelectedTags.remove(at: index)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                List {
                    Section {
                        Button(action: {
                            tempSelectedTags = []
                        }) {
                            HStack {
                                Text("すべてクリア".localized)
                                    .foregroundColor(.red)
                                
                                Spacer()
                            }
                        }
                        
                        Button(action: {
                            tempSelectedTags = Array(allTags)
                        }) {
                            HStack {
                                Text("すべて選択".localized)
                                    .foregroundColor(.blue)
                                
                                Spacer()
                            }
                        }
                    }
                    
                    if filteredTags.isEmpty {
                        Section {
                            Text("タグが見つかりません".localized)
                                .foregroundColor(.gray)
                                .italic()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        }
                    } else {
                        Section(header: Text("利用可能なタグ".localized)) {
                            ForEach(filteredTags) { tag in
                                TagRowItem(
                                    tag: tag,
                                    isSelected: isTagSelected(tag),
                                    onToggle: {
                                        toggleTag(tag)
                                    }
                                )
                            }
                        }
                    }
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
                        let updatedTags = tempSelectedTags
                        
                        // メインスレッドで実行して確実に更新
                        DispatchQueue.main.async {
                            selectedTags = updatedTags
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
