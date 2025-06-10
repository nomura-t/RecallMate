import SwiftUI
import CoreData

/// タグ関連のビューで共通して使用されるコンポーネント集
/// このファイルにより、色選択やその他の共通機能の重複を避け、
/// 一貫したユーザー体験を提供できます

/// 共通の色選択セクション
/// タグの編集と新規作成の両方で使用される統一されたインターフェースです
struct UnifiedColorSelectionSection: View {
    @Binding var selectedColor: String
    let tagService: TagService
    let title: String
    let description: String?
    
    // カスタムイニシャライザで柔軟性を提供
    init(
        selectedColor: Binding<String>,
        tagService: TagService,
        title: String = "色の選択",
        description: String? = nil
    ) {
        self._selectedColor = selectedColor
        self.tagService = tagService
        self.title = title
        self.description = description
    }
    
    // 4列のグリッドレイアウト
    private let colorGridColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            // オプショナルな説明文
            if let description = description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // 現在選択されている色の表示
            CurrentColorIndicator(
                selectedColor: selectedColor,
                tagService: tagService
            )
            
            // 色選択グリッド
            LazyVGrid(columns: colorGridColumns, spacing: 16) {
                ForEach(tagService.availableColors, id: \.self) { colorName in
                    UnifiedColorButton(
                        colorName: colorName,
                        color: tagService.colorFromString(colorName),
                        isSelected: selectedColor.lowercased() == colorName.lowercased(),
                        onSelect: { selectedColor = colorName }
                    )
                }
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

/// 現在選択されている色を表示するインジケーター
struct CurrentColorIndicator: View {
    let selectedColor: String
    let tagService: TagService
    
    var body: some View {
        HStack {
            Text("選択中:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Circle()
                .fill(tagService.colorFromString(selectedColor))
                .frame(width: 20, height: 20)
            
            Text(selectedColor.capitalized)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

/// 統一された色選択ボタン
/// 編集と新規作成の両方で一貫したインタラクション体験を提供します
struct UnifiedColorButton: View {
    let colorName: String
    let color: Color
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: {
            // 選択時のハプティックフィードバック
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onSelect()
        }) {
            VStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 3)
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
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
                
                Text(colorName.capitalized)
                    .font(.caption)
                    .foregroundColor(isSelected ? .primary : .secondary)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// タグ名入力用の共通コンポーネント
/// プレビュー機能付きの統一されたタグ名入力体験を提供します
struct UnifiedTagNameSection: View {
    @Binding var tagName: String
    let selectedColor: String
    let tagService: TagService
    let isEditing: Bool // 編集モードか新規作成モードかを判別
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isEditing ? "作業内容名を変更" : "作業内容名")
                .font(.headline)
                .foregroundColor(.primary)
            
            // 入力フィールド
            VStack(alignment: .leading, spacing: 8) {
                TextField(
                    isEditing ? "新しい名前を入力" : "例: 数学、プログラミング、英語学習",
                    text: $tagName
                )
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.body)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                
                // 文字数カウンターと制限の表示
                HStack {
                    if !isEditing {
                        Text("20文字以内で入力してください")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(tagName.count)/20")
                        .font(.caption)
                        .foregroundColor(tagName.count > 20 ? .red : .secondary)
                }
            }
            
            // リアルタイムプレビュー
            TagPreviewSection(
                tagName: tagName,
                selectedColor: selectedColor,
                tagService: tagService
            )
        }
    }
}

/// タグのプレビュー表示セクション
/// ユーザーが作成中のタグがどのように表示されるかを即座に確認できます
struct TagPreviewSection: View {
    let tagName: String
    let selectedColor: String
    let tagService: TagService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("プレビュー:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                Circle()
                    .fill(tagService.colorFromString(selectedColor))
                    .frame(width: 12, height: 12)
                
                Text(tagName.isEmpty ? "タグ名を入力してください" : tagName)
                    .font(.subheadline)
                    .foregroundColor(tagName.isEmpty ? .secondary : .primary)
                    .italic(tagName.isEmpty)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(tagName.isEmpty ? Color.gray.opacity(0.1) : tagService.colorFromString(selectedColor).opacity(0.2))
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                tagName.isEmpty ? Color.gray.opacity(0.3) : tagService.colorFromString(selectedColor),
                                lineWidth: 1
                            )
                    )
            )
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}
