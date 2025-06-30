import SwiftUI
import CoreData

struct TagEditModalView: View {
    let tag: Tag
    let onSave: (Tag) -> Void
    let onCancel: () -> Void
    
    @Environment(\.managedObjectContext) private var viewContext
    @State private var editedName: String = ""
    @State private var editedColor: String = ""
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    private let tagService = TagService.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 警告メッセージ
                    WarningMessageCard()
                    
                    // 共通のタグ名編集セクションを使用
                    UnifiedTagNameSection(
                        tagName: $editedName,
                        selectedColor: editedColor,
                        tagService: tagService,
                        isEditing: true
                    )
                    
                    // 共通の色選択セクションを使用
                    UnifiedColorSelectionSection(
                        selectedColor: $editedColor,
                        tagService: tagService,
                        title: "色を変更".localized,
                        description: "作業内容を区別しやすくするため、色を変更できます".localized
                    )
                    
                    // 使用状況表示セクション
                    TagUsageInfoSection(tag: tag)
                }
                .padding(20)
            }
            .navigationTitle("作業内容を編集".localized)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("キャンセル".localized) {
                    onCancel()
                }
                .foregroundColor(.blue),
                trailing: Button("保存".localized) {
                    saveChanges()
                }
                .foregroundColor(.blue)
                .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            )
            .onAppear {
                setupInitialValues()
            }
            .alert("エラー".localized, isPresented: $showErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func setupInitialValues() {
        editedName = tag.name ?? ""
        editedColor = tag.color ?? "blue"
    }
    
    private func saveChanges() {
        let trimmedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            errorMessage = "タグ名を入力してください".localized
            showErrorAlert = true
            return
        }
        
        isLoading = true
        
        let success = tagService.editTag(
            tag,
            newName: trimmedName,
            newColor: editedColor,
            in: viewContext
        )
        
        isLoading = false
        
        if success {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            onSave(tag)
        } else {
            errorMessage = "同じ名前のタグが既に存在します".localized
            showErrorAlert = true
        }
    }
}

// WarningMessageCard と TagUsageInfoSection は変更なし
struct WarningMessageCard: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.system(size: 20))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("変更の影響について".localized)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("このタグは復習記録でも使用されている可能性があります。変更はすべての記録に反映されます。".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct TagUsageInfoSection: View {
    let tag: Tag
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("使用状況".localized)
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                UsageInfoRow(
                    icon: "brain.head.profile",
                    title: "復習記録".localized,
                    count: getReviewMemoCount(),
                    color: .blue
                )
                
                UsageInfoRow(
                    icon: "timer",
                    title: "作業記録".localized,
                    count: getWorkTimerCount(),
                    color: .green
                )
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private func getReviewMemoCount() -> Int {
        let fetchRequest: NSFetchRequest<Memo> = Memo.fetchRequest()
        
        guard let tagId = tag.id else { return 0 }
        
        fetchRequest.predicate = NSPredicate(format: "ANY tags.id == %@", tagId as CVarArg)
        
        do {
            let memos = try viewContext.fetch(fetchRequest)
            return memos.filter { !($0.title?.hasPrefix("作業記録:") ?? false) }.count
        } catch {
            return 0
        }
    }
    
    private func getWorkTimerCount() -> Int {
        guard let tagId = tag.id else { return 0 }
        
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let activities = LearningActivity.fetchWorkTimerActivities(
            from: thirtyDaysAgo,
            to: Date(),
            tagId: tagId,
            in: viewContext
        )
        return activities.count
    }
}

struct UsageInfoRow: View {
    let icon: String
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 16))
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("%d件".localizedFormat(count))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(count > 0 ? color : .secondary)
        }
    }
}
