// QuestionEditorUsageModalView.swift
import SwiftUI

struct QuestionEditorUsageModalView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // 背景オーバーレイ
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // 背景タップでモーダルを閉じる
                    withAnimation {
                        isPresented = false
                    }
                }
            
            // モーダルコンテンツ
            VStack(alignment: .leading, spacing: 16) {
                // ヘッダー部分
                HStack {
                    Text("問題編集の使い方".localized)
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
                
                // スクロール可能なコンテンツ
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 問題をコピー機能の説明
                        FeatureExplanationView(
                            title: "問題をコピー機能".localized,
                            icon: "doc.on.doc",
                            color: .blue,
                            description: "登録されている問題をクリップボードにコピーし、AIツールで回答を作成できます。".localized
                        )
                        
                        // 手順
                        Text("使い方：".localized)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            StepView(number: 1, text: "右上の「...」メニューから「問題をコピー」を選択".localized)
                            StepView(number: 2, text: "問題がクリップボードにコピーされます".localized)
                            StepView(number: 3, text: "AIツールに貼り付けて回答を依頼".localized)
                        }
                        .padding(.bottom, 8)
                        
                        // コピーされるフォーマットの例
                        Text("コピーされる形式：".localized)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("以下の問題に対する回答を作成してください。各回答の前には「問題X回答:」というタグをつけてください。\n\n問題1: 「記憶定着」について説明してください。\n補足情報: この概念、特徴、重要性について詳しく述べてください。...".localized)
                            .font(.caption)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        // 回答をインポート機能の説明
                        FeatureExplanationView(
                            title: "回答をインポート機能".localized,
                            icon: "square.and.arrow.down",
                            color: .green,
                            description: "AIツールなどで作成された回答を問題と自動的に紐づけて一括インポートします。".localized
                        )
                        
                        // 手順
                        Text("使い方：".localized)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            StepView(number: 1, text: "AIからの回答テキスト全体をコピー".localized)
                            StepView(number: 2, text: "「...」メニューから「回答をインポート」を選択".localized)
                            StepView(number: 3, text: "表示される画面に回答を貼り付け".localized)
                            StepView(number: 4, text: "システムが自動的に「問題X回答:」の形式を認識".localized)
                            StepView(number: 5, text: "「回答を適用」ボタンを押して取り込み完了".localized)
                        }
                        .padding(.bottom, 8)
                        
                        // インポート可能な回答形式の例
                        Text("インポート可能な回答形式：".localized)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("問題1回答: 記憶定着とは、学習した内容を長期記憶として保持する過程を指します。...\n\n問題2回答: アクティブリコールと分散学習の主な違いは次の通りです...".localized)
                            .font(.caption)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding()
                }
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.9)
            .frame(maxHeight: UIScreen.main.bounds.height * 0.8)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 10)
        }
        .transition(.opacity)
    }
}

// 機能説明コンポーネント
struct FeatureExplanationView: View {
    let title: String
    let icon: String
    let color: Color
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// 手順説明用コンポーネント
struct StepView: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 24, height: 24)
                
                Text("\(number)")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            
            Text(text)
                .font(.subheadline)
        }
    }
}
