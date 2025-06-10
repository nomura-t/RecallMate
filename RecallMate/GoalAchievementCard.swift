// GoalAchievementCard.swift（完全版）
import SwiftUI

struct GoalAchievementCard: View {
    let todayStudySeconds: Int
    let goalMinutes: Int
    let currentStreak: Int
    let bestStreak: Int
    let onSettingsPressed: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    // 既存のコード（前回と同じ）...
    private var achievementRate: Double {
        guard goalMinutes > 0 else { return 0.0 }
        let studyMinutes = Double(todayStudySeconds) / 60.0
        return min(studyMinutes / Double(goalMinutes), 1.0)
    }
    
    private var todayStudyMinutes: Int {
        Int(ceil(Double(todayStudySeconds) / 60.0))
    }
    
    private var isGoalAchieved: Bool {
        todayStudyMinutes >= goalMinutes
    }
    
    private var remainingMinutes: Int {
        max(0, goalMinutes - todayStudyMinutes)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // ヘッダー
            HStack {
                Text("今日の学習目標")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: onSettingsPressed) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                }
            }
            
            // メイン達成度表示
            HStack(spacing: 24) {
                // 円形プログレス
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2), lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(achievementRate))
                        .stroke(
                            achievementProgressColor,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.8), value: achievementRate)
                    
                    VStack(spacing: 2) {
                        Text("\(Int(achievementRate * 100))")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(achievementProgressColor)
                        
                        Text("%")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                // 詳細情報
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(.blue)
                            .font(.system(size: 16))
                        
                        Text("目標: \(goalMinutes)分")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 16))
                        
                        Text("実績: \(formattedStudyTime)")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    
                    if isGoalAchieved {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 16))
                            
                            Text("目標達成！")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                    } else {
                        HStack {
                            Image(systemName: "timer")
                                .foregroundColor(.orange)
                                .font(.system(size: 16))
                            
                            Text("残り: \(remainingMinutes)分")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    // ストリーク表示
                    if currentStreak > 0 {
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 16))
                            
                            Text("\(currentStreak)日連続達成")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
            
            // プログレスバー（補助表示）
            VStack(spacing: 8) {
                HStack {
                    Text("進捗")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundColor(achievementProgressColor)
                        .fontWeight(.medium)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                            .cornerRadius(3)
                        
                        Rectangle()
                            .fill(achievementProgressColor)
                            .frame(width: geometry.size.width * CGFloat(achievementRate), height: 6)
                            .cornerRadius(3)
                            .animation(.easeInOut(duration: 0.8), value: achievementRate)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1),
                    radius: 4,
                    x: 0,
                    y: 2
                )
        )
    }
    
    // 達成度に応じた色
    private var achievementProgressColor: Color {
        if isGoalAchieved {
            return .green
        } else if achievementRate >= 0.8 {
            return .orange
        } else if achievementRate >= 0.5 {
            return .yellow
        } else {
            return .blue
        }
    }
    
    // ステータスメッセージ
    private var statusMessage: String {
        if isGoalAchieved {
            return "目標達成！素晴らしいです"
        } else if achievementRate >= 0.8 {
            return "もう少しで達成です！"
        } else if achievementRate >= 0.5 {
            return "順調に進んでいます"
        } else if achievementRate > 0 {
            return "良いスタートです"
        } else {
            return "今日も頑張りましょう"
        }
    }
    
    // 学習時間のフォーマット
    private var formattedStudyTime: String {
        let hours = todayStudyMinutes / 60
        let minutes = todayStudyMinutes % 60
        
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }
}

// 追加コンポーネント1: 統計情報カード
struct GoalStatisticsCard: View {
    let todayStudySeconds: Int
    let goalMinutes: Int
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var todayStudyMinutes: Int {
        Int(ceil(Double(todayStudySeconds) / 60.0))
    }
    
    private var isGoalAchieved: Bool {
        todayStudyMinutes >= goalMinutes
    }
    
    private var overageMinutes: Int {
        max(0, todayStudyMinutes - goalMinutes)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("今日の詳細統計")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                StatisticItem(
                    title: "学習時間",
                    value: "\(todayStudyMinutes)分",
                    icon: "clock.fill",
                    color: .blue
                )
                
                StatisticItem(
                    title: "目標時間",
                    value: "\(goalMinutes)分",
                    icon: "target",
                    color: .purple
                )
                
                if isGoalAchieved && overageMinutes > 0 {
                    StatisticItem(
                        title: "目標超過",
                        value: "+\(overageMinutes)分",
                        icon: "plus.circle.fill",
                        color: .green
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05),
                    radius: 2,
                    x: 0,
                    y: 1
                )
        )
    }
}

// 統計アイテム個別コンポーネント
struct StatisticItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// 追加コンポーネント2: 目標無効時のカード
struct GoalDisabledCard: View {
    let onEnablePressed: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "target")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.6))
            
            Text("学習目標を設定しませんか？")
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text("1日の学習目標を設定することで、継続的な学習習慣を身につけることができます。")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: onEnablePressed) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    
                    Text("目標を設定する")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(20)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1),
                    radius: 4,
                    x: 0,
                    y: 2
                )
        )
    }
}

// 追加コンポーネント3: 目標達成お祝いビュー
struct GoalAchievementCelebrationView: View {
    @Binding var isPresented: Bool
    let studyMinutes: Int
    let goalMinutes: Int
    let currentStreak: Int
    
    var body: some View {
        ZStack {
            // 半透明オーバーレイ
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        isPresented = false
                    }
                }
            
            // お祝いカード
            VStack(spacing: 20) {
                // アニメーション付きアイコン
                Image(systemName: "party.popper.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                    .scaleEffect(isPresented ? 1.2 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: isPresented)
                
                Text("🎉 目標達成！🎉")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                VStack(spacing: 8) {
                    Text("今日は\(studyMinutes)分学習しました")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("目標の\(goalMinutes)分を達成です！")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if currentStreak > 1 {
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.red)
                            
                            Text("\(currentStreak)日連続達成中")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        .padding(.top, 8)
                    }
                }
                
                Button(action: {
                    withAnimation {
                        isPresented = false
                    }
                }) {
                    Text("素晴らしい！")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 120)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(20)
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 20)
            )
            .padding(.horizontal, 40)
            .scaleEffect(isPresented ? 1.0 : 0.8)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isPresented)
        }
    }
}
