import SwiftUI

struct SocialView: View {
    @State private var selectedSegment = 0
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var friendshipManager = FriendshipManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var showingAuthFlow = false
    
    var body: some View {
        NavigationView {
            socialContent
                .navigationTitle("ソーシャル")
                .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            Task {
                await authManager.checkCurrentSession()
            }
        }
        .sheet(isPresented: $showingAuthFlow) {
            AuthenticationView()
        }
    }
    
    private var socialContent: some View {
        VStack(spacing: 0) {
            // セグメントコントロール
            Picker("Social Options", selection: $selectedSegment) {
                Text("友達").tag(0)
                Text("グループ").tag(1)
                Text("ランキング").tag(2)
                Text("通知").tag(3)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.top, 16)
            
            // 選択されたセグメントに応じてコンテンツを表示
            TabView(selection: $selectedSegment) {
                FriendsView()
                    .tag(0)
                
                StudyGroupsView()
                    .tag(1)
                
                RankingView()
                    .tag(2)
                
                NotificationListView()
                    .tag(3)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut, value: selectedSegment)
        }
    }
    
    private var authenticationPromptContent: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("ソーシャル機能を使用するには")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("友達との学習共有やグループ機能を利用するために、アカウントにログインしてください。")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: {
                showingAuthFlow = true
            }) {
                Text("ログイン・新規登録")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(25)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

struct SocialView_Previews: PreviewProvider {
    static var previews: some View {
        SocialView()
    }
}