import SwiftUI
import CoreData

struct TagSelectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedTags: [Tag]
    @State private var newTagName = ""
    @State private var selectedColor = "blue"
    @State private var errorMessage: String? = nil
    @State private var showAlert = false
    @State private var showColorPicker = false
    
    // 編集中のタグ
    @State private var editingTag: Tag? = nil
    // 削除対象のタグ
    @State private var tagToDelete: Tag? = nil
    @State private var showDeleteConfirmation = false
    
    // タグの変更を通知するためのコールバック（オプション）
    var onTagsChanged: (() -> Void)? = nil
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)],
        animation: .default)
    private var allTags: FetchedResults<Tag>
    
    private let tagService = TagService.shared
    
    var body: some View {
        NavigationStack {
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
                
                // 選択中のタグセクション
                if !selectedTags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("選択中のタグ")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(selectedTags) { tag in
                                    TagChip(
                                        tag: tag,
                                        isSelected: true,
                                        showDeleteButton: true,
                                        onDelete: { removeFromSelection(tag) }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 8)
                    }
                }
                
                // 利用可能なタグリスト
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("利用可能なタグ")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.top, 16)
                        
                        if allTags.isEmpty {
                            Text("タグがありません")
                                .foregroundColor(.gray)
                                .italic()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            ForEach(allTags) { tag in
                                HStack {
                                    // タグチップ（選択用）
                                    Button(action: { toggleTagSelection(tag) }) {
                                        TagChip(
                                            tag: tag,
                                            isSelected: selectedTags.contains(where: { $0.id == tag.id }),
                                            onTap: { toggleTagSelection(tag) }
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Spacer()
                                    
                                    // 編集ボタン
                                    Button(action: { startEditingTag(tag) }) {
                                        Image(systemName: "pencil")
                                            .foregroundColor(.blue)
                                            .font(.system(size: 16))
                                            .frame(width: 40, height: 40)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    // 削除ボタン
                                    Button(action: { confirmTagDeletion(tag) }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                            .font(.system(size: 16))
                                            .frame(width: 40, height: 40)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                
                // 完了ボタン
                Button(action: {
                    // タグ名が入力されている場合は、タグを自動作成して選択
                    if !newTagName.isEmpty {
                        let trimmedName = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if let newTag = tagService.createTag(name: trimmedName, color: selectedColor, in: viewContext) {
                            if !selectedTags.contains(where: { $0.id == newTag.id }) {
                                selectedTags.append(newTag)
                            }
                            newTagName = ""
                            showColorPicker = false
                        }
                    }
                    dismiss()
                }) {
                    Text("完了")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("")
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("エラー"),
                    message: Text(errorMessage ?? "不明なエラーが発生しました"),
                    dismissButton: .default(Text("OK"))
                )
            }
            // タグ編集シート
            .sheet(item: $editingTag) { tag in
                TagEditView(
                    tag: tag,
                    initialName: tag.name ?? "",
                    initialColor: tag.color ?? "blue",
                    onSave: { newName, newColor in
                        if tagService.editTag(tag, newName: newName, newColor: newColor, in: viewContext) {
                            // 編集成功時の処理
                            editingTag = nil
                            
                            // 選択中のタグリストも更新
                            if let index = selectedTags.firstIndex(where: { $0.id == tag.id }) {
                                selectedTags[index] = tag
                            }
                            
                            onTagsChanged?()
                            
                            // 遅延してUIを更新
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onTagsChanged?()
                            }
                        } else {
                            // 編集失敗時のエラーハンドリング
                            errorMessage = "タグの編集に失敗しました。同じ名前のタグが既に存在する可能性があります。"
                            showAlert = true
                        }
                    },
                    onCancel: { editingTag = nil }
                )
            }
            // タグ削除確認ダイアログ
            .alert("タグを削除", isPresented: $showDeleteConfirmation) {
                Button("キャンセル", role: .cancel) {}
                Button("削除", role: .destructive) {
                    if let tag = tagToDelete {
                        deleteTag(tag)
                    }
                }
            } message: {
                Text("タグ「\(tagToDelete?.name ?? "")」を削除しますか？このタグが付いているメモからも削除されます。")
            }
        }
    }
    
    // タグ編集開始
    private func startEditingTag(_ tag: Tag) {
        editingTag = tag
    }
    
    // タグ削除確認
    private func confirmTagDeletion(_ tag: Tag) {
        tagToDelete = tag
        showDeleteConfirmation = true
    }
    
    // タグ削除実行
    private func deleteTag(_ tag: Tag) {
        // 選択中のタグからも削除
        if let index = selectedTags.firstIndex(where: { $0.id == tag.id }) {
            selectedTags.remove(at: index)
        }
        
        // CoreDataから削除
        if tagService.deleteTag(tag, in: viewContext) {
            print("✅ タグを削除しました: \(tag.name ?? "")")
            onTagsChanged?()
        } else {
            errorMessage = "タグの削除に失敗しました"
            showAlert = true
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

// タグ編集ビュー
struct TagEditView: View {
    let tag: Tag
    @State private var editedName: String
    @State private var editedColor: String
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    let onSave: (String, String) -> Void
    let onCancel: () -> Void
    private let tagService = TagService.shared
    
    init(tag: Tag, initialName: String, initialColor: String, onSave: @escaping (String, String) -> Void, onCancel: @escaping () -> Void) {
        self.tag = tag
        self._editedName = State(initialValue: initialName)
        self._editedColor = State(initialValue: initialColor)
        self.onSave = onSave
        self.onCancel = onCancel
        
        print("初期化 - タグ: \(tag.name ?? "無名"), 色: \(initialColor)")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("タグ名")) {
                    TextField("タグ名", text: $editedName)
                        .autocapitalization(.none)
                }
                
                Section(header: Text("タグの色")) {
                    // 現在選択されている色のプレビュー
                    HStack {
                        Text("選択中の色:")
                        Spacer()
                        Circle()
                            .fill(tagService.colorFromString(editedColor))
                            .frame(width: 30, height: 30)
                        Text(editedColor)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    // 色選択グリッド
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(tagService.availableColors, id: \.self) { colorName in
                                Button(action: {
                                    print("色を選択: \(colorName)")
                                    editedColor = colorName
                                }) {
                                    VStack {
                                        Circle()
                                            .fill(tagService.colorFromString(colorName))
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Circle()
                                                    .stroke(editedColor == colorName ? Color.blue : Color.clear, lineWidth: 3)
                                            )
                                        
                                        // 色名を表示
                                        Text(colorName)
                                            .font(.caption)
                                            .foregroundColor(editedColor == colorName ? .blue : .primary)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("タグを編集")
            .navigationBarItems(
                leading: Button("キャンセル") { onCancel() },
                trailing: Button("保存") {
                    saveTag()
                }
                .disabled(editedName.isEmpty)
            )
            .alert("エラー", isPresented: $showErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                print("現在のタグ - 名前: \(tag.name ?? "無名"), 色: \(tag.color ?? "未設定")")
                print("編集値 - 名前: \(editedName), 色: \(editedColor)")
            }
        }
    }
    
    // 保存アクションを強化
    private func saveTag() {
        print("保存処理 - 名前: \(editedName), 色: \(editedColor)")
        
        // 名前が空かどうかチェック
        let trimmedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            errorMessage = "タグ名を入力してください"
            showErrorAlert = true
            return
        }
        
        // 色がリストに存在するかチェック
        if !tagService.availableColors.contains(where: { $0.lowercased() == editedColor.lowercased() }) {
            errorMessage = "選択された色が無効です"
            showErrorAlert = true
            return
        }
        
        // 保存処理を実行
        onSave(trimmedName, editedColor)
    }
}

// 色のグリッド表示ビュー
struct ColorGridView: View {
    @Binding var selectedColor: String
    var onColorSelected: () -> Void
    private let tagService = TagService.shared
    
    // グリッドレイアウト用の設定
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("色を選択")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(tagService.availableColors, id: \.self) { colorName in
                        ColorItemView(
                            color: tagService.colorFromString(colorName),
                            colorName: colorName,
                            isSelected: selectedColor.lowercased() == colorName.lowercased()
                        )
                        .onTapGesture {
                            selectedColor = colorName
                            onColorSelected()
                        }
                    }
                }
            }
            .frame(height: 200)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
    }
}

// 個別の色アイテム表示
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
                    Group {
                        if isSelected {
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                )
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            
            // 色名を表示
            Text(colorName)
                .font(.system(size: 10))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(width: 60)
        }
    }
}
