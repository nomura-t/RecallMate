import SwiftUI

struct TagSelectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedTags: [Tag]
    @State private var newTagName = ""
    @State private var selectedColor = "blue"
    @State private var errorMessage: String? = nil
    @State private var showAlert = false
    @State private var showColorPicker = false // 色選択パネルの表示状態
    
    // タグの変更を通知するためのコールバック（オプション）
    var onTagsChanged: (() -> Void)? = nil
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)],
        animation: .default)
    private var allTags: FetchedResults<Tag>
    
    private let tagService = TagService.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // 新規タグ作成セクションを分離
            VStack(spacing: 12) {
                Text("新しいタグを作成")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack {
                    TextField("タグ名", text: $newTagName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                    
                    // 色選択ボタン - タップすると色選択パネルを表示
                    Button(action: { showColorPicker.toggle() }) {
                        Circle()
                            .fill(tagService.colorFromString(selectedColor))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                    }
                    
                    Button(action: createNewTag) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }
                    .disabled(newTagName.isEmpty)
                }
                .padding(.bottom, 12)
                
                // 色選択パネル - showColorPickerがtrueの時のみ表示
                if showColorPicker {
                    ColorGridView(selectedColor: $selectedColor) {
                        withAnimation {
                            showColorPicker = false
                        }
                    }
                    .padding(.bottom, 10)
                }
            }
            .padding()
            .background(Color(.systemGray6).opacity(0.5))
            
            // 既存タグ選択セクションを分離
            TagSelectionList(
                allTags: allTags,
                selectedTags: $selectedTags,
                onToggle: toggleTagSelection,
                onRemove: removeFromSelection
            )
            
            // 完了ボタン
            CompleteButton {
                dismiss()
            }
        }
        .navigationTitle("タグ")
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("エラー"),
                message: Text(errorMessage ?? "不明なエラーが発生しました"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // 新規タグ作成
    private func createNewTag() {
        let trimmedName = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        if let newTag = tagService.createTag(name: trimmedName, color: selectedColor, in: viewContext) {
            if !selectedTags.contains(where: { $0.id == newTag.id }) {
                selectedTags.append(newTag)
                onTagsChanged?() // タグが変更されたことを通知
            }
            newTagName = ""
            showColorPicker = false // 色選択パネルを閉じる
        } else {
            errorMessage = "タグの作成に失敗しました"
            showAlert = true
        }
    }
    
    // タグ選択のトグル
    private func toggleTagSelection(_ tag: Tag) {
        if let index = selectedTags.firstIndex(where: { $0.id == tag.id }) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
        }
        onTagsChanged?() // タグが変更されたことを通知
    }
    
    // 選択から削除
    private func removeFromSelection(_ tag: Tag) {
        if let index = selectedTags.firstIndex(where: { $0.id == tag.id }) {
            selectedTags.remove(at: index)
            onTagsChanged?() // タグが変更されたことを通知
        }
    }
}

// 色のグリッド表示ビュー - 改良版
struct ColorGridView: View {
    @Binding var selectedColor: String
    var onColorSelected: () -> Void
    private let tagService = TagService.shared
    
    // グリッドレイアウト用の設定
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())  // 色が増えたので列も増やす
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("色を選択")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(tagService.availableColors, id: \.self) { color in
                        ColorItemView(
                            color: tagService.colorFromString(color),
                            colorName: color,
                            isSelected: selectedColor == color
                        )
                        .onTapGesture {
                            selectedColor = color
                            onColorSelected()
                        }
                    }
                }
            }
            .frame(height: 200)  // スクロール可能な高さを設定
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
    }
}

// 個別の色アイテム表示 - 改良版（色名表示付き）
struct ColorItemView: View {
    let color: Color
    let colorName: String
    let isSelected: Bool
    
    var body: some View {
        VStack {
            Circle()
                .fill(color)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                )
                .overlay(
                    // 修正: 条件付きでチェックマークを表示
                    Group {
                        if isSelected {
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                )
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            
            // 色名を表示（オプション）
            if !colorName.isEmpty {
                Text(colorName.capitalized)
                    .font(.system(size: 10))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(width: 60)
            }
        }
    }
}

// 残りのサブビューコードは変更なし
struct TagSelectionList: View {
    let allTags: FetchedResults<Tag>
    @Binding var selectedTags: [Tag]
    var onToggle: (Tag) -> Void
    var onRemove: (Tag) -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("タグを選択")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top)
                
                // 選択済みタグを表示
                if !selectedTags.isEmpty {
                    SelectedTagsView(selectedTags: selectedTags, onRemove: onRemove)
                }
                
                // 利用可能なタグをグリッド表示
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                    ForEach(allTags) { tag in
                        TagChip(
                            tag: tag,
                            isSelected: selectedTags.contains(where: { $0.id == tag.id }),
                            onTap: { onToggle(tag) }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct SelectedTagsView: View {
    let selectedTags: [Tag]
    var onRemove: (Tag) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("選択中")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(selectedTags) { tag in
                        TagChip(
                            tag: tag,
                            isSelected: true,
                            showDeleteButton: true,
                            onDelete: { onRemove(tag) }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

struct CompleteButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("完了")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
                .padding()
        }
    }
}
