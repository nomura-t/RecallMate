// AppInfoView.swift
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
                                Text("このアプリの使い方")
                                    .font(.headline)
                                
                                Text("基本機能と活用のヒント")
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
                                Text("効果のある勉強法について")
                                    .font(.headline)
                                
                                Text("科学的に証明された学習テクニック")
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
                                Text("モチベーションについて")
                                    .font(.headline)
                                
                                Text("学習意欲を維持するための方法")
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
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("開発者")
                        Spacer()
                        Text("RecallMate Team")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("このアプリについて")
            .navigationBarTitleDisplayMode(.inline)
            // 戻るナビゲーションボタンを削除しました
        }
    }
}

// アプリの使い方画面
struct AppUsageGuideView: View {
    var body: some View {
        List {
            Section(header: Text("基本的な使い方")) {
                NavigationLink(destination: DetailContentView(title: "スキマ時間の利用法", content: "スキマ時間の効果的な活用方法について解説します。短い時間でも積み重ねることで大きな効果を生み出せます。")) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                        Text("スキマ時間の利用法")
                    }
                }
                
                NavigationLink(destination: DetailContentView(title: "アプリ応用法", content: "RecallMateの様々な機能を組み合わせた応用的な使い方を紹介します。学習効果を最大化しましょう。")) {
                    HStack {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .foregroundColor(.blue)
                        Text("アプリ応用法")
                    }
                }
                
                NavigationLink(destination: DetailContentView(title: "開発者はこう使っている", content: "開発チームが実践している効果的なRecallMateの活用法を紹介します。開発者ならではの視点とコツをご覧ください。")) {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.blue)
                        Text("開発者はこう使っている")
                    }
                }
            }
            
            Section(header: Text("ヒントとコツ")) {
                // 追加のヒント項目
                NavigationLink(destination: DetailContentView(title: "タグの活用方法", content: "タグ機能を使って学習内容を整理する方法について解説します。")) {
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundColor(.blue)
                        Text("タグの活用方法")
                    }
                }
                
                NavigationLink(destination: DetailContentView(title: "復習のタイミング", content: "最適な復習のタイミングと、通知機能の使い方について説明します。")) {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(.blue)
                        Text("復習のタイミング")
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
            Section(header: Text("学習の基礎")) {
                NavigationLink(destination: DetailContentView(title: "勉強とは？", content: "効果的な学習とは何か、その本質について解説します。")) {
                    Text("勉強とは？")
                }
                
                NavigationLink(destination: DetailContentView(title: "効果の薄い勉強法", content: "時間を費やしていても効果が低い勉強法について解説します。")) {
                    Text("効果の薄い勉強法")
                }
                
                NavigationLink(destination: DetailContentView(title: "やっちゃいがちな流暢性の錯覚", content: "「わかった気になる」という認知バイアスと、それを避ける方法について解説します。")) {
                    Text("やっちゃいがちな流暢性の錯覚")
                }
                
                NavigationLink(destination: DetailContentView(title: "学習の認知過程", content: "脳がどのように情報を処理し、記憶に定着させるかについての科学的解説です。")) {
                    Text("学習の認知過程")
                }
            }
            
            Section(header: Text("科学的に証明された学習法")) {
                NavigationLink(destination: DetailContentView(title: "効果の高い勉強法", content: "科学的研究により効果が実証されている学習方法を紹介します。")) {
                    Text("効果の高い勉強法")
                }
                
                NavigationLink(destination: DetailContentView(title: "アクティブリコールメソッドについて", content: "能動的に情報を思い出すことでより強固な記憶を形成する手法について詳しく解説します。")) {
                    Text("アクティブリコールメソッドについて")
                }
                
                NavigationLink(destination: DetailContentView(title: "分散学習について", content: "学習を時間的に分散させることで記憶の定着率を高める方法について解説します。")) {
                    Text("分散学習について")
                }
                
                NavigationLink(destination: DetailContentView(title: "プロダクション効果", content: "学んだ内容を声に出したり書き出したりすることで記憶を強化する効果について解説します。")) {
                    Text("プロダクション効果")
                }
                
                NavigationLink(destination: DetailContentView(title: "連続的再学習について", content: "効果的な復習サイクルと、記憶の長期定着のためのテクニックを解説します。")) {
                    Text("連続的再学習について")
                }
                
                NavigationLink(destination: DetailContentView(title: "学習の実感", content: "学習の進捗を適切に自己評価する方法と、実感と実際の効果の関係について解説します。")) {
                    Text("学習の実感")
                }
                
                NavigationLink(destination: DetailContentView(title: "プロテジェ効果", content: "誰かに教えることを意識して学ぶことで理解が深まる効果について解説します。")) {
                    Text("プロテジェ効果")
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
            NavigationLink(destination: DetailContentView(title: "自己関連づけ効果", content: "学習内容を自分自身の経験や知識と関連付けることで理解と定着を促進する効果について解説します。")) {
                HStack {
                    Image(systemName: "person.fill.checkmark")
                        .foregroundColor(.orange)
                    Text("自己関連づけ効果")
                }
            }
            
            NavigationLink(destination: DetailContentView(title: "利用価値介入", content: "学習内容の実生活における価値を認識することでモチベーションを高める方法について解説します。")) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.orange)
                    Text("利用価値介入")
                }
            }
            
            NavigationLink(destination: DetailContentView(title: "自己効力感の高め方", content: "「自分にはできる」という自信を育み、維持するための実践的な方法を紹介します。")) {
                HStack {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .foregroundColor(.orange)
                    Text("自己効力感の高め方")
                }
            }
            
            NavigationLink(destination: DetailContentView(title: "自分の進捗を確認しよう", content: "学習の進捗を可視化し、達成感を得ることでモチベーションを維持する方法を解説します。")) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.orange)
                    Text("自分の進捗を確認しよう")
                }
            }
            
            NavigationLink(destination: DetailContentView(title: "内発的な目標", content: "外部からの報酬ではなく、内側から湧き上がるモチベーションを育む方法について解説します。")) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.orange)
                    Text("内発的な目標")
                }
            }
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
                Text(content)
                    .padding()
                
                // ここに各トピックの詳細コンテンツを追加
                Text("このセクションでは「\(title)」について詳しく解説します。実際のアプリでは、ここに詳細な説明文、図解、例示などを追加してください。")
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(title)
    }
}

// プレビュー用
struct AppInfoView_Previews: PreviewProvider {
    static var previews: some View {
        AppInfoView()
    }
}
