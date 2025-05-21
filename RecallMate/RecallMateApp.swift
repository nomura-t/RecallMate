// RecallMateApp.swift に変更を加える
import SwiftUI
import CoreData

@main
struct RecallMateApp: App {
    // AppDelegateを登録
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    let persistenceController = PersistenceController.shared
    
    // appSettings を宣言
    @StateObject private var appSettings = AppSettings()
    
    // オンボーディング表示状態
    @State private var isShowingOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    
    init() {
        // アプリ起動時にストリークを確認・更新
        StreakTracker.shared.checkAndUpdateStreak(in: persistenceController.container.viewContext)
        
        // ユーザーの使用時間に基づいて通知時間を更新
        StreakNotificationManager.shared.updatePreferredTime()
        
        // ストリーク維持のための通知をスケジュール
        StreakNotificationManager.shared.scheduleStreakReminder()
        
        // 習慣化チャレンジの状態をチェック
        HabitChallengeManager.shared.checkDailyProgress()
        
        // サンプル記録の作成（初回起動時のみ）
        createSampleMemoIfNeeded(in: persistenceController.container.viewContext)
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(appSettings)
                    .onReceive(NotificationCenter.default.publisher(for: Notification.Name("StartPomodoroFromNotification"))) { _ in
                        // 通知からポモドーロを開始する処理をここに書くこともできます
                        // 例: ポモドーロタブに移動する、など
                    }
            }
        }
    }
    
    // サンプル記録を作成する関数（初回起動時のみ）
    private func createSampleMemoIfNeeded(in context: NSManagedObjectContext) {
        // サンプル記録がすでに作成されているかチェック
        if UserDefaults.standard.bool(forKey: "hasSampleMemo") {
            return
        }
        
        // サンプル記録を作成
        let sampleMemo = Memo(context: context)
        sampleMemo.id = UUID()
        sampleMemo.title = "(sample)効果的な学習法：アクティブリコールと分散学習"
        sampleMemo.content = """
        アクティブリコールとは？
        アクティブリコールは、情報を単に読み返すのではなく、自分の力で思い出そうとする学習法です。教科書を閉じて、学んだ内容を自分の言葉で書き出すことで、記憶の定着度が大幅に向上します。

        アクティブリコールのステップ：
        1. 教材を一通り学習する
        2. 教材を閉じる
        3. 思い出せる内容をすべて書き出す
        4. 思い出せなかった部分を確認する
        5. 再度思い出す作業を繰り返す

        分散学習とは？
        分散学習は、学習内容を一度に詰め込むのではなく、時間をおいて複数回に分けて学習する方法です。脳が情報を処理し、長期記憶に定着させるためには、間隔を空けた復習が効果的です。

        分散学習の最適な間隔：
        - 1日後に1回目の復習
        - 1週間後に2回目の復習
        - 2週間後に3回目の復習
        - 1ヶ月後に4回目の復習

        これらを組み合わせることで、最小限の時間で最大限の記憶定着効果が得られます。RecallMateはこの最適な間隔を自動的に計算し、通知してくれます。
        """
//        sampleMemo.pageRange = "参考書 p.24-32"
        sampleMemo.recallScore = 80
        sampleMemo.createdAt = Date()
        sampleMemo.lastReviewedDate = Date()
        
        // 次回復習日を1日後に設定
        let calendar = Calendar.current
        sampleMemo.nextReviewDate = calendar.date(byAdding: .day, value: 1, to: Date())
        
        // キーワードを追加
        sampleMemo.keywords = "アクティブリコール,分散学習,長期記憶,復習間隔"
        
        // 説明問題の回答をUserDefaultsに保存
        UserDefaults.standard.set("""
        アクティブリコールとは、学習した内容を単に読み返すのではなく、能動的に思い出そうとする学習法です。
        
        特徴:
        - 記憶を取り出す行為そのものが記憶を強化する
        - 単なる再読よりも効果が2-3倍高い
        - 記憶の定着に必要な神経回路を強化する
        
        重要性:
        アクティブリコールは「テスト効果」とも呼ばれ、単に情報を見直すよりも長期記憶への定着率が著しく高いことが研究で証明されています。脳が情報を取り出す過程で記憶が強化されるため、特に概念理解や問題解決能力の向上に効果的です。
        """, forKey: "keyword_answer_アクティブリコール")
        
        UserDefaults.standard.set("""
        分散学習とは、学習セッションを時間的に分散させて行う学習方法です。
        
        特徴:
        - 一度に長時間学習するよりも、短い時間を複数回に分けて学習する
        - 学習と学習の間に適切な間隔を設ける
        - 間隔を徐々に広げていく（スペーシング効果）
        
        重要性:
        分散学習は「エビングハウスの忘却曲線」に基づいています。人間は学習後の時間経過とともに急速に忘れていきますが、適切なタイミングで復習することで忘却を防ぎ、長期記憶への定着率を高めることができます。特に複雑な概念や大量の情報を記憶する際に効果的な方法です。
        """, forKey: "keyword_answer_分散学習")
        
        UserDefaults.standard.set("""
        長期記憶とは、数日、数年、あるいは一生涯にわたって保持される記憶の形態です。
        
        特徴:
        - 容量が非常に大きい（ほぼ無制限）
        - 適切な方法で形成されれば非常に長く持続する
        - 陳述的記憶（事実や出来事）と非陳述的記憶（技能や習慣）に分類される
        
        重要性:
        長期記憶は学習の最終目標です。試験のために一時的に覚えるのではなく、知識を長期的に活用できるようにするためには、情報を長期記憶に定着させることが重要です。アクティブリコールと分散学習は、この長期記憶形成を効率的に促進する科学的に証明された方法です。
        """, forKey: "keyword_answer_長期記憶")
        
        UserDefaults.standard.set("""
        復習間隔とは、学習と復習の間、および復習と次の復習の間に設ける時間的な間隔のことです。
        
        特徴:
        - 最適な間隔は徐々に広がっていく（例：1日後→1週間後→2週間後→1ヶ月後）
        - 記憶の定着度に応じて調整される
        - 個人差や学習内容の難易度によって異なる
        
        重要性:
        復習間隔の最適化は分散学習の核心部分です。間隔が短すぎると効率が悪く、長すぎると忘却が進んでしまいます。RecallMateはこの最適な間隔を自動計算し、ユーザーに最適なタイミングで復習を促します。これにより、最小限の時間投資で最大限の記憶定着効果を得ることができます。
        """, forKey: "keyword_answer_復習間隔")
        
        // 比較問題を作成
        let comparisonQuestion = ComparisonQuestion(context: context)
        comparisonQuestion.id = UUID()
        comparisonQuestion.question = "「アクティブリコール」と「分散学習」の違いを比較して説明してください。それぞれの特徴、共通点、相違点について詳細に述べてください。"
        comparisonQuestion.createdAt = Date()
        comparisonQuestion.memo = sampleMemo
        comparisonQuestion.answer = """
        アクティブリコールと分散学習の比較：
        
        【アクティブリコール】
        • 定義：情報を能動的に思い出そうとする学習方法
        • 焦点：記憶を「取り出す」プロセスに焦点
        • 方法：教材を閉じて思い出す、自分の言葉で説明する
        • タイミング：一度の学習セッション内でも実施可能
        
        【分散学習】
        • 定義：学習を時間的に分散させて行う学習方法
        • 焦点：学習の「間隔」に焦点
        • 方法：適切な間隔で複数回学習する、間隔を徐々に広げる
        • タイミング：複数の日にちや週にわたって実施
        
        【共通点】
        • どちらも科学的に効果が実証されている学習法
        • 長期記憶の形成を促進する
        • 能動的な学習姿勢を必要とする
        • 効率的な学習のために組み合わせることが理想的
        
        【相違点】
        • アクティブリコールは「どのように」学ぶかに焦点、分散学習は「いつ」学ぶかに焦点
        • アクティブリコールは1回の学習でも効果があるが、分散学習は複数回の学習セッションが必須
        • アクティブリコールは記憶の強化に、分散学習は忘却の防止に特に効果的
        
        【最適な組み合わせ方】
        アクティブリコールと分散学習を組み合わせることで相乗効果が得られます。具体的には、分散学習の各セッションでアクティブリコールを行うことです。例えば、1日目に学習した内容を、3日後、1週間後、2週間後と間隔を空けて復習する際（分散学習）、毎回教材を見る前に自分で思い出す（アクティブリコール）ようにすると、最も効果的に記憶を定着させることができます。
        """
        
        // 変更を保存
        do {
            try context.save()
            
            // サンプル記録が作成されたことをマーク
            UserDefaults.standard.set(true, forKey: "hasSampleMemo")
        } catch {
        }
    }
}
