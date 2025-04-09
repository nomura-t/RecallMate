// OnboardingView.swift
import SwiftUI

struct OnboardingView: View {
    @Binding var isShowingOnboarding: Bool
    @State private var currentPage = 0
    
    // チュートリアルページの内容
    private let pages: [(image: String, title: String, description: String)] = [
        (
            image: "doc.text",
            title: "新規メモを作成",
            description: "ホーム画面右下の「🧠」ボタンから学習内容のメモを作成できます。"
        ),
        (
            image: "arrow.clockwise",
            title: "アクティブリコール",
            description: "メモを閉じて学んだ内容を思い出し、記憶を強化しましょう。"
        ),
        (
            image: "calendar",
            title: "分散学習",
            description: "最適な間隔で復習することで、長期記憶への定着率が向上します。"
        ),
        (
            image: "slider.horizontal.3",
            title: "記憶度の評価",
            description: "記憶度を評価すると、次回の復習タイミングが自動的に最適化されます。"
        ),
        (
            image: "timer",
            title: "ポモドーロタイマー",
            description: "集中力を最大化するポモドーロテクニックを活用しましょう。"
        ),
        // 最後に脳アイコン誘導を追加
        (
            image: "brain.head.profile",
            title: "メモを作成してみましょう",
            description: "ホーム画面に戻ったら、右下の脳アイコンをタップして最初のメモを作成してみましょう！"
        )
    ]
    
    var body: some View {
        ZStack {
            // 背景オーバーレイ（画面全体をカバー）
            Color(.systemBackground)
                .edgesIgnoringSafeArea(.all)
                .opacity(0.95)
            
            // コンテンツ部分（中央に位置する小さいカード）
            VStack {
                // スキップボタン
                HStack {
                    Spacer()
                    Button("スキップ") {
                        withAnimation {
                            isShowingOnboarding = false
                            saveOnboardingShown()
                        }
                    }
                    .padding()
                }
                
                Spacer()
                
                // コンテンツカード - サイズを制限
                VStack {
                    TabView(selection: $currentPage) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            VStack(spacing: 15) {
                                Image(systemName: pages[index].image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.blue)
                                
                                Text(pages[index].title)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                
                                Text(pages[index].description)
                                    .font(.subheadline)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                    .foregroundColor(.secondary)
                            }
                            .tag(index)
                            .padding()
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                    .frame(height: 280) // 高さを制限
                    
                    // 次へ/開始ボタン - クリック領域を修正
                    Button(action: {
                        if currentPage < pages.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            withAnimation {
                                isShowingOnboarding = false
                                saveOnboardingShown()
                            }
                        }
                    }) {
                        Text(currentPage == pages.count - 1 ? "RecallMateを始める" : "次へ")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(20)
                .shadow(radius: 10)
                .padding(.horizontal, 40) // 水平方向のパディングを追加して小さく
                
                Spacer()
            }
        }
    }
    
    // オンボーディングが表示されたことを保存
    private func saveOnboardingShown() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
    }
}
