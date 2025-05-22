// HomeView.swift
import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme
    
    // 日付選択の状態管理
    @State private var selectedDate = Date()
    @Binding var isAddingMemo: Bool
    
    // タグフィルタリングの状態管理（既存機能を保持）
    @State private var selectedTags: [Tag] = []
    
    // UI更新のトリガー
    @State private var refreshTrigger = UUID()
    
    // 全タグの取得（フィルタリング用）
    @FetchRequest(
        entity: Tag.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)],
        animation: .default)
    private var allTags: FetchedResults<Tag>
    
    // 選択された日付の記録を取得（タグフィルタリングも適用）
    private var dailyMemos: [Memo] {
        let fetchRequest: NSFetchRequest<Memo> = Memo.fetchRequest()
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-1)
        
        // 復習予定日が選択された日、または復習予定日が過ぎている記録をフィルタ
        let isToday = calendar.isDateInToday(selectedDate)
        
        if isToday {
            // 今日の場合：今日が復習日の記録 + 期限切れの記録
            fetchRequest.predicate = NSPredicate(
                format: "(nextReviewDate >= %@ AND nextReviewDate <= %@) OR (nextReviewDate < %@)",
                startOfDay as NSDate,
                endOfDay as NSDate,
                startOfDay as NSDate
            )
        } else {
            // 他の日の場合：その日が復習日の記録のみ
            fetchRequest.predicate = NSPredicate(
                format: "nextReviewDate >= %@ AND nextReviewDate <= %@",
                startOfDay as NSDate,
                endOfDay as NSDate
            )
        }
        
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Memo.nextReviewDate, ascending: true)
        ]
        
        do {
            var memos = try viewContext.fetch(fetchRequest)
            
            // タグフィルタリングを適用
            if !selectedTags.isEmpty {
                memos = memos.filter { memo in
                    // すべての選択されたタグを含むかチェック
                    for tag in selectedTags {
                        if !memo.tagsArray.contains(where: { $0.id == tag.id }) {
                            return false
                        }
                    }
                    return true
                }
            }
            
            return memos
        } catch {
            print("Error fetching daily memos: \(error)")
            return []
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // カスタムカレンダーセクション
                DatePickerCalendarView(selectedDate: $selectedDate)
                    .padding(.vertical, 16)
                    .background(
                        Rectangle()
                            .fill(Color(.systemBackground))
                            .shadow(
                                color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1),
                                radius: 2,
                                x: 0,
                                y: 1
                            )
                    )
                
                // メインコンテンツエリア
                VStack(spacing: 0) {
                    // タグフィルタリングセクション
                    if !allTags.isEmpty {
                        TagFilterSection(
                            selectedTags: $selectedTags,
                            allTags: Array(allTags)
                        )
                        .padding(.top, 16)
                    }
                    
                    // 日付情報ヘッダー（SharedComponentsから使用）
                    DayInfoHeader(
                        selectedDate: selectedDate,
                        memoCount: dailyMemos.count,
                        selectedTags: selectedTags
                    )
                    
                    // 記録リストまたは空の状態
                    if dailyMemos.isEmpty {
                        EmptyStateView(
                            selectedDate: selectedDate,
                            hasTagFilter: !selectedTags.isEmpty
                        )
                    } else {
                        // 記録リスト
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(dailyMemos, id: \.id) { memo in
                                    NavigationLink(destination: ContentView(memo: memo)) {
                                        EnhancedReviewListItem(
                                            memo: memo,
                                            selectedDate: selectedDate
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 100) // フローティングボタンのスペース
                        }
                        .refreshable {
                            forceRefreshData()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .overlay(
                // フローティング追加ボタン（SharedComponentsから使用）
                FloatingAddButton(isAddingMemo: $isAddingMemo)
            )
        }
        .onAppear {
            forceRefreshData()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ForceRefreshMemoData"))) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                forceRefreshData()
            }
        }
        .fullScreenCover(isPresented: $isAddingMemo) {
            ContentView(memo: nil)
        }
    }
    
    // データの強制リフレッシュ
    private func forceRefreshData() {
        viewContext.rollback()
        viewContext.refreshAllObjects()
        refreshTrigger = UUID()
    }
}

// MARK: - タグフィルタリングセクション
struct TagFilterSection: View {
    @Binding var selectedTags: [Tag]
    let allTags: [Tag]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // タグ選択のための水平スクロールビュー
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // 「すべて」ボタン
                    Button(action: {
                        selectedTags = []
                    }) {
                        Text("すべて")
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedTags.isEmpty ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(selectedTags.isEmpty ? .white : .primary)
                            .cornerRadius(16)
                    }
                    
                    // 個別のタグボタン
                    ForEach(allTags, id: \.id) { tag in
                        TagFilterButton(
                            tag: tag,
                            isSelected: selectedTags.contains(where: { $0.id == tag.id }),
                            onToggle: { toggleTag(tag) }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
            
            // 選択されたタグの表示
            if !selectedTags.isEmpty {
                SelectedTagsView(
                    selectedTags: selectedTags,
                    onClearAll: { selectedTags = [] }
                )
                .padding(.horizontal, 16)
            }
        }
    }
    
    // タグの選択/解除をトグル
    private func toggleTag(_ tag: Tag) {
        if let index = selectedTags.firstIndex(where: { $0.id == tag.id }) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
        }
    }
}

// MARK: - タグフィルターボタン
struct TagFilterButton: View {
    let tag: Tag
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
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
                isSelected
                ? tag.swiftUIColor().opacity(0.2)
                : Color.gray.opacity(0.15)
            )
            .foregroundColor(
                isSelected
                ? tag.swiftUIColor()
                : .primary
            )
            .cornerRadius(16)
        }
    }
}

// MARK: - 選択されたタグの表示
struct SelectedTagsView: View {
    let selectedTags: [Tag]
    let onClearAll: () -> Void
    
    var body: some View {
        HStack {
            Text(selectedTags.count == 1 ? "フィルター:" : "フィルター（すべてを含む）:")
                .font(.caption)
                .foregroundColor(.gray)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(selectedTags, id: \.id) { tag in
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
            
            // フィルタークリアボタン
            Button(action: onClearAll) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
    }
}
