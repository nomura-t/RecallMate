import SwiftUI

struct PomodoroView: View {
    @StateObject private var pomodoroTimer = PomodoroTimer()
    @State private var showSettings = false
    
    // 使い方モーダルの表示状態を管理する変数を追加
    @State private var showUsageModal = false
    
    // タイマープログレスの色
    private func progressColor() -> Color {
        switch pomodoroTimer.currentSession {
        case .work:
            return .red
        case .shortBreak:
            return .green
        case .longBreak:
            return .blue
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // セッション情報
                HStack {
                    Spacer()
                    
                    VStack {
                        Text(pomodoroTimer.currentSession.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        // セッションカウンター
                        if pomodoroTimer.currentSession == .work {
                            Text("セッション: \(pomodoroTimer.sessionCount + 1)")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // 使い方ボタンを追加
                    Button(action: {
                        showUsageModal = true
                    }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 22))
                            .foregroundColor(.blue)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .padding(.trailing, 16)
                    .highPriorityGesture(
                        TapGesture()
                            .onEnded { _ in
                                showUsageModal = true
                                
                                // ハプティックフィードバック
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }
                    )
                }
                .padding(.top)
                
                // 通知許可状態を表示
                if !pomodoroTimer.notificationsEnabled {
                    HStack {
                        Image(systemName: "bell.slash")
                            .foregroundColor(.red)
                        Text("通知が許可されていません。設定アプリで許可してください。")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .onTapGesture {
                        // 設定アプリを開く
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                
                // タイマー表示
                ZStack {
                    // 背景円
                    Circle()
                        .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    
                    // プログレス円
                    Circle()
                        .trim(from: 0, to: pomodoroTimer.progress)
                        .stroke(progressColor(), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: pomodoroTimer.progress)
                    
                    // 残り時間
                    Text(pomodoroTimer.formattedTimeRemaining())
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                }
                .padding(40)
                .frame(height: 300)
                
                // コントロールボタン
                HStack(spacing: 40) {
                    // リセットボタン
                    Button(action: {
                        pomodoroTimer.reset()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title)
                            .foregroundColor(.primary)
                    }
                    
                    // 再生/一時停止ボタン
                    Button(action: {
                        // 通知許可を再確認
                        pomodoroTimer.recheckNotificationPermission()
                        
                        switch pomodoroTimer.timerState {
                        case .stopped:
                            pomodoroTimer.start()
                        case .running:
                            pomodoroTimer.pause()
                        case .paused:
                            pomodoroTimer.resume()
                        }
                    }) {
                        Image(systemName: pomodoroTimer.timerState == .running ? "pause.fill" : "play.fill")
                            .font(.system(size: 50))
                            .foregroundColor(progressColor())
                    }
                    
                    // 設定ボタン
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gear")
                            .font(.title)
                            .foregroundColor(.primary)
                    }
                }
                .padding(.vertical, 40)
                
                // セッション説明
                VStack(alignment: .leading, spacing: 5) {
                    switch pomodoroTimer.currentSession {
                    case .work:
                        Text("🧠 集中して作業しましょう")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    case .shortBreak:
                        Text("☕️ 短い休憩でリフレッシュ")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    case .longBreak:
                        Text("🌿 長い休憩でしっかり回復")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                
                Spacer()
            }
            .padding()
            .navigationTitle("")
            .onAppear {
                // 画面表示時に通知許可を確認
                pomodoroTimer.recheckNotificationPermission()
            }
            .sheet(isPresented: $showSettings) {
                PomodoroSettingsView(pomodoroTimer: pomodoroTimer)
            }
            .overlay(
                // 「使い方」モーダルの表示
                Group {
                    if showUsageModal {
                        PomodoroUsageModalView(isPresented: $showUsageModal)
                            .transition(.opacity)
                            .animation(.easeInOut, value: showUsageModal)
                    }
                }
            )
        }
    }
}
// 設定画面
struct PomodoroSettingsView: View {
    @ObservedObject var pomodoroTimer: PomodoroTimer
    @Environment(\.dismiss) private var dismiss
    
    // 設定項目の一時保存
    @State private var workMinutes: Double = 25
    @State private var shortBreakMinutes: Double = 5
    @State private var longBreakMinutes: Double = 15
    @State private var longBreakAfter: Double = 4
    @State private var notificationSound: String = "default"
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("作業時間")) {
                    Slider(value: $workMinutes, in: 5...60, step: 5) {
                        Text("作業時間: \(Int(workMinutes))分")
                    }
                    Text("\(Int(workMinutes))分")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                
                Section(header: Text("短い休憩")) {
                    Slider(value: $shortBreakMinutes, in: 1...15, step: 1) {
                        Text("短い休憩: \(Int(shortBreakMinutes))分")
                    }
                    Text("\(Int(shortBreakMinutes))分")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                
                Section(header: Text("長い休憩")) {
                    Slider(value: $longBreakMinutes, in: 5...30, step: 5) {
                        Text("長い休憩: \(Int(longBreakMinutes))分")
                    }
                    Text("\(Int(longBreakMinutes))分")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                
                Section(header: Text("長い休憩の頻度")) {
                    Slider(value: $longBreakAfter, in: 2...8, step: 1) {
                        Text("\(Int(longBreakAfter))セッションごと")
                    }
                    Text("\(Int(longBreakAfter))セッションごとに長い休憩")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                
                Section(header: Text("通知音")) {
                    Picker("通知音", selection: $notificationSound) {
                        Text("デフォルト").tag("default")
                        Text("なし").tag("none")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section {
                    Button("設定を保存") {
                        // 設定を保存
                        pomodoroTimer.workDuration = workMinutes * 60
                        pomodoroTimer.shortBreakDuration = shortBreakMinutes * 60
                        pomodoroTimer.longBreakDuration = longBreakMinutes * 60
                        pomodoroTimer.longBreakAfter = Int(longBreakAfter)
                        pomodoroTimer.notificationSound = notificationSound
                        
                        // タイマーが停止中であれば新しい設定を反映
                        if pomodoroTimer.timerState == .stopped {
                            pomodoroTimer.reset()
                        }
                        
                        dismiss()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                
                // 通知確認セクション
                if !pomodoroTimer.notificationsEnabled {
                    Section {
                        Button("通知設定を開く") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                        Text("タイマー終了通知を受け取るには通知を許可してください")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("ポモドーロ設定")
            .navigationBarItems(trailing: Button("閉じる") {
                dismiss()
            })
            .onAppear {
                // 現在の設定を読み込み
                workMinutes = pomodoroTimer.workDuration / 60
                shortBreakMinutes = pomodoroTimer.shortBreakDuration / 60
                longBreakMinutes = pomodoroTimer.longBreakDuration / 60
                longBreakAfter = Double(pomodoroTimer.longBreakAfter)
                notificationSound = pomodoroTimer.notificationSound
                
                // 通知許可を確認
                pomodoroTimer.recheckNotificationPermission()
            }
        }
    }
}
