import SwiftUI

struct PomodoroUsageModalView: View {
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
                    Text("ポモドーロテクニック")
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
                        // ポモドーロテクニックの説明
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ポモドーロテクニックとは？")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("集中して作業をする時間と短い休憩を交互に繰り返すことで、生産性を高める時間管理法です。通常、25分の作業と5分の休憩を1セットとして行います。")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        
                        // 使い方の説明
                        VStack(alignment: .leading, spacing: 10) {
                            Text("基本的な使い方")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top) {
                                    Text("1")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(width: 20, height: 20)
                                        .background(Color.red)
                                        .cornerRadius(10)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("タイマーをスタート")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Text("中央の再生ボタンを押して、作業セッションをスタートします。")
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
                                        .background(Color.red)
                                        .cornerRadius(10)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("集中して作業")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Text("タイマーが終了するまで、集中して作業に取り組みます。途中で一時停止することもできます。")
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
                                        .background(Color.red)
                                        .cornerRadius(10)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("休憩を取る")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Text("作業時間が終わると自動的に休憩モードに切り替わります。リフレッシュしましょう。")
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
                                        .background(Color.red)
                                        .cornerRadius(10)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("サイクルを繰り返す")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Text("4セッション終了すると、より長い休憩が取れます。ポモドーロテクニックを続けてみましょう。")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.leading, 4)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        
                        // ポモドーロテクニックのコツ
                        VStack(alignment: .leading, spacing: 8) {
                            Text("効果的に使うコツ")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                BulletPoint(text: "作業開始前に、何をするか明確にしておきましょう")
                                BulletPoint(text: "作業中は通知をオフにして、集中環境を作りましょう")
                                BulletPoint(text: "休憩時間はしっかり休み、画面から離れましょう")
                                BulletPoint(text: "長時間の作業は複数のポモドーロに分けると効果的です")
                                BulletPoint(text: "実績を記録して、モチベーションを維持しましょう")
                            }
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                        
                        // アプリの操作方法
                        VStack(alignment: .leading, spacing: 8) {
                            Text("アプリの操作方法")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                IconExplanation(icon: "play.fill", text: "再生ボタン - タイマーをスタート")
                                IconExplanation(icon: "pause.fill", text: "一時停止ボタン - 作業を中断")
                                IconExplanation(icon: "arrow.clockwise", text: "リセットボタン - タイマーをリセット")
                                IconExplanation(icon: "gear", text: "設定ボタン - 作業時間や休憩時間をカスタマイズ")
                            }
                        }
                        .padding()
                        
                        // ポモドーロテクニックの効果
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ポモドーロテクニックの効果")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("集中力の向上、作業効率のアップ、疲労の軽減、時間管理スキルの向上などの効果があります。続けることでさらに効果が高まります。")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
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

//struct BulletPoint: View {
//    let text: String
//    
//    var body: some View {
//        HStack(alignment: .top, spacing: 6) {
//            Text("•")
//                .font(.caption)
//            
//            Text(text)
//                .font(.caption)
//                .foregroundColor(.secondary)
//        }
//    }
//}

struct IconExplanation: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundColor(.blue)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
