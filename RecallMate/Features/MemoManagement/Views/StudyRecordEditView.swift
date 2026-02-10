import SwiftUI
import CoreData

// MARK: - Study Record Edit View
struct StudyRecordEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let activity: LearningActivity
    @State private var durationMinutes: Int16
    @State private var activityDate: Date
    @State private var notes: String
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(activity: LearningActivity) {
        self.activity = activity
        self._durationMinutes = State(initialValue: activity.durationMinutes)
        self._activityDate = State(initialValue: activity.date ?? Date())
        self._notes = State(initialValue: activity.note ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("学習記録") {
                    // 学習日時
                    DatePicker("学習日時", selection: $activityDate, displayedComponents: [.date, .hourAndMinute])
                    
                    // 学習時間
                    VStack(alignment: .leading, spacing: UIConstants.smallSpacing) {
                        HStack {
                            Text("学習時間")
                            Spacer()
                            Text("\\(durationMinutes)分")
                                .font(.headline)
                                .foregroundColor(AppColors.primary)
                        }
                        
                        Slider(value: Binding(
                            get: { Double(durationMinutes) },
                            set: { durationMinutes = Int16($0) }
                        ), in: 1...300, step: 1)
                        .tint(AppColors.primary)
                    }
                    
                    // メモ
                    VStack(alignment: .leading, spacing: UIConstants.smallSpacing) {
                        Text("メモ")
                        
                        TextEditor(text: $notes)
                            .frame(minHeight: 80)
                            .textInputAutocapitalization(.sentences)
                    }
                }
                
                Section("学習情報") {
                    HStack {
                        Text("種類")
                        Spacer()
                        Text(activity.type ?? "不明")
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    HStack {
                        Text("関連メモ")
                        Spacer()
                        Text(activity.memo?.title ?? "なし")
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .navigationTitle("学習記録編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveRecord()
                    }
                    .disabled(isLoading)
                }
            }
            .alert("編集結果", isPresented: $showingAlert) {
                Button("OK") {
                    if alertMessage.contains("成功") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .overlay {
                if isLoading {
                    LoadingOverlay(message: "保存中...")
                }
            }
        }
    }
    
    private func saveRecord() {
        isLoading = true
        
        activity.durationMinutes = durationMinutes
        activity.date = activityDate
        activity.note = notes.isEmpty ? nil : notes
        
        do {
            try viewContext.save()
            alertMessage = "学習記録が更新されました"
            showingAlert = true
        } catch {
            alertMessage = "保存に失敗しました: \\(error.localizedDescription)"
            showingAlert = true
        }
        
        isLoading = false
    }
}

// MARK: - Study Record Row with Actions
struct StudyRecordRow: View {
    let activity: LearningActivity
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.smallSpacing) {
            // ヘッダー
            HStack {
                Text(activity.memo?.title ?? activity.type ?? "学習記録")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Text("\\(activity.durationMinutes)分")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.primary)
            }
            
            // 学習日時
            HStack {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                Text(formatDate(activity.date ?? Date()))
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                Spacer()
            }
            
            // メモ（あれば）
            if let notes = activity.note, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(AppColors.backgroundSecondary)
        .cornerRadius(UIConstants.mediumCornerRadius)
        .swipeActions(edge: .trailing) {
            // 削除アクション
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("削除", systemImage: "trash")
            }
            
            // 編集アクション
            Button {
                showingEditSheet = true
            } label: {
                Label("編集", systemImage: "pencil")
            }
            .tint(AppColors.primary)
        }
        .contextMenu {
            Button {
                showingEditSheet = true
            } label: {
                Label("編集", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            StudyRecordEditView(activity: activity)
        }
        .alert("記録を削除", isPresented: $showingDeleteAlert) {
            Button("削除", role: .destructive) {
                deleteRecord()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("この学習記録を削除してもよろしいですか？\\nこの操作は取り消せません。")
        }
    }
    
    private func deleteRecord() {
        viewContext.delete(activity)
        
        do {
            try viewContext.save()
        } catch {
            print("削除エラー: \\(error)")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// MARK: - Study Records List View
struct StudyRecordsListView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \LearningActivity.date, ascending: false)],
        animation: .default)
    private var activities: FetchedResults<LearningActivity>
    
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    
    var filteredActivities: [LearningActivity] {
        let calendar = Calendar.current
        return activities.filter { activity in
            guard let activityDate = activity.date else { return false }
            return calendar.isDate(activityDate, inSameDayAs: selectedDate)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 日付選択ヘッダー
                VStack(spacing: UIConstants.smallSpacing) {
                    Button(action: {
                        showingDatePicker.toggle()
                    }) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(AppColors.primary)
                            
                            Text(formatSelectedDate())
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .padding()
                        .background(AppColors.backgroundSecondary)
                        .cornerRadius(UIConstants.mediumCornerRadius)
                    }
                    
                    if showingDatePicker {
                        DatePicker("日付を選択", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .padding()
                            .background(AppColors.backgroundSecondary)
                            .cornerRadius(UIConstants.mediumCornerRadius)
                    }
                }
                .padding()
                .background(AppColors.backgroundPrimary)
                
                // 記録一覧
                if filteredActivities.isEmpty {
                    EmptyStateView(
                        hasTagFilter: false
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: UIConstants.mediumSpacing) {
                            ForEach(filteredActivities, id: \.self) { activity in
                                StudyRecordRow(activity: activity)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("学習記録")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("今日") {
                        selectedDate = Date()
                        showingDatePicker = false
                    }
                }
            }
        }
    }
    
    private func formatSelectedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: selectedDate)
    }
}

// MARK: - Preview
struct StudyRecordEditView_Previews: PreviewProvider {
    static var previews: some View {
        StudyRecordsListView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}