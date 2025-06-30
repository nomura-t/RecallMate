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
                Section(header: Text("学習目標設定".localized)) {
                    Toggle("学習目標を有効にする".localized, isOn: $tempIsEnabled)
                    
                    if tempIsEnabled {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("1日の学習目標時間".localized)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            Picker("目標時間".localized, selection: $tempGoalMinutes) {
                                ForEach(goalOptions, id: \.self) { minutes in
                                    Text(formatGoalTime(minutes))
                                        .tag(minutes)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(height: 120)
                            
                            // カスタム時間入力
                            HStack {
                                Text("カスタム:".localized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Stepper(
                                    value: $tempGoalMinutes,
                                    in: 5...480,
                                    step: 5
                                ) {
                                    Text("%d分".localizedFormat(tempGoalMinutes))
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                }
                
                if tempIsEnabled {
                    Section(header: Text("目標の効果".localized)) {
                        GoalBenefitsView(goalMinutes: tempGoalMinutes)
                    }
                }
                
                Section(header: Text("ストリーク記録".localized)) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.red)
                        Text("現在のストリーク".localized)
                        Spacer()
                        Text("%d日".localizedFormat(goalManager.currentStreak))
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.orange)
                        Text("最長ストリーク".localized)
                        Spacer()
                        Text("%d日".localizedFormat(goalManager.bestStreak))
                            .fontWeight(.semibold)
                    }
                    
                    Button("ストリークをリセット".localized) {
                        resetStreak()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("学習目標".localized)
            .navigationBarItems(
                leading: Button("キャンセル".localized) {
                    dismiss()
                },
                trailing: Button("保存".localized) {
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
            return "%d時間%d分".localizedFormat(hours, remainingMinutes)
        } else if hours > 0 {
            return "%d時間".localizedFormat(hours)
        } else {
            return "%d分".localizedFormat(minutes)
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
                title: "記憶定着の向上".localized,
                description: "%d分の学習で効果的な記憶定着が期待できます".localizedFormat(goalMinutes)
            )
            
            BenefitRow(
                icon: "calendar",
                title: "学習習慣の形成".localized,
                description: "毎日の継続で強固な学習習慣を築けます".localized
            )
            
            BenefitRow(
                icon: "chart.line.uptrend.xyaxis",
                title: "進捗の可視化".localized,
                description: "達成度を確認してモチベーションを維持できます".localized
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
