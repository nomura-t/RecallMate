// ReviewRequestView.swift
import SwiftUI
import StoreKit

struct ReviewRequestView: View {
    @Binding var isPresented: Bool
    @State private var hasRespondedPositively = false
    
    var body: some View {
        ZStack {
            // 背景オーバーレイ
            Color(.black)
                .opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    isPresented = false
                }
            
            // モーダルカード
            VStack(spacing: 20) {
                Text("RecallMateをお使いいただきありがとうございます")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                Text("アプリは気に入っていただけましたか？")
                    .font(.subheadline)
                
                HStack(spacing: 30) {
                    // いいえボタン
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("いいえ")
                            .frame(width: 100)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                    }
                    
                    // はいボタン
                    Button(action: {
                        hasRespondedPositively = true
                    }) {
                        Text("はい")
                            .frame(width: 100)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                
                if hasRespondedPositively {
                    Text("開発者の励みになります。良かったらレビューをお願いします！")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        requestReview()
                        isPresented = false
                    }) {
                        Text("レビューを書く")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("また今度")
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 5)
                }
            }
            .padding(25)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding(.horizontal, 40)
        }
    }
    
    private func requestReview() {
        // iOS 14.0以降でのレビュー依頼方法
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}
