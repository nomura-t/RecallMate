import SwiftUI

struct UsageModalView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // 半透明の背景オーバーレイ
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // 背景タップでモーダルを閉じる
                    withAnimation {
                        isPresented = false
                    }
                }
            
            // モーダルコンテンツ
            VStack(spacing: 0) {
                // ヘッダー部分
                HStack {
                    Text("アクティブリコール・メソッド".localized)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // 閉じるボタン
                    Button(action: {
                        withAnimation {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                
                // コンテンツ部分をスクロールビューで表示
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // 3つの記憶術の説明
                        VStack(alignment: .leading, spacing: 8) {
                            Text("3つの記憶術のしくみ".localized)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            // アクティブリコール
                            HStack(alignment: .top, spacing: 12) {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Text("1")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("アクティブリコール".localized)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Text("情報を思い出そうとすることで、記憶が強くなります。ただ読み返すよりも、自分で思い出す方が記憶に残ります！".localized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // プロダクション効果
                            HStack(alignment: .top, spacing: 12) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Text("2")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("プロダクション効果".localized)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Text("声に出しながら情報を書き出すことで、記憶に定着しやすくなります。".localized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // 自己説明効果
                            HStack(alignment: .top, spacing: 12) {
                                Circle()
                                    .fill(Color.purple)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Text("3")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("自己説明効果".localized)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Text("学んだことを自分で説明すると理解が深まります。誰かに教えるつもりで説明すると記憶に残ります！".localized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        Divider()
                        
                        // やり方の説明
                        VStack(alignment: .leading, spacing: 10) {
                            Text("やり方はカンタン4ステップ".localized)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top) {
                                    Text("1")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(width: 20, height: 20)
                                        .background(Color.blue)
                                        .cornerRadius(10)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("覚えたいことを教科書を見ないで書き出す".localized)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Text("まずは自分の力で思い出してみましょう。わからなくても大丈夫！".localized)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.leading, 4)
                                }
                                
                                HStack(alignment: .top) {
                                    Text("2")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(width: 20, height: 20)
                                        .background(Color.blue)
                                        .cornerRadius(10)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("わからない点は教科書で確認する".localized)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Text("思い出せなかった部分を確認して、知識を補いましょう。".localized)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.leading, 4)
                                }
                                
                                HStack(alignment: .top) {
                                    Text("3")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(width: 20, height: 20)
                                        .background(Color.blue)
                                        .cornerRadius(10)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("①と②を繰り返す".localized)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Text("再度挑戦して、どれだけ覚えているか試してみましょう。".localized)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.leading, 4)
                                }
                                
                                HStack(alignment: .top) {
                                    Text("4")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(width: 20, height: 20)
                                        .background(Color.blue)
                                        .cornerRadius(10)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("時間をおいてまた、①〜③を繰り返す".localized)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Text("翌日など時間をあけると、より記憶に残りやすくなります。RecallMateが自動的に最適な復習タイミングを計算してお知らせしてくれます。".localized)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.leading, 4)
                                }
                            }
                        }
                        
                        Divider()
                        
                        // アプリでの活用法
                        VStack(alignment: .leading, spacing: 8) {
                            Text("RecallMateでの活用法".localized)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            // 新規記録の使い方
                            VStack(alignment: .leading, spacing: 6) {
                                Text("新規記録の使い方".localized)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    BulletPoint(text: "勉強したあと、教科書を閉じてアプリを開きます".localized)
                                    BulletPoint(text: "思い出せることを「新規記録」に書きます".localized)
                                    BulletPoint(text: "わからない部分は確認して追加します".localized)
                                    BulletPoint(text: "自分の言葉で書くのがポイントです！".localized)
                                }
                            }
                            .padding(.vertical, 8)
                            
                            // 問題カードの使い方
                            VStack(alignment: .leading, spacing: 6) {
                                Text("問題カードの使い方".localized)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    BulletPoint(text: "重要な概念を問題カードにします".localized)
                                    BulletPoint(text: "自分で答えを説明してみます（自己説明）".localized)
                                    BulletPoint(text: "複数の概念を比較する問題も作れます".localized)
                                    BulletPoint(text: "定期的に問題カードを見直すと効果的！".localized)
                                }
                            }
                        }
                        
                        // おすすめの使い方
                        VStack(alignment: .leading, spacing: 4) {
                            Text("おすすめのポイント".localized)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("勉強したあとすぐにRecallMateで内容を思い出して書いてみましょう。図や表も自分で書き直すと、より記憶に残ります。".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        }
                        .padding()
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding()
                }
                .background(Color(.systemBackground))
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.9)
            .frame(maxHeight: UIScreen.main.bounds.height * 0.8)
            .cornerRadius(12)
            .shadow(radius: 10)
        }
        .transition(.opacity)
    }
}

struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .font(.caption)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
