// ReviewRequestView.swift
import SwiftUI
import StoreKit

// iOS 18以降の新しいAppStore APIのインポート
#if canImport(AppStore)
import AppStore
#endif

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
                Text("RecallMateをお使いいただきありがとうございます".localized)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                Text("アプリは気に入っていただけましたか？".localized)
                    .font(.subheadline)
                
                HStack(spacing: 30) {
                    // いいえボタン
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("いいえ".localized)
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
                        Text("はい".localized)
                            .frame(width: 100)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                
                if hasRespondedPositively {
                    Text("開発者(tenten)の励みになります。良かったらレビューをお願いします！".localized)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        requestReview()
                        isPresented = false
                    }) {
                        Text("レビューを書く".localized)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("また今度".localized)
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
        // iOS 18以降では新しいAppStore APIを使用
        if #available(iOS 18.0, *) {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                AppStore.requestReview(in: scene)
            }
        } else {
            // iOS 14.0-17.x では従来のStoreKit APIを使用
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
    }
}
