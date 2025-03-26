import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // 複数タグ選択をサポートするため配列に変更
    @State private var selectedTags: [Tag] = []
    // 日付フォーマッター
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    // UIの更新を強制するためのトリガー
    @State private var refreshTrigger = UUID()
    
    // メモの取得リクエスト
    @FetchRequest(
        entity: Memo.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Memo.nextReviewDate, ascending: true)],
        animation: .default)
    private var memos: FetchedResults<Memo>
    
    // タグのFetchRequest
    @FetchRequest(
        entity: Tag.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)],
        animation: .default)
    private var allTags: FetchedResults<Tag>

    @Binding var isAddingMemo: Bool
    
    // デバッグ用の状態変数
    @State private var showDebugInfo = true
    @State private var debugMessage = ""
    
    // デバッグモードフラグ
    @State private var isDebugMode = false

    // 表示するメモのリスト（タグによるフィルタリング適用）
    private var displayedMemos: [Memo] {
        if selectedTags.isEmpty {
            return Array(memos)
        } else {
            // 「かつ」条件 - 選択したすべてのタグを持つメモだけを表示
            return Array(memos).filter { memo in
                // すべての選択されたタグを含むかチェック
                for tag in selectedTags {
                    if !memo.tagsArray.contains(where: { $0.id == tag.id }) {
                        return false  // 1つでも含まれていないタグがあればこのメモは除外
                    }
                }
                return true  // すべての選択タグを含む場合のみtrue
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {                
                // タグリスト（水平スクロール）
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // 「すべて」ボタン（タグをクリア）
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
                        
                        // タグボタン（複数選択を可能に）
                        ForEach(allTags) { tag in
                            Button(action: {
                                // タグの選択/解除のトグル
                                if let index = selectedTags.firstIndex(where: { $0.id == tag.id }) {
                                    // 既に選択されている場合は解除
                                    selectedTags.remove(at: index)
                                } else {
                                    // 選択されていない場合は追加
                                    selectedTags.append(tag)
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
                                    selectedTags.contains(where: { $0.id == tag.id })
                                    ? tag.swiftUIColor().opacity(0.2)
                                    : Color.gray.opacity(0.15)
                                )
                                .foregroundColor(
                                    selectedTags.contains(where: { $0.id == tag.id })
                                    ? tag.swiftUIColor()
                                    : .primary
                                )
                                .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                // 選択されたタグの表示（複数選択されている場合）
                if selectedTags.count > 0 {
                    HStack {
                        if selectedTags.count == 1 {
                            Text("フィルター:")
                                .font(.caption)
                                .foregroundColor(.gray)
                        } else {
                            Text("フィルター（すべてを含む）:")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(selectedTags) { tag in
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
                        
                        // タグ選択クリアボタン
                        Button(action: {
                            selectedTags = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 4)
                }
                
                HStack(spacing: 8) {
                    StreakCardView()
                        .frame(maxWidth: .infinity)
                        .frame(width: 100)
                    HabitChallengeCardView()
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 5)                // デバッグメッセージがあれば表示
                if showDebugInfo && !debugMessage.isEmpty {
                    Text(debugMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                // デバッグモードの場合のみ表示
                if isDebugMode {
                    HStack {
                        Button(action: {
                            debugMemos()
                        }) {
                            Label("メモ診断", systemImage: "magnifyingglass")
                                .font(.caption)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            forceRefreshData()
                        }) {
                            Label("強制更新", systemImage: "arrow.clockwise")
                                .font(.caption)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            analyzeReviewDates()
                        }) {
                            Label("復習日分析", systemImage: "calendar.badge.clock")
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                if displayedMemos.isEmpty {
                    // フィルター適用後メモがない場合の表示
                    if !selectedTags.isEmpty {
                        VStack(spacing: 20) {
                            Text("条件に一致するメモがありません")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                            
                            Button(action: {
                                selectedTags = []
                            }) {
                                Text("フィルターをクリア")
                                    .foregroundColor(.blue)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    } else {
                        // そもそもメモがない場合
                        VStack(spacing: 20) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text("メモはまだありません")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Text("右下のボタンからメモを追加できます")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    }
                } else {
                    // メモリスト
                    List {
                        ForEach(displayedMemos, id: \.id) { memo in
                            NavigationLink(destination: ContentView(memo: memo)) {
                                ReviewListItem(memo: memo)
                            }
                        }
                        .onDelete(perform: deleteMemo)
                    }
                    .id(refreshTrigger) // リストの強制リフレッシュ用
                    .listStyle(.plain)
                    .padding(.bottom, 20)
                    .refreshable {
                        // リストを手動で更新
                        forceRefreshData()
                    }
                }
            }
            .onAppear {
                print("🔄 HomeView表示 - データをリフレッシュします")
                forceRefreshData()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // デバッグモード切り替えボタン
                    Button(action: {
                        isDebugMode.toggle()
                    }) {
                        Image(systemName: isDebugMode ? "ladybug.fill" : "ladybug")
                            .foregroundColor(isDebugMode ? .red : .gray)
                    }
                }
            }
            .overlay(
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            // デバッグログを追加
                            print("➕ 新規メモ追加ボタンがタップされました")
                            showDebugInfo = true
                            
                            // isAddingMemoを設定
                            isAddingMemo = true
                        }) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 40))
                                .padding()
                                .background(Color.blue.opacity(0.8))
                                .foregroundColor(.white)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding()
                    }
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ForceRefreshMemoData"))) { notification in
            print("📣 HomeView: データ更新通知を受信しました")
            
            // 更新処理の前に少し遅延を入れる
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                forceRefreshData()
            }
        }
    }
    
    // メモの詳細情報をデバッグ出力（強化版）
    private func debugMemos() {
        print("🔍 メモ診断を実行します")
        
        print("📊 現在のメモ一覧:")
        let sortedMemos = memos.sorted {
            ($0.nextReviewDate ?? Date.distantFuture) < ($1.nextReviewDate ?? Date.distantFuture)
        }
        
        // 今日の日付
        let today = Calendar.current.startOfDay(for: Date())
        
        // 復習期限切れのメモをカウント
        let overdueCount = sortedMemos.filter { memo in
            guard let reviewDate = memo.nextReviewDate else { return false }
            return Calendar.current.startOfDay(for: reviewDate) < today
        }.count
        
        // 今日が復習日のメモをカウント
        let todayCount = sortedMemos.filter { memo in
            guard let reviewDate = memo.nextReviewDate else { return false }
            return Calendar.current.isDateInToday(reviewDate)
        }.count
        
        print("- 復習期限切れ: \(overdueCount)件")
        print("- 今日が復習日: \(todayCount)件")
        print("- その他: \(memos.count - overdueCount - todayCount)件")
        
        for memo in memos {
            print("- メモ: \(memo.title ?? "無題")")
            print("  - ID: \(memo.id?.uuidString ?? "不明")")
            print("  - 完璧回数: \(memo.perfectRecallCount)")
            print("  - 最終復習日: \(dateFormatter.string(from: memo.lastReviewedDate ?? Date()))")
            print("  - 次回復習日: \(memo.nextReviewDate != nil ? dateFormatter.string(from: memo.nextReviewDate!) : "未設定")")
            print("  - タグ数: \(memo.tagsArray.count)")
            print("  - 履歴エントリ数: \(memo.historyEntriesArray.count)")
            
            // 履歴エントリの詳細（最新の3つまで）
            if !memo.historyEntriesArray.isEmpty {
                print("  - 履歴エントリ:")
                for (index, entry) in memo.historyEntriesArray.prefix(3).enumerated() {
                    print("    [\(index+1)] 日時: \(dateFormatter.string(from: entry.date ?? Date())), 記憶度: \(entry.recallScore)%, 定着度: \(entry.retentionScore)%")
                }
            }
        }
        
        // 変更を検出するため、CoreDataコンテキストも診断
        print("🔍 CoreData診断:")
        print("- 挿入されたオブジェクト: \(viewContext.insertedObjects.count)")
        print("- 更新されたオブジェクト: \(viewContext.updatedObjects.count)")
        print("- 削除されたオブジェクト: \(viewContext.deletedObjects.count)")
        print("- 変更の合計: \(viewContext.insertedObjects.count + viewContext.updatedObjects.count + viewContext.deletedObjects.count)")
        
        if viewContext.hasChanges {
            print("⚠️ 未保存の変更があります")
        } else {
            print("✅ 未保存の変更はありません")
        }
        
        // UIを強制更新
        refreshTrigger = UUID()
        debugMessage = "診断完了: \(Date().formatted(date: .omitted, time: .shortened))"
        showDebugInfo = true
    }
    
    // 復習日の分析を実行
    private func analyzeReviewDates() {
        print("📅 復習日分析:")
        
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: today)!
        let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: today)!
        
        // 期限切れ
        let overdue = memos.filter { memo in
            guard let reviewDate = memo.nextReviewDate else { return false }
            return reviewDate < today
        }
        
        // 今日
        let dueToday = memos.filter { memo in
            guard let reviewDate = memo.nextReviewDate else { return false }
            return Calendar.current.isDateInToday(reviewDate)
        }
        
        // 明日
        let dueTomorrow = memos.filter { memo in
            guard let reviewDate = memo.nextReviewDate else { return false }
            return Calendar.current.isDateInTomorrow(reviewDate)
        }
        
        // 今週（明日以降）
        let dueThisWeek = memos.filter { memo in
            guard let reviewDate = memo.nextReviewDate else { return false }
            return reviewDate > tomorrow && reviewDate <= nextWeek
        }
        
        // 今月（今週以降）
        let dueThisMonth = memos.filter { memo in
            guard let reviewDate = memo.nextReviewDate else { return false }
            return reviewDate > nextWeek && reviewDate <= nextMonth
        }
        
        // 来月以降
        let dueLater = memos.filter { memo in
            guard let reviewDate = memo.nextReviewDate else { return false }
            return reviewDate > nextMonth
        }
        
        // 集計結果表示
        print("- 期限切れ: \(overdue.count)件")
        print("- 今日が期限: \(dueToday.count)件")
        print("- 明日が期限: \(dueTomorrow.count)件")
        print("- 今週が期限: \(dueThisWeek.count)件")
        print("- 今月が期限: \(dueThisMonth.count)件")
        print("- 来月以降: \(dueLater.count)件")
        print("- 未設定: \(memos.filter { $0.nextReviewDate == nil }.count)件")
        
        // メッセージ表示
        debugMessage = "復習日分析: 期限切れ[\(overdue.count)] 今日[\(dueToday.count)] 明日[\(dueTomorrow.count)] 今週[\(dueThisWeek.count)]"
        showDebugInfo = true
    }
    
    // データを強制的に更新するメソッド
    private func forceRefreshData() {
        // 習慣化チャレンジの進捗をチェック
        HabitChallengeManager.shared.checkDailyProgress()
        
        // 進行中のタスクがあれば明示的にキャンセル
        viewContext.rollback()
        
        print("🧹 CoreDataキャッシュをクリア")
        viewContext.refreshAllObjects()
        
        // FetchRequestの再実行
        let fetchRequest: NSFetchRequest<Memo> = Memo.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Memo.nextReviewDate, ascending: true)]
        
        do {
            // 明示的に再取得
            let refreshedMemos = try viewContext.fetch(fetchRequest)
            print("📊 メモを再読み込みしました (\(refreshedMemos.count)件)")
            
            // UI更新トリガー
            refreshTrigger = UUID()
            
            // 詳細情報（最初の5件）
            for memo in refreshedMemos.prefix(5) {
                print("- メモ: \(memo.title ?? "無題")")
                print("  - 完璧回数: \(memo.perfectRecallCount)")
                print("  - 次回復習日: \(memo.nextReviewDate != nil ? dateFormatter.string(from: memo.nextReviewDate!) : "未設定")")
            }
        } catch {
            print("❌ メモ取得エラー: \(error)")
        }
    }
    
    private func deleteMemo(offsets: IndexSet) {
        withAnimation {
            offsets.map { displayedMemos[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
                
                // 削除後に表示を更新
                refreshTrigger = UUID()
            } catch {
                print("❌ 削除エラー: \(error)")
            }
        }
    }
}
