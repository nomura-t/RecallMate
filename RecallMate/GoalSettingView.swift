// GoalSettingView.swift
import SwiftUI

struct GoalSettingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var goalManager = StudyGoalManager.shared
    
    @State private var tempGoalMinutes: Int = 60
    @State private var tempIsEnabled: Bool = true
    
    let goalOptions = [15, 30, 45, 60, 90, 120, 180, 240]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("学習目標設定")) {
                    Toggle("学習目標を有効にする", isOn: $tempIsEnabled)
                    
                    if tempIsEnabled {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("1日の学習目標時間")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            Picker("目標時間", selection: $tempGoalMinutes) {
                                ForEach(goalOptions, id: \.self) { minutes in
                                    Text(formatGoalTime(minutes))
                                        .tag(minutes)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(height: 120)
                            
                            // カスタム時間入力
                            HStack {
                                Text("カスタム:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Stepper(
                                    value: $tempGoalMinutes,
                                    in: 5...480,
                                    step: 5
                                ) {
                                    Text("\(tempGoalMinutes)分")
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                }
                
                if tempIsEnabled {
                    Section(header: Text("目標の効果")) {
                        GoalBenefitsView(goalMinutes: tempGoalMinutes)
                    }
                }
                
                Section(header: Text("ストリーク記録")) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.red)
                        Text("現在のストリーク")
                        Spacer()
                        Text("\(goalManager.currentStreak)日")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.orange)
                        Text("最長ストリーク")
                        Spacer()
                        Text("\(goalManager.bestStreak)日")
                            .fontWeight(.semibold)
                    }
                    
                    Button("ストリークをリセット") {
                        resetStreak()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("学習目標")
            .navigationBarItems(
                leading: Button("キャンセル") {
                    dismiss()
                },
                trailing: Button("保存") {
                    saveSettings()
                    dismiss()
                }
            )
            .onAppear {
                tempGoalMinutes = goalManager.dailyGoalMinutes
                tempIsEnabled = goalManager.isGoalEnabled
            }
        }
    }
    
    private func formatGoalTime(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 && remainingMinutes > 0 {
            return "\(hours)時間\(remainingMinutes)分"
        } else if hours > 0 {
            return "\(hours)時間"
        } else {
            return "\(minutes)分"
        }
    }
    
    private func saveSettings() {
        goalManager.updateDailyGoal(minutes: tempGoalMinutes)
        goalManager.toggleGoal(enabled: tempIsEnabled)
    }
    
    private func resetStreak() {
        UserDefaults.standard.set(0, forKey: "currentStreak")
        UserDefaults.standard.set(0, forKey: "bestStreak")
        goalManager.currentStreak = 0
        goalManager.bestStreak = 0
    }
}

struct GoalBenefitsView: View {
    let goalMinutes: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            BenefitRow(
                icon: "brain.head.profile",
                title: "記憶定着の向上",
                description: "\(goalMinutes)分の学習で効果的な記憶定着が期待できます"
            )
            
            BenefitRow(
                icon: "calendar",
                title: "学習習慣の形成",
                description: "毎日の継続で強固な学習習慣を築けます"
            )
            
            BenefitRow(
                icon: "chart.line.uptrend.xyaxis",
                title: "進捗の可視化",
                description: "達成度を確認してモチベーションを維持できます"
            )
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.system(size: 16))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
