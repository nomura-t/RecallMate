import SwiftUI
import Foundation

struct SettingsView: View {
    @State private var notificationEnabled = true
    @State private var currentNotificationTime = ""
    
    // 設定クラスをEnvironmentObjectとして追加
    @EnvironmentObject private var appSettings: AppSettings
    
    // シェア関連の状態変数
    @State private var isShareSheetPresented = false
    @State private var showMissingAppAlert = false
    @State private var missingAppName = ""
    @State private var shareText = "RecallMateアプリを使って科学的に記憶力を強化しています。長期記憶の定着に最適なアプリです！ https://apps.apple.com/app/recallmate/id000000000" // 実際のApp StoreリンクIDに変更する
    
    var body: some View {
        NavigationStack {
            Form {
#if DEBUG
                Section(header: Text("開発者オプション")) {
                    Button("レビュー誘導画面をリセット") {
                        ReviewManager.shared.resetReviewRequest()
                    }
                    
                    Button("レビュー誘導画面を表示") {
                        ReviewManager.shared.shouldShowReview = true
                    }
                    
                    // UserDefaultsの値を表示
                    let taskCount = UserDefaults.standard.integer(forKey: "task_completion_count")
                    Text("タスク完了カウント: \(taskCount)/15")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
#endif
                
                // アプリを共有セクション
                Section {
                    HStack(alignment: .center) {
                        // テキスト部分 - タップ不可
                        VStack(alignment: .leading, spacing: 4) {
                            Text("RecallMateを友達に紹介する")
                                .font(.headline)
                            
                            Text("効率的な学習方法を友達にも教えてあげましょう")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // LINEアイコン部分のみタップ可能
                        Button(action: {
                            shareAppViaLINE()
                        }) {
                            VStack(spacing: 2) {
                                Image(systemName: "arrow.up.square")
                                    .font(.system(size: 30))
                                    .foregroundColor(.green)
                                    .frame(width: 40, height: 40)
                                Text("LINE")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("アプリを共有")
                }
                
                Section(header: Text("一般設定")) {
                    Toggle("通知を有効にする", isOn: $notificationEnabled)
                        .onChange(of: notificationEnabled) { enabled in
                            if enabled {
                                StreakNotificationManager.shared.scheduleStreakReminder()
                            } else {
                                // 通知を無効化する処理（必要に応じて）
                            }
                        }
                }
                
                // テキストフォントサイズ設定セクション
                Section(header: Text("テキスト設定")) {
                    VStack(alignment: .leading, spacing: 16) {
                        // 回答テキストのフォントサイズの選択
                        VStack(alignment: .leading, spacing: 4) {
                            Picker("回答フォントサイズ", selection: $appSettings.answerFontSize) {
                                ForEach(appSettings.availableFontSizes, id: \.self) { size in
                                    Text("\(Int(size))pt").tag(size)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            
                            // 回答テキストのプレビュー
                            Text("回答テキストのプレビュー")
                                .font(.system(size: CGFloat(appSettings.answerFontSize)))
                                .padding(.vertical, 4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        Divider()
                        
                        // メモ入力欄のフォントサイズの選択
                        VStack(alignment: .leading, spacing: 4) {
                            Picker("メモフォントサイズ", selection: $appSettings.memoFontSize) {
                                ForEach(appSettings.availableFontSizes, id: \.self) { size in
                                    Text("\(Int(size))pt").tag(size)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            
                            // メモテキストのプレビュー
                            Text("メモテキストのプレビュー")
                                .font(.system(size: CGFloat(appSettings.memoFontSize)))
                                .padding(.vertical, 4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                
                Section(header: Text("通知設定")) {
                    HStack {
                        Text("現在の通知時間:")
                        Spacer()
                        Text(StreakNotificationManager.shared.getPreferredTimeString())
                            .foregroundColor(.gray)
                    }
                    
                    Button("現在時刻を通知時間に設定") {
                        StreakNotificationManager.shared.updatePreferredTime()
                        // ビューを更新するために現在の通知時間を取得
                        currentNotificationTime = StreakNotificationManager.shared.getPreferredTimeString()
                    }
                }
                .disabled(!notificationEnabled)
            }
            .navigationTitle("")
            .sheet(isPresented: $isShareSheetPresented) {
                TextShareSheet(text: shareText)
            }
            .alert(isPresented: $showMissingAppAlert) {
                Alert(
                    title: Text("\(missingAppName)がインストールされていません"),
                    message: Text("共有するには\(missingAppName)アプリをインストールしてください。"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                // ビューが表示されるたびに現在の通知時間を更新
                currentNotificationTime = StreakNotificationManager.shared.getPreferredTimeString()
                
                // 現在のフォントサイズが選択肢になければ、近い値に調整
                if !appSettings.availableFontSizes.contains(appSettings.answerFontSize) {
                    let closest = appSettings.availableFontSizes.min(by: {
                        abs($0 - appSettings.answerFontSize) < abs($1 - appSettings.answerFontSize)
                    }) ?? 16
                    appSettings.answerFontSize = closest
                }
                
                // メモフォントサイズも同様に調整
                if !appSettings.availableFontSizes.contains(appSettings.memoFontSize) {
                    let closest = appSettings.availableFontSizes.min(by: {
                        abs($0 - appSettings.memoFontSize) < abs($1 - appSettings.memoFontSize)
                    }) ?? 16
                    appSettings.memoFontSize = closest
                }
            }
        }
    }
    
    // LINEで共有
    func shareAppViaLINE() {
        let encodedText = shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let lineURL = URL(string: "https://line.me/R/msg/text/?\(encodedText)")!
        
        if UIApplication.shared.canOpenURL(lineURL) {
            UIApplication.shared.open(lineURL)
        } else {
            // LINEアプリがインストールされていない場合
            showAlertForMissingApp(name: "LINE")
        }
    }
    
    // システム共有シート
    func showShareSheet() {
        isShareSheetPresented = true
    }
    
    // アプリがインストールされていない場合のアラート
    func showAlertForMissingApp(name: String) {
        missingAppName = name
        showMissingAppAlert = true
    }
}

// TextShareSheet構造体
struct TextShareSheet: UIViewControllerRepresentable {
    var text: String
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityItems: [Any] = [text]
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
