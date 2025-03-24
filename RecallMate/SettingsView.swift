// SettingsView.swift - 未使用設定を削除
import SwiftUI

struct SettingsView: View {
    // 削除: isDarkMode（使われていない）
    @State private var notificationEnabled = true
    // 削除: defaultReviewInterval（使われていない）
    @State private var currentNotificationTime = ""
    
    // 設定クラスをEnvironmentObjectとして追加
    @EnvironmentObject private var appSettings: AppSettings
    
    var body: some View {
        NavigationStack {
            Form {
                // SettingsView.swift の修正部分

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
                Section(header: Text("一般設定")) {
                    // 削除: ダークモード設定（使われていない）
                    Toggle("通知を有効にする", isOn: $notificationEnabled)
                        .onChange(of: notificationEnabled) { enabled in
                            if enabled {
                                StreakNotificationManager.shared.scheduleStreakReminder()
                            } else {
                                // 通知を無効化する処理（必要に応じて）
                            }
                        }
                }
                
                // テキストフォントサイズ設定セクション - 両方のフォントサイズを設定
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

                // 削除: 復習設定セクション（使われていない）
            }
            .navigationTitle("")
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
}
