import SwiftUI

struct AppInfoView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    // アプリについての3つの主要カテゴリー
                    NavigationLink(destination: AppUsageGuideView()) {
                        HStack {
                            Image(systemName: "book.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 24))
                                .frame(width: 32, height: 32)
                            
                            VStack(alignment: .leading) {
                                Text("このアプリの使い方".localized)
                                    .font(.headline)
                                
                                Text("基本機能と活用のヒント".localized)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.leading, 8)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    NavigationLink(destination: EffectiveStudyMethodsView()) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.purple)
                                .font(.system(size: 24))
                                .frame(width: 32, height: 32)
                            
                            VStack(alignment: .leading) {
                                Text("効果のある勉強法について".localized)
                                    .font(.headline)
                                
                                Text("科学的に証明された学習テクニック".localized)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.leading, 8)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    NavigationLink(destination: MotivationTipsView()) {
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 24))
                                .frame(width: 32, height: 32)
                            
                            VStack(alignment: .leading) {
                                Text("モチベーションについて".localized)
                                    .font(.headline)
                                
                                Text("学習意欲を維持するための方法".localized)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.leading, 8)
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section {
                    HStack {
                        Text("バージョン".localized)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("開発者".localized)
                        Spacer()
                        Text("RecallMate Team")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("このアプリについて".localized)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// アプリの使い方画面
struct AppUsageGuideView: View {
    var body: some View {
        List {
            Section(header: Text("基本的な使い方".localized)) {
                NavigationLink(destination: DetailContentView(title: "スキマ時間の活用法", content: "忙しい日常の中でも、スキマ時間を活用して効率的に学習する方法をご紹介します。")) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                        Text("スキマ時間の活用法".localized)
                    }
                }
                
                NavigationLink(destination: DetailContentView(title: "アプリの使いこなし方", content: "RecallMateの様々な機能を組み合わせて、より効果的に学習する方法をご紹介します。")) {
                    HStack {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .foregroundColor(.blue)
                        Text("アプリの使いこなし方")
                    }
                }
                
                NavigationLink(destination: DetailContentView(title: "開発者も実践！効果的な使い方", content: "開発チームが実際に使っているRecallMateの活用法をお教えします。様々な場面での活用例をご紹介します。")) {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.blue)
                        Text("開発者も実践！効果的な使い方")
                    }
                }
            }
            
            Section(header: Text("ヒントとコツ")) {
                // タグの使い方を残して復習のベストタイミングを削除
                NavigationLink(destination: DetailContentView(title: "タグの上手な使い方", content: "タグ機能を使って学習内容をスマートに整理する方法をご紹介します。")) {
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundColor(.blue)
                        Text("タグの上手な使い方")
                    }
                }
            }
        }
        .navigationTitle("このアプリの使い方")
    }
}

// 効果のある勉強法について画面
struct EffectiveStudyMethodsView: View {
    var body: some View {
        List {
            Section(header: Text("学習の基礎知識")) {
                NavigationLink(destination: DetailContentView(title: "勉強って何だろう？", content: "効果的な学習とは何か、その本質についてわかりやすく解説します。")) {
                    Text("勉強って何だろう？")
                }
                
                NavigationLink(destination: DetailContentView(title: "あまり効果がない勉強法", content: "時間をかけているのに効果が出にくい勉強法について解説します。時間を無駄にしないためにチェックしておきましょう。")) {
                    Text("あまり効果がない勉強法")
                }
                
                NavigationLink(destination: DetailContentView(title: "「わかった気」になる落とし穴", content: "「理解した気になる」という認知バイアスと、それを避ける方法について解説します。この落とし穴にハマっていませんか？")) {
                    Text("「わかった気」になる落とし穴")
                }
                
                NavigationLink(destination: DetailContentView(title: "脳はどう学ぶ？", content: "脳がどのように情報を処理し、記憶に定着させるかについてやさしく解説します。脳の仕組みを知って賢く学びましょう。")) {
                    Text("脳はどう学ぶ？")
                }
            }
            
            Section(header: Text("科学的に効果が証明された学習法")) {
                NavigationLink(destination: DetailContentView(title: "本当に効く勉強法", content: "科学的研究により効果が実証されている学習方法をご紹介します。これらの方法を取り入れて、学習効率をアップさせましょう。")) {
                    Text("本当に効く勉強法")
                }
                
                NavigationLink(destination: DetailContentView(title: "アクティブリコールって何？", content: "能動的に情報を思い出すことでより強い記憶を作る「アクティブリコール」について詳しく解説します。RecallMateの核となる学習法です。")) {
                    Text("アクティブリコールって何？")
                }
                
                NavigationLink(destination: DetailContentView(title: "分散学習のすすめ", content: "学習を時間的に分散させることで記憶の定着率を高める方法について解説します。一度にやるより分散させた方が効果的な理由とは？")) {
                    Text("分散学習のすすめ")
                }
                
                NavigationLink(destination: DetailContentView(title: "声に出すと覚えやすい理由", content: "学んだ内容を声に出したり書き出したりすることで記憶が強化される「プロダクション効果」について解説します。")) {
                    Text("声に出すと覚えやすい理由")
                }
                
                NavigationLink(destination: DetailContentView(title: "人に教えると自分も学べる理由", content: "誰かに教えることを意識して学ぶことで理解が深まる効果について解説します。「教えることは二度学ぶこと」の秘密とは？")) {
                    Text("人に教えると自分も学べる理由")
                }
            }
        }
        .navigationTitle("効果的な勉強法")
    }
}

// モチベーションについて画面
struct MotivationTipsView: View {
    var body: some View {
        List {
            NavigationLink(destination: DetailContentView(title: "自分に関連づけて覚えよう", content: "学習内容を自分自身の経験や知識と関連づけることで理解と定着を促進する効果について解説します。身近な例で考えると記憶に残りやすくなりますよ。")) {
                HStack {
                    Image(systemName: "person.fill.checkmark")
                        .foregroundColor(.orange)
                    Text("自分に関連づけて覚えよう")
                }
            }
            
//            NavigationLink(destination: DetailContentView(title: "学ぶ意味を見つけよう", content: "学習内容の実生活における価値を認識することでモチベーションを高める方法について解説します。「なぜ学ぶのか」がわかると続けやすくなります。")) {
//                HStack {
//                    Image(systemName: "chart.bar.fill")
//                        .foregroundColor(.orange)
//                    Text("学ぶ意味を見つけよう")
//                }
//            }
//            
//            NavigationLink(destination: DetailContentView(title: "「できる！」という自信の育て方", content: "「自分にはできる」という自信を育み、維持するための実践的な方法を紹介します。小さな成功体験を積み重ねていきましょう。")) {
//                HStack {
//                    Image(systemName: "figure.strengthtraining.traditional")
//                        .foregroundColor(.orange)
//                    Text("「できる！」という自信の育て方")
//                }
//            }
//            
//            NavigationLink(destination: DetailContentView(title: "進歩を目に見える形に", content: "学習の進捗を可視化し、達成感を得ることでモチベーションを維持する方法を解説します。小さな一歩も見逃さず、成長を実感しましょう。")) {
//                HStack {
//                    Image(systemName: "chart.line.uptrend.xyaxis")
//                        .foregroundColor(.orange)
//                    Text("進歩を目に見える形に")
//                }
//            }
//            
//            NavigationLink(destination: DetailContentView(title: "内側から湧き出るやる気の見つけ方", content: "外部からの報酬ではなく、内側から湧き上がるモチベーションを育む方法について解説します。本当の「楽しさ」を見つけると学習が変わります。")) {
//                HStack {
//                    Image(systemName: "heart.fill")
//                        .foregroundColor(.orange)
//                    Text("内側から湧き出るやる気の見つけ方")
//                }
//            }
        }
        .navigationTitle("モチベーション")
    }
}

// 詳細コンテンツ表示用の共通ビュー
struct DetailContentView: View {
    let title: String
    let content: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // ここから各記事の内容
                if title == "自分に関連づけて覚えよう" {
                    selfRelevanceContent
                } else if title == "勉強って何だろう？" {
                    studyBasicsContent
                } else if title == "あまり効果がない勉強法" {
                    ineffectiveMethodsContent
                } else if title == "「わかった気」になる落とし穴" {
                    fluencyIllusionContent
                } else if title == "脳はどう学ぶ？" {
                    learningProcessContent
                } else if title == "本当に効く勉強法" {
                    effectiveMethodsContent
                } else if title == "アクティブリコールって何？" {
                    activeRecallContent
                } else if title == "分散学習のすすめ" {
                    spacedLearningContent
                } else if title == "スキマ時間の活用法" {
                    spareTimeContent
                } else if title == "声に出すと覚えやすい理由" {
                    productionEffectContent
                } else if title == "人に教えると自分も学べる理由" {
                    teachingEffectContent
                } else if title == "アプリの使いこなし方" {
                    appUsageTipsContent
                } else if title == "開発者も実践！効果的な使い方" {
                    developerUsageContent
                } else if title == "タグの上手な使い方" {
                    tagUsageContent
                } else {
                    // その他のページには基本テンプレートを表示
                    Text(content)
                        .padding()
                    
                    Text("このセクションでは「\(title)」について詳しく解説します。実際のアプリでは、ここに詳細な説明文、図解、例示などを追加してください。")
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(title)
    }
    private var selfRelevanceContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("誰でも自分に関係することには興味が湧き、記憶に残りやすいものです。この「自分に関連付ける」を学習に活かすことで、効果が格段にアップします！")
                .padding()
            
            Image(systemName: "person.fill.viewfinder")
                .font(.system(size: 60))
                .foregroundColor(.orange)
                .frame(maxWidth: .infinity)
                .padding()
            
            Text("なぜ自分に関連付けると効果があるの？")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "brain.fill")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("脳が熱心に処理するから")
                            .fontWeight(.semibold)
                        Text("自分に関係する情報は、脳が特別に注意深く処理します。これは生まれつき持っている自然な特性なんです。")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "link")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("既存の知識と結びつけやすいから")
                            .fontWeight(.semibold)
                        Text("自分の経験や知識と関連付けると、新しい情報が記憶のネットワークにしっかり組み込まれます。")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("学ぶ意欲が自然と高まるから")
                            .fontWeight(.semibold)
                        Text("「これは自分に関係ある！」と感じると、自然とやる気が出てきて、集中力も高まります。")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            
            Text("学校で「これ何の役に立つの？」と思った経験、ありませんか？")
                .font(.headline)
                .padding(.horizontal)
            
            Text("学校の授業で「これ将来使わないよね」と思ったことがある人は多いはず。実はこれ、その内容を自分と関連付けられていないサインなんです。何かを学ぶとき、それが自分の生活や将来にどう役立つのかわからないと、やる気も出ないし覚えることもできません。")
                .padding(.horizontal)
                .padding(.bottom, 8)
            
            Text("イーロン・マスクも推奨する方法")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("イーロン・マスクはこう言っています：")
                    .font(.subheadline)
                    .padding(.horizontal)
                
                Text("「何かを覚えるためには、それに意味を与えなければなりません。なぜこれが自分に関連があるのかを言ってください。なぜ、自分に関連があるのかを言えれば、おそらくそれを覚えるでしょう」")
                    .font(.subheadline)
                    .italic()
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
            
            Text("今日から試せる実践法")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                    Text("勉強を始める前に「これが自分の何に役立つか」を1分書き出してみる")
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "person.text.rectangle")
                        .foregroundColor(.blue)
                    Text("「これを友達に説明するとしたら？」と想像してみる")
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "arrow.triangle.merge")
                        .foregroundColor(.blue)
                    Text("勉強する内容と自分の趣味や好きなことを結びつけてみる")
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundColor(.blue)
                    Text("「これがわかると、自分にどんな可能性が広がるか」を考えてみる")
                }
            }
            .padding()
            
            Text("これを「利用価値介入」とも呼びます。特に苦手な科目や内容に取り組むときに効果的です。一度立ち止まって「これは自分にとってどんな意味があるのか」を問いかけてみましょう。学ぶ理由がはっきりすると、不思議とやる気も記憶力も高まりますよ！")
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
        }
    }
    private var appUsageTipsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("RecallMateは科学的に効果が高いとされる学習法を誰でも簡単に実践できるように設計されたアプリです。特にアクティブリコールと分散学習という2つの強力な学習法を上手に組み合わせています。")
                .padding()
            
            Image(systemName: "sparkles.rectangle.stack.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding()
            
            Text("アクティブリコールを実践する方法")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 30, height: 30)
                        Text("1")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("新規メモを作成する")
                            .fontWeight(.semibold)
                        Text("ホーム画面右下の🧠ボタンからメモを作成します")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 30, height: 30)
                        Text("2")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("内容欄を活用する")
                            .fontWeight(.semibold)
                        Text("教材を見ずに、覚えている内容をまず書き出してみましょう")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 30, height: 30)
                        Text("3")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("記憶度の振り返りをする")
                            .fontWeight(.semibold)
                        Text("どのくらい覚えていたかをスライダーで評価します")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            
            Text("分散学習を実践する方法")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    Text("アプリが次の復習タイミングを自動計算し、通知してくれます")
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    Text("記憶度に応じて、次の復習日が最適化されます")
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    Text("徐々に間隔を広げることで、長期記憶への定着を促進します")
                }
            }
            .padding()
            
            Text("より効果を高めるコツ：タグ機能を活用する、問題カードを作成する、スキマ時間に復習する、声に出して読む、などがあります。詳しくは他の記事もぜひ読んでみてくださいね！RecallMateを使えば、科学的に効果の高い学習法を自然と実践できるようになっています。")
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
        }
    }
    
    // 新しく追加した開発者も実践！効果的な使い方のコンテンツ
    private var developerUsageContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("RecallMateの開発者も実際に日々の生活でアプリを活用しています。単なる勉強だけでなく、様々なシーンで記憶の定着に役立てています。ここではその実例をご紹介します。")
                .padding()
            
            Image(systemName: "person.fill.viewfinder")
                .font(.system(size: 60))
                .foregroundColor(.purple)
                .frame(maxWidth: .infinity)
                .padding()
            
            Text("ビジネスシーンでの活用例")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "person.crop.circle.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("人脈の記憶")
                            .fontWeight(.semibold)
                        Text("一度会った方の名前、特徴、話した内容などを記録しておくと次に会ったときに役立ちます")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("アイデアの発展")
                            .fontWeight(.semibold)
                        Text("思いついたアイデアをメモしておき、復習タイミングでさらに発展させていきます")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            
            Text("日常生活での活用例")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "figure.run")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    Text("スポーツのコツや技術をメモして定着させる")
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "quote.bubble.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    Text("気に入った言葉や名言をコレクションする")
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "book.fill")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    Text("読んだ本やマンガのポイントをメモして忘れない")
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    Text("趣味の知識（植物の育て方、料理のコツなど）を記録する")
                }
            }
            .padding()
            
            Text("私たちは「長期記憶に定着したものが、その人を形作っていく」と考えています。覚えたことは、考え方や行動の基盤になります。RecallMateを使って、学校や仕事だけでなく、人生を豊かにする様々な記憶を大切に育ててみてください。あなただけの「知の宝庫」を一緒に作っていきましょう！")
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
        }
    }
    
    // 新しく追加したタグの上手な使い方のコンテンツ
    private var tagUsageContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("タグ機能を使うと、メモを効率よく整理したり、必要なときにすぐに見つけたりできるようになります。上手に活用して、自分だけの学習システムを作りましょう！")
                .padding()
            
            Image(systemName: "tag.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.teal)
                .frame(maxWidth: .infinity)
                .padding()
            
            Text("タグの付け方のコツ")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "smallcircle.filled.circle.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("複数の視点でタグ付けする")
                            .fontWeight(.semibold)
                        Text("例：「数学」という科目タグと「高校」という学校段階のタグを両方つける")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "smallcircle.filled.circle.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("大きな範囲と小さな範囲の両方でタグ付け")
                            .fontWeight(.semibold)
                        Text("例：「科学」と「化学」「有機化学」など階層的につける")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            
            Text("タグの活用例")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "books.vertical.fill")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    Text("科目別：「数学」「英語」「歴史」など")
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "building.2.fill")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    Text("学校/レベル別：「中学」「高校」「大学」「資格」など")
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    Text("テスト時期別：「中間テスト」「期末テスト」「入試」など")
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "graduationcap.fill")
                        .foregroundColor(.purple)
                        .frame(width: 24)
                    Text("重要度別：「重要」「基礎」「発展」など")
                }
            }
            .padding()
            
            Text("タグ検索のコツ：ホーム画面でタグをタップすると、そのタグがついたメモだけを表示できます。複数のタグを選ぶと、それらすべてのタグがついたメモだけが表示されるので、効率的に絞り込みができます。テスト前には「数学」「重要」などの組み合わせで重要な数学のメモだけをピックアップするなど、状況に応じた使い方ができますよ！")
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
        }
    }
    // 各記事の内容をプロパティとして定義
    private var studyBasicsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("勉強は単なる暗記じゃないんです。新しい知識を理解して、長く覚えておくための脳の活動なんですよ。")
                .padding()
            
            Text("本当の「学び」って何だと思いますか？")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.down.doc.fill")
                        .foregroundColor(.blue)
                    Text("新しい情報を取り入れること")
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "brain")
                        .foregroundColor(.purple)
                    Text("その情報の意味を理解すること")
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "archivebox.fill")
                        .foregroundColor(.green)
                    Text("長期的に記憶に残すこと")
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.orange)
                    Text("必要な時に思い出して使えること")
                }
            }
            .padding()
            
            Text("良い勉強法は、ただ覚えるだけでなく、実際に使えるようになることを目指しています。RecallMateは、この過程をより効果的にするためのアプリなんです。")
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
        }
    }
    
    private var ineffectiveMethodsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("多くの人が「繰り返し読む」という勉強法を使っていますが、実はあまり効果的じゃないんです。アメリカのある大学調査では、84%の学生がこの方法を使っていたそうです。")
                .padding()
            
            Image(systemName: "book.fill")
                .font(.system(size: 50))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity)
                .padding()
            
            Text("なぜ「繰り返し読む」だけでは効果が低いの？")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text("受動的な活動のため、脳が深く処理しない")
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text("「わかった気」になりやすく、理解が浅くなる")
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text("長期記憶への定着率が低い")
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("効果を高めるなら、間隔を空けて読み直す")
                }
            }
            .padding()
            
            Text("他にもあまり効果が高くない勉強法：")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("• ハイライトやマーカーだけで終わらせる")
                Text("• 一夜漬けの詰め込み勉強")
                Text("• 受動的な講義視聴だけ")
                Text("• ノートを写すだけで終わる")
            }
            .padding()
            
            Text("これらの方法に共通しているのは、頭を積極的に使っていないこと。効果的な学習には、脳が能動的に情報を処理する必要があるんです。")
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
        }
    }
    
    private var fluencyIllusionContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("「わかった気」になる現象を「流暢性の錯覚」といいます。2回目に教科書を読むとスラスラ読めるから「理解できた！」と思ってしまうんです。でも、実は深く理解できていないことが多いんですよ。")
                .padding()
            
            Text("こんな経験ありませんか？")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    Text("教科書を読み返したら「簡単だな」と思ったけど、テストでは思い出せなかった")
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    Text("解答例を見て「なるほど、自分でも解けたはず」と思ったけど、似た問題が出たら解けなかった")
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    Text("授業中は「わかった」と思っていたけど、後で誰かに説明しようとしたらうまくできなかった")
                }
            }
            .padding()
            
            Text("この落とし穴を避けるコツ：")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.purple)
                    Text("情報を見るだけでなく、自分で思い出してみる")
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "person.fill.questionmark")
                        .foregroundColor(.blue)
                    Text("自分の言葉で説明してみる")
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "pencil")
                        .foregroundColor(.orange)
                    Text("教科書を閉じて書き出してみる")
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.green)
                    Text("他の人に教えるつもりで話してみる")
                }
            }
            .padding()
            
            Text("実は、賢い人ほどこの錯覚にハマりやすいんです。理解が早いため「わかった」と思いがちですが、実際に試してみることで本当の理解度がわかります。RecallMateはそのプロセスをサポートします。")
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
        }
    }
    
    private var learningProcessContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("学習には、ただ暗記するだけではなく、さまざまな段階があります。これを教育学では「教育目標の分類」と呼んでいます。")
                .padding()
            
            Text("学習の6つの段階：")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 30, height: 30)
                        Text("1")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("記憶する")
                            .font(.headline)
                            .foregroundColor(.blue)
                        Text("事実や情報を覚える")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 30, height: 30)
                        Text("2")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("理解する")
                            .font(.headline)
                            .foregroundColor(.green)
                        Text("意味を把握し、説明できる")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 30, height: 30)
                        Text("3")
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("応用する")
                            .font(.headline)
                            .foregroundColor(.orange)
                        Text("学んだことを新しい状況で使える")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.2))
                            .frame(width: 30, height: 30)
                        Text("4")
                            .font(.headline)
                            .foregroundColor(.red)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("分析する")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text("情報を分解し、関係性を見つける")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.2))
                            .frame(width: 30, height: 30)
                        Text("5")
                            .font(.headline)
                            .foregroundColor(.purple)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("評価する")
                            .font(.headline)
                            .foregroundColor(.purple)
                        Text("判断基準に基づいて価値を決める")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.teal.opacity(0.2))
                            .frame(width: 30, height: 30)
                        Text("6")
                            .font(.headline)
                            .foregroundColor(.teal)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("創造する")
                            .font(.headline)
                            .foregroundColor(.teal)
                        Text("新しいアイデアや視点を生み出す")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            
            Text("記憶だけでは不十分で、理解し、応用できることが大切です。でも、記憶は土台。理解や応用をするには、まず基本情報を覚えている必要があります。RecallMateは記憶の定着をサポートすることで、より高度な学習の土台を作ります。")
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
        }
    }
    
    private var effectiveMethodsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("科学的な研究によって、本当に効果があると証明されている勉強法をご紹介します。これらを取り入れるだけで、同じ時間でもぐんと学習効果が上がりますよ。")
                .padding()
            
            Text("アクティブリコール（能動的な思い出し）")
                .font(.headline)
                .padding(.horizontal)
            
            Text("教科書を閉じて、学んだ内容を自分の力で思い出す方法です。単に読み返すより、自ら思い出そうとする行為自体が記憶を強化します。研究によると、この方法は通常の再読より50〜100%も記憶定着率が高いんです。")
                .padding(.horizontal)
            
            Text("分散学習")
                .font(.headline)
                .padding(.horizontal)
            
            Text("一度にガッと勉強するより、適切な間隔を空けて複数回に分けて学ぶ方法です。例えば6時間連続で勉強するより、1時間ずつ6日間に分けた方が記憶に残りやすいことがわかっています。")
                .padding(.horizontal)
            
            Text("その他の効果的な方法：")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "shuffle")
                        .foregroundColor(.purple)
                    VStack(alignment: .leading) {
                        Text("インターリービング（交互学習）")
                            .fontWeight(.semibold)
                        Text("関連する複数の内容を交互に学ぶ")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "text.append")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text("精緻化（エラボレーション）")
                            .fontWeight(.semibold)
                        Text("学んだ内容を詳しく説明したり関連づけたりする")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "person.wave.2.fill")
                        .foregroundColor(.orange)
                    VStack(alignment: .leading) {
                        Text("自己説明")
                            .fontWeight(.semibold)
                        Text("学習内容を自分自身や他者に説明する")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            
            Text("RecallMateはこれらの効果的な学習方法（特にアクティブリコールと分散学習）をもとに設計されています。科学的な学習法を簡単に実践できるようサポートします。")
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
        }
    }
    
    private var activeRecallContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("アクティブリコールとは、「能動的に思い出す」学習法のこと。教科書や参考書を見直すんじゃなくて、一度閉じてから「さて、何が書いてあったっけ？」と自分の力で思い出す方法です。")
                .padding()
            
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding()
            
            Text("なぜ効果があるの？")
                .font(.headline)
                .padding(.horizontal)
            
            Text("情報を見たり聞いたりするだけだと、脳は「受動モード」。でも、自分で思い出そうとすると脳が「能動モード」になって、記憶を引き出す神経回路が強化されるんです。まるで脳の筋トレのようなものですね。")
                .padding(.horizontal)
            
            Text("やり方はカンタン！")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 30, height: 30)
                        Text("1")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    
                    Text("教材を一通り学習する")
                        .fontWeight(.medium)
                }
                
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 30, height: 30)
                        Text("2")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    
                    Text("教材を閉じる")
                        .fontWeight(.medium)
                }
                
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 30, height: 30)
                        Text("3")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    
                    Text("思い出せる内容をすべて書き出す（または口に出す）")
                        .fontWeight(.medium)
                }
                
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 30, height: 30)
                        Text("4")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    
                    Text("思い出せなかった部分を確認する")
                        .fontWeight(.medium)
                }
                
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 30, height: 30)
                        Text("5")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    
                    Text("再度思い出す作業を繰り返す")
                        .fontWeight(.medium)
                }
            }
            .padding()
            
            Text("研究によると、アクティブリコールを実践した学生は、単に教科書を読み返した学生より50〜100%もテストの成績が良かったそうです。しかも、最初に間違えた問題でも、アクティブリコールをすると次回のテストで正解できる確率が上がるんですよ。")
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
        }
    }
    
    private var spacedLearningContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("分散学習とは、学習を一度にまとめてやるんじゃなくて、時間を空けて複数回に分けてやる方法です。例えば、6時間連続で勉強するより、1時間ずつ6日間に分けた方が効果的なんです。")
                .padding()
            
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundColor(.green)
                .frame(maxWidth: .infinity)
                .padding()
            
            Text("なぜ効果があるの？")
                .font(.headline)
                .padding(.horizontal)
            
            Text("人間の脳は、新しい情報を時間をかけて処理し、長期記憶に変換します。エビングハウスの「忘却曲線」によれば、人は学習直後から急速に情報を忘れていきますが、適切なタイミングで復習することで忘却を防げるんです。")
                .padding(.horizontal)
            
            Text("おすすめの復習間隔：")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "1.circle.fill")
                        .foregroundColor(.blue)
                    Text("1回目の復習：1日後")
                        .fontWeight(.medium)
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "2.circle.fill")
                        .foregroundColor(.blue)
                    Text("2回目の復習：1週間後")
                        .fontWeight(.medium)
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "3.circle.fill")
                        .foregroundColor(.blue)
                    Text("3回目の復習：2週間後")
                        .fontWeight(.medium)
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "4.circle.fill")
                        .foregroundColor(.blue)
                    Text("4回目の復習：1ヶ月後")
                        .fontWeight(.medium)
                }
            }
            .padding()
            
            Text("実は睡眠も大切なポイント！脳は睡眠中に学んだ情報を整理して長期記憶に変換します。分散学習では複数の睡眠サイクルを挟むので、このプロセスがより効果的に働くんです。RecallMateは、あなたの記憶度に合わせて最適な復習タイミングを自動的に計算してくれますよ。")
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
        }
    }
    
    // 新しく追加したスキマ時間の活用法のコンテンツ
    private var spareTimeContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("「まとまった時間がないから…」って学習をあきらめていませんか？実は、日常のちょっとした隙間時間を上手に使うだけで、驚くほど学習が進むんです！")
                .padding()
            
            Image(systemName: "hourglass.tophalf.filled")
                .font(.system(size: 60))
                .foregroundColor(.orange)
                .frame(maxWidth: .infinity)
                .padding()
            
            Text("スキマ時間はこんなところに！")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "tram.fill")
                        .foregroundColor(.blue)
                    Text("通勤・通学の電車やバスの中で")
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "cup.and.saucer.fill")
                        .foregroundColor(.brown)
                    Text("休憩時間や待ち時間に")
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "washer.fill")
                        .foregroundColor(.indigo)
                    Text("家事の合間や育児の隙間時間に")
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "bed.double.fill")
                        .foregroundColor(.purple)
                    Text("寝る前の10分間")
                }
            }
            .padding()
            
            Text("スキマ時間活用のメリット")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .frame(width: 24)
                    Text("平日だけでも1日1時間使えば、年間240時間以上の学習時間に！")
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .frame(width: 24)
                    Text("30分ずつ2回に分けて学ぶ方が、1時間まとめてやるより記憶に残りやすい")
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .frame(width: 24)
                    Text("気分転換になって、集中力アップ！")
                }
            }
            .padding()
            
            Text("「学ぶに暇あらずという者は、暇ありといえどもまた学ぶ能わず」（時間がないと言う人は、時間があっても学べない）という中国の古典の言葉があります。時間がないことを言い訳にせず、スキマ時間を活用して一歩ずつ前に進みましょう！RecallMateはスキマ時間での学習にぴったりです。")
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
        }
    }
    
    // 新しく追加した声に出すと覚えやすい理由のコンテンツ
    private var productionEffectContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("「声に出して読むと覚えられる」という経験、ありませんか？実はこれには科学的な根拠があるんです。「プロダクション効果」と呼ばれるこの現象、どうして効果があるのでしょうか？")
                .padding()
            
            Image(systemName: "waveform.circle")
                .font(.system(size: 60))
                .foregroundColor(.purple)
                .frame(maxWidth: .infinity)
                .padding()
            
            Text("声に出すとなぜ覚えやすいの？")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "ear.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("複数の感覚を使うから")
                            .fontWeight(.semibold)
                        Text("目で見るだけでなく、声に出して耳でも聞くので、複数の経路で脳に情報が入ります")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("能動的な処理が起きるから")
                            .fontWeight(.semibold)
                        Text("声に出すには、ただ見るよりも脳が積極的に情報を処理する必要があります")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "person.fill.checkmark")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("情報の「区別性」が高まるから")
                            .fontWeight(.semibold)
                        Text("声に出した情報は「特別」として記憶に残りやすくなります")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            
            Text("研究でわかったこと：")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("声に出して読んだ単語は、黙読した単語よりも10〜20%記憶テストの成績が良かった")
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("書いて覚える方法も同様に効果的")
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("効果は長期間（1週間以上）持続する")
                }
            }
            .padding()
            
            Text("実践のコツ：重要なポイントだけ声に出す、自分で説明してみる、RecallMateのメモ機能を使って書き出してみる。これらを日常に取り入れるだけで、記憶力がぐんとアップしますよ！")
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
        }
    }
    
    // 新しく追加した人に教えると自分も学べる理由のコンテンツ
    private var teachingEffectContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("「教えることで学ぶ」という言葉を聞いたことがありますか？実は、誰かに教えることは、自分自身の学びを深める最も効果的な方法の一つなんです。これは「プロテジェ効果」と呼ばれています。")
                .padding()
            
            Image(systemName: "person.2.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
                .frame(maxWidth: .infinity)
                .padding()
            
            Text("なぜ教えると自分も学べるの？")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("深い理解が必要になるから")
                            .fontWeight(.semibold)
                        Text("他の人にわかりやすく説明するには、自分自身がより深く理解する必要があります")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("知識の再構成が起きるから")
                            .fontWeight(.semibold)
                        Text("頭の中の知識を整理し直して説明しやすい形に組み立て直します")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "exclamationmark.bubble.fill")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("知識のギャップに気づくから")
                            .fontWeight(.semibold)
                        Text("説明しようとして初めて「ここがわかってなかった」と気づくことがあります")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            
            Text("驚きの研究結果：")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .frame(width: 24)
                    Text("「後で誰かに教える予定」と思って勉強した人は、「テストを受ける予定」と思って勉強した人よりも理解度が高かった")
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .frame(width: 24)
                    Text("実際に教えなくても、「教えるつもり」で学ぶだけで効果がある")
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .frame(width: 24)
                    Text("学校で「成績のいい子が他の子に教えている」場面、実は最も学んでいるのは教えている側")
                }
            }
            .padding()
            
            Text("試してみよう：RecallMateで学習する内容を「誰かに説明するつもりで」メモしてみましょう。もし可能なら、実際に友達や家族に学んだことを教えてみてください。驚くほど理解が深まり、記憶に残りますよ！")
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
        }
    }
}
