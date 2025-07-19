import SwiftUI

struct SocialTabView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var selectedTab = 0
    @State private var showLoginView = false
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                // 認証済みユーザー向けのソーシャル機能
                authenticatedSocialView
            } else {
                // 未認証ユーザー向けのログイン促進画面
                unauthenticatedView
            }
        }
        .sheet(isPresented: $showLoginView) {
            LoginView()
        }
        .onAppear {
            // 未認証の場合はログイン画面を表示
            if !authManager.isAuthenticated {
                showLoginView = true
            }
        }
    }
    
    // MARK: - Authenticated Social View
    
    private var authenticatedSocialView: some View {
        TabView(selection: $selectedTab) {
            // フレンド
            FriendsView()
                .tabItem {
                    Label("フレンド", systemImage: "person.2.fill")
                }
                .tag(0)
            
            // グループ
            StudyGroupsView()
                .tabItem {
                    Label("グループ", systemImage: "person.3.fill")
                }
                .tag(1)
            
            // チャット
            GroupChatListView()
                .tabItem {
                    Label("チャット", systemImage: "message.fill")
                }
                .badge(totalUnreadMessages)
                .tag(2)
            
            // 掲示板
            DiscussionBoardView()
                .tabItem {
                    Label("掲示板", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .tag(3)
            
            // ランキング
            RankingView()
                .tabItem {
                    Label("ランキング", systemImage: "trophy.fill")
                }
                .tag(4)
            
            // 通知
            NotificationListView()
                .tabItem {
                    Label("通知", systemImage: "bell.fill")
                }
                .badge(notificationManager.unreadCount)
                .tag(5)
        }
        .onAppear {
            // 認証済みユーザーの場合は通知を読み込み
            Task {
                await notificationManager.loadNotifications()
            }
        }
    }
    
    // MARK: - Unauthenticated View
    
    private var unauthenticatedView: some View {
        VStack(spacing: 32) {
            // ソーシャル機能の説明
            VStack(spacing: 16) {
                Image(systemName: "person.3.sequence.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("ソーシャル学習")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("フレンドと一緒に学習して、\nモチベーションを高めましょう")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 60)
            
            // 機能紹介
            VStack(spacing: 20) {
                featureCard(
                    icon: "person.badge.plus",
                    title: "フレンドを追加",
                    description: "学習仲間を見つけて、お互いの進捗を共有しましょう"
                )
                
                featureCard(
                    icon: "person.3.fill",
                    title: "学習グループ",
                    description: "同じ目標を持つ仲間とグループを作って一緒に学習"
                )
                
                featureCard(
                    icon: "message.fill",
                    title: "グループチャット",
                    description: "リアルタイムでコミュニケーションを取りながら学習"
                )
                
                featureCard(
                    icon: "trophy.fill",
                    title: "ランキング",
                    description: "学習時間や成果を競って、モチベーションを維持"
                )
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // ログインボタン
            Button {
                showLoginView = true
            } label: {
                Text("ログインしてソーシャル機能を使う")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Feature Card
    
    private func featureCard(icon: String, title: String, description: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Properties
    
    private var totalUnreadMessages: Int {
        // 実際の実装では GroupChatManager から未読数を取得
        return 0
    }
}

// MARK: - Preview

struct SocialTabView_Previews: PreviewProvider {
    static var previews: some View {
        SocialTabView()
    }
}