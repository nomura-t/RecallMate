import SwiftUI

struct SocialShareView: View {
    @Binding var isPresented: Bool
    @State private var showMissingAppAlert = false
    @State private var missingAppName = ""
    @State private var showShareSheet = false
    var shareText: String? = nil
    
    // 利用可能なプラットフォームのみ表示
    private var availablePlatforms: [SocialPlatform] {
        SocialPlatform.allCases.filter { platform in
            if platform == .system {
                return true // システム共有は常に利用可能
            }
            return ShareService.shared.canShareTo(platform: platform)
        }
    }
    
    var body: some View {
        ZStack {
            // 背景オーバーレイ
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        isPresented = false
                    }
                }
            
            // シェアオプションパネル
            VStack(spacing: 20) {
                // タイトル
                Text("アプリを共有")
                    .font(.headline)
                    .padding(.top)
                
                // プラットフォームリスト
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {
                    ForEach(availablePlatforms) { platform in
                        PlatformShareButton(
                            platform: platform,
                            shareText: shareText,
                            onMissingApp: { appName in
                                missingAppName = appName
                                showMissingAppAlert = true
                            },
                            onSystemShare: {
                                showShareSheet = true
                            }
                        )
                    }
                }
                .padding(.horizontal)
                
                // 閉じるボタン
                Button("キャンセル") {
                    withAnimation {
                        isPresented = false
                    }
                }
                .foregroundColor(.gray)
                .padding(.bottom)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 10)
            .frame(width: UIScreen.main.bounds.width * 0.8)
        }
        .alert(isPresented: $showMissingAppAlert) {
            Alert(
                title: Text("\(missingAppName)がインストールされていません"),
                message: Text("共有するには\(missingAppName)アプリをインストールしてください。"),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $showShareSheet) {
            if #available(iOS 16.0, *) {
                SystemSharePresenter(text: shareText ?? ShareService.shared.defaultShareText)
            } else {
                LegacySystemSharePresenter(text: shareText ?? ShareService.shared.defaultShareText)
            }
        }        .onAppear {
            // 通知リスナーを設定
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("MissingAppNotification"),
                object: nil,
                queue: .main
            ) { notification in
                if let appName = notification.userInfo?["appName"] as? String {
                    missingAppName = appName
                    showMissingAppAlert = true
                }
            }
        }
    }
}

// 各プラットフォームのシェアボタン
struct PlatformShareButton: View {
    let platform: SocialPlatform
    let shareText: String?
    let onMissingApp: (String) -> Void
    let onSystemShare: () -> Void
    
    var body: some View {
        Button(action: {
            shareAction()
        }) {
            VStack {
                // プラットフォームのカスタムアイコンまたはシステムアイコン
                if UIImage(named: platform.iconName) != nil {
                    Image(platform.iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                } else {
                    Image(systemName: platform.systemIconName)
                        .font(.system(size: 30))
                        .foregroundColor(platform.color)
                        .frame(width: 40, height: 40)
                }
                
                Text(platform.displayName)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 10)
            .frame(width: 80)
        }
    }
    
    private func shareAction() {
        switch platform {
        case .line:
            ShareService.shared.shareViaLINE(text: shareText)
        case .whatsapp:
            ShareService.shared.shareViaWhatsApp(text: shareText)
        case .facebook:
            ShareService.shared.shareViaFacebook()
        case .instagram:
            ShareService.shared.shareViaInstagram()
        case .twitter:
            ShareService.shared.shareViaTwitter(text: shareText)
        case .system:
            onSystemShare()
        }
    }
}

// iOSバージョンに応じたシェアシート


// iOS 16以降用
@available(iOS 16.0, *)
struct SystemSharePresenter: UIViewControllerRepresentable {
    let text: String
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityItems: [Any] = [text]
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
// iOS 16未満用の互換性ビュー
struct LegacySystemSharePresenter: UIViewControllerRepresentable {
    let text: String
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityItems: [Any] = [text]
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

