// NotificationSettingsView.swift - 通知設定の統合管理画面
import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @StateObject private var notificationSettings = NotificationSettingsManager.shared
    @State private var showingTimePicker = false
    @State private var tempNotificationTime = Date()
    
    var body: some View {
        NavigationView {
            Form {
                // 通知の全体制御
                Section(header: Text("通知設定")) {
                    Toggle("通知を有効にする", isOn: $notificationSettings.isNotificationEnabled)
                        .onChange(of: notificationSettings.isNotificationEnabled) { _, newValue in
                            if newValue {
                                notificationSettings.enableNotifications()
                            } else {
                                notificationSettings.disableAllNotifications()
                            }
                        }
                    
                    if notificationSettings.isNotificationEnabled {
                        // 通知時間の設定
                        HStack {
                            Text("通知時間")
                            Spacer()
                            Button(notificationSettings.formattedNotificationTime) {
                                tempNotificationTime = notificationSettings.notificationTime
                                showingTimePicker = true
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }
                
                // 通知の種類別設定
                if notificationSettings.isNotificationEnabled {
                    Section(header: Text("通知の種類")) {
                        Toggle("学習ストリークリマインダー", isOn: $notificationSettings.streakReminderEnabled)
                        Toggle("復習リマインダー", isOn: $notificationSettings.reviewReminderEnabled)
//                        Toggle("学習目標達成通知", isOn: $notificationSettings.goalAchievementEnabled)
                    }
                    
                    Section(header: Text("通知頻度")) {
                        Picker("リマインダー頻度", selection: $notificationSettings.reminderFrequency) {
                            Text("毎日").tag(ReminderFrequency.daily)
                            Text("平日のみ").tag(ReminderFrequency.weekdays)
                            Text("週3回").tag(ReminderFrequency.threeTimesWeek)
                        }
                    }
                }
                
                // 通知の状態表示
                Section(header: Text("システム情報")) {
                    HStack {
                        Text("システム通知許可")
                        Spacer()
                        Text(notificationSettings.systemPermissionStatus)
                            .foregroundColor(notificationSettings.hasSystemPermission ? .green : .red)
                    }
                    
                    if !notificationSettings.hasSystemPermission {
                        Button("設定アプリで許可する") {
                            notificationSettings.openSystemSettings()
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("通知設定")
        }
        .sheet(isPresented: $showingTimePicker) {
            TimePickerView(
                selectedTime: $tempNotificationTime,
                onSave: {
                    notificationSettings.updateNotificationTime(tempNotificationTime)
                    showingTimePicker = false
                },
                onCancel: {
                    showingTimePicker = false
                }
            )
        }
        .onAppear {
            notificationSettings.refreshPermissionStatus()
        }
    }
}

enum ReminderFrequency: String, CaseIterable {
    case daily = "毎日"
    case weekdays = "平日のみ"
    case threeTimesWeek = "週3回"
}
