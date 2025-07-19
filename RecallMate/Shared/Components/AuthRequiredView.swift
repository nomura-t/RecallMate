import SwiftUI

// MARK: - Auth Required View
// 認証が必要な機能にアクセスしようとした際に表示するコンポーネント

struct AuthRequiredView: View {
    let feature: String
    let description: String
    let benefits: [String]
    @State private var showingAuthFlow = false
    
    var body: some View {
        VStack(spacing: UIConstants.extraLargeSpacing) {
            // アイコンとタイトル
            VStack(spacing: UIConstants.mediumSpacing) {
                Circle()
                    .fill(AppColors.primary.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 40))
                            .foregroundColor(AppColors.primary)
                    )
                
                VStack(spacing: UIConstants.smallSpacing) {
                    Text("\\(feature)を利用するには")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("アカウント登録が必要です")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            // 説明文
            Text(description)
                .font(.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // 機能のメリット
            if !benefits.isEmpty {
                VStack(alignment: .leading, spacing: UIConstants.smallSpacing) {
                    ForEach(Array(benefits.enumerated()), id: \.offset) { index, benefit in
                        HStack(spacing: UIConstants.smallSpacing) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppColors.success)
                                .font(.system(size: 16))
                            
                            Text(benefit)
                                .font(.subheadline)
                                .foregroundColor(AppColors.textPrimary)
                        }
                    }
                }
                .padding()
                .background(AppColors.backgroundSecondary)
                .cornerRadius(UIConstants.mediumCornerRadius)
            }
            
            // アクションボタン
            VStack(spacing: UIConstants.mediumSpacing) {
                Button(action: {
                    showingAuthFlow = true
                }) {
                    HStack {
                        Image(systemName: "applelogo")
                            .font(.system(size: 18))
                        Text("Apple でサインイン")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: UIConstants.buttonHeight)
                    .background(Color.black)
                    .cornerRadius(UIConstants.mediumCornerRadius)
                }
                
                Button(action: {
                    showingAuthFlow = true
                }) {
                    Text("匿名でサインイン")
                        .font(.subheadline)
                        .foregroundColor(AppColors.primary)
                }
            }
            .padding(.horizontal)
        }
        .padding(UIConstants.extraLargeSpacing)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.backgroundPrimary)
        .sheet(isPresented: $showingAuthFlow) {
            LoginView()
        }
    }
}

// MARK: - Feature Lock Overlay
// 既存のビューにオーバーレイとして表示するコンポーネント

struct FeatureLockOverlay: View {
    let feature: String
    let description: String
    let benefits: [String]
    @State private var showingAuthFlow = false
    
    var body: some View {
        ZStack {
            // 背景のブラー効果
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // コンテンツ
            VStack(spacing: UIConstants.largeSpacing) {
                VStack(spacing: UIConstants.mediumSpacing) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 50))
                        .foregroundColor(AppColors.primary)
                    
                    VStack(spacing: UIConstants.smallSpacing) {
                        Text("\\(feature)機能")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("アカウント登録で利用できます")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                Text(description)
                    .font(.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: UIConstants.smallSpacing) {
                    Button(action: {
                        showingAuthFlow = true
                    }) {
                        Text("今すぐ登録")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(AppColors.primary)
                            .cornerRadius(UIConstants.mediumCornerRadius)
                    }
                    
                    Button("後で") {
                        // 閉じる処理は親ビューで実装
                    }
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(UIConstants.extraLargeSpacing)
            .background(AppColors.backgroundPrimary)
            .cornerRadius(UIConstants.mediumCornerRadius)
            .shadow(radius: 10)
            .padding(UIConstants.largeSpacing)
        }
        .sheet(isPresented: $showingAuthFlow) {
            LoginView()
        }
    }
}

// MARK: - Auth Status Banner
// アプリ上部に表示する認証ステータスバナー

struct AuthStatusBanner: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var showingAuthFlow = false
    @State private var isDismissed = false
    
    var body: some View {
        if authManager.isAnonymousUser && !isDismissed {
            VStack(spacing: UIConstants.smallSpacing) {
                HStack {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .foregroundColor(AppColors.warning)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("匿名モードで利用中")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("アカウント登録でデータを保護")
                            .font(.caption2)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Button("登録") {
                        showingAuthFlow = true
                    }
                    .font(.caption)
                    .foregroundColor(AppColors.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppColors.primary.opacity(0.1))
                    .cornerRadius(UIConstants.smallCornerRadius)
                    
                    Button(action: {
                        isDismissed = true
                    }) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .padding(.horizontal, UIConstants.mediumSpacing)
                .padding(.vertical, UIConstants.smallSpacing)
                .background(AppColors.warning.opacity(0.1))
            }
            .sheet(isPresented: $showingAuthFlow) {
                LoginView()
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    func requiresAuth(
        feature: String,
        description: String,
        benefits: [String] = []
    ) -> some View {
        @StateObject var authManager = AuthenticationManager.shared
        
        return Group {
            if authManager.isAuthenticated && !authManager.isAnonymousUser {
                self
            } else {
                AuthRequiredView(
                    feature: feature,
                    description: description,
                    benefits: benefits
                )
            }
        }
    }
    
    func lockForAnonymous(
        feature: String,
        description: String,
        benefits: [String] = []
    ) -> some View {
        @StateObject var authManager = AuthenticationManager.shared
        @State var showingLock = false
        
        return ZStack {
            self
                .disabled(authManager.isAnonymousUser)
                .onTapGesture {
                    if authManager.isAnonymousUser {
                        showingLock = true
                    }
                }
            
            if showingLock {
                FeatureLockOverlay(
                    feature: feature,
                    description: description,
                    benefits: benefits
                )
                .onTapGesture {
                    showingLock = false
                }
            }
        }
    }
}

// MARK: - Preview
struct AuthRequiredView_Previews: PreviewProvider {
    static var previews: some View {
        AuthRequiredView(
            feature: "フレンド機能",
            description: "友達と一緒に学習したり、学習記録を共有することができます。",
            benefits: [
                "友達と学習進捗を共有",
                "一緒に学習セッションを開催",
                "学習記録のバックアップ",
                "複数デバイスでの同期"
            ]
        )
    }
}