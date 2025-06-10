import SwiftUI
import CoreData

struct NewTagCreatorView: View {
    let onSave: (Tag) -> Void
    let onCancel: () -> Void
    
    @Environment(\.managedObjectContext) private var viewContext
    @State private var tagName: String = ""
    @State private var selectedColor: String = "blue"
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    private let tagService = TagService.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 導入メッセージ
                    IntroductionCard()
                    
                    // 共通のタグ名入力セクションを使用
                    UnifiedTagNameSection(
                        tagName: $tagName,
                        selectedColor: selectedColor,
                        tagService: tagService,
                        isEditing: false
                    )
                    
                    // 共通の色選択セクションを使用
                    UnifiedColorSelectionSection(
                        selectedColor: $selectedColor,
                        tagService: tagService,
                        title: "色の選択",
                        description: "作業内容を区別しやすくするため、色を選んでください"
                    )
                    
                    // 使用例の提案セクション
                    UsageExamplesSection()
                }
                .padding(20)
            }
            .navigationTitle("作業内容を追加")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("キャンセル") {
                    onCancel()
                }
                .foregroundColor(.blue),
                trailing: Button("作成") {
                    createNewTag()
                }
                .foregroundColor(.blue)
                .disabled(tagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            )
            .alert("エラー", isPresented: $showErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func createNewTag() {
        let trimmedName = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            errorMessage = "作業内容名を入力してください"
            showErrorAlert = true
            return
        }
        
        guard trimmedName.count <= 20 else {
            errorMessage = "作業内容名は20文字以内で入力してください"
            showErrorAlert = true
            return
        }
        
        isLoading = true
        
        if let newTag = tagService.createTag(name: trimmedName, color: selectedColor, in: viewContext) {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            isLoading = false
            onSave(newTag)
        } else {
            isLoading = false
            errorMessage = "同じ名前の作業内容が既に存在します"
            showErrorAlert = true
        }
    }
}

// 残りの構造体（IntroductionCard, UsageExamplesSection など）は変更なし
struct IntroductionCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 24))
                
                Text("新しい作業内容を追加")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("作業時間を記録するためのカテゴリを作成します。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("例：数学、プログラミング、英語学習、読書など")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct UsageExamplesSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("使用例")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("作業内容は以下のような分類で作成することをお勧めします：")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 10) {
                UsageExampleRow(
                    icon: "function",
                    category: "学習分野別",
                    examples: "数学、物理、化学、英語、プログラミング"
                )
                
                UsageExampleRow(
                    icon: "briefcase.fill",
                    category: "作業タイプ別",
                    examples: "資料作成、会議準備、企画書作成、メール対応"
                )
                
                UsageExampleRow(
                    icon: "book.fill",
                    category: "スキル向上",
                    examples: "読書、オンライン講座、語学学習、資格勉強"
                )
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct UsageExampleRow: View {
    let icon: String
    let category: String
    let examples: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.system(size: 16))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(category)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(examples)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
