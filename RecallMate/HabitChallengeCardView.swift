import SwiftUI

// 習慣化チャレンジカードビュー
struct HabitChallengeCardView: View {
    @ObservedObject private var challengeManager = HabitChallengeManager.shared
    @State private var showInfoModal = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("習慣化チャレンジ".localized)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 情報ボタン
                Button(action: {
                    showInfoModal = true
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                }
            }
            
            HStack(spacing: 10) { // ここの spacing を小さくする（元の値を10に変更）
                // 進捗表示（円形プログレス）
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 6)
                        .frame(width: 50, height: 50)
                    
                    Circle()
                        .trim(from: 0, to: min(CGFloat(challengeManager.currentStreak) / CGFloat(66), 1.0))
                        .stroke(progressColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(challengeManager.currentStreak)")
                        .font(.system(size: 14, weight: .bold))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("%d/66日".localizedWithInt(challengeManager.currentStreak))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if challengeManager.currentStreak > 0 {
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("毎日5分以上学習して習慣化しよう！".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.leading, 0) // 左側の余白を削除する
                
                Spacer()
                
                // メダル表示
                HStack(spacing: 6) {
                    MedalView(isAchieved: challengeManager.bronzeAchieved, medalType: .bronze)
                    MedalView(isAchieved: challengeManager.silverAchieved, medalType: .silver)
                    MedalView(isAchieved: challengeManager.goldAchieved, medalType: .gold)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        .sheet(isPresented: $showInfoModal) {
            HabitChallengeInfoView()
        }
        .alert("最初の1週間を達成！".localized, isPresented: $challengeManager.showBronzeModal) {
            Button("ありがとう！".localized, role: .cancel) { }
        } message: {
            Text("おめでとうございます！最初の1週間が最も大変な時期です。あなたはそれを乗り越えました！この調子で続けていきましょう！".localized)
        }
        .alert("3週間達成！".localized, isPresented: $challengeManager.showSilverModal) {
            Button("ありがとう！".localized, role: .cancel) { }
        } message: {
            Text("素晴らしいです！3週間の継続は大きな達成です。あなたは習慣化の中間地点に到達しました。このままあと45日続ければ、完全な習慣になります！".localized)
        }
        .alert("66日間達成！".localized, isPresented: $challengeManager.showGoldModal) {
            Button("ありがとう！".localized, role: .cancel) { }
        } message: {
            Text("おめでとうございます！研究によると、66日間の継続で行動は無意識の習慣になります。あなたは学習を習慣化することに成功しました！今後も継続することで、その効果はさらに大きくなります。".localized)
        }
    }
    
    // 進捗に応じた色を返す
    private var progressColor: Color {
        if challengeManager.goldAchieved {
            return .yellow
        } else if challengeManager.silverAchieved {
            return .gray
        } else if challengeManager.bronzeAchieved {
            return .orange
        } else {
            return .blue
        }
    }
    
    // 進捗に応じたメッセージを返す
    private var statusMessage: String {
        let streak = challengeManager.currentStreak
        
        if streak < 3 {
            return "始めたばかり！続けていきましょう！".localized
        } else if streak < 7 {
            return "最初の1週間が肝心です！あと\(7-streak)日！".localized
        } else if streak < 21 {
            return "順調です！3週間まであと\(21-streak)日！".localized
        } else if streak < 66 {
            return "素晴らしい！習慣化まであと\(66-streak)日！".localized
        } else {
            return "習慣化達成おめでとうございます！".localized
        }
    }
}

// メダル表示用のビュー
struct MedalView: View {
    let isAchieved: Bool
    let medalType: MedalType
    
    enum MedalType {
        case bronze
        case silver
        case gold
        
        var symbol: String {
            switch self {
            case .bronze: return "🥉"
            case .silver: return "🥈"
            case .gold: return "🥇"
            }
        }
        
        var requirement: String {
            switch self {
            case .bronze: return "7日".localized
            case .silver: return "21日".localized
            case .gold: return "66日".localized
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text(medalType.symbol)
                .font(.system(size: 16))
                .opacity(isAchieved ? 1.0 : 0.3)
            
            Text(medalType.requirement)
                .font(.system(size: 8))
                .foregroundColor(.gray)
        }
    }
}

// 習慣化チャレンジの説明ビュー
struct HabitChallengeInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // タイトル
                    Text("習慣化チャレンジについて".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    // 説明テキスト
                    Text("習慣化チャレンジは、学習を日常的な習慣にするためのプログラムです。研究によると、新しい習慣が定着するのに約66日かかると言われています。".localized)
                        .padding(.bottom, 8)
                    
                    Text("チャレンジのルール:".localized)
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HabitBulletPoint(text: "毎日最低5分以上学習する".localized)
                        HabitBulletPoint(text: "1日でも記録がないとカウンターはリセットされます".localized)
                        HabitBulletPoint(text: "7日達成で銅メダル獲得".localized)
                        HabitBulletPoint(text: "21日達成で銀メダル獲得".localized)
                        HabitBulletPoint(text: "66日達成で金メダル獲得！習慣化の目標達成".localized)
                    }
                    .padding(.bottom, 16)
                    
                    Text("習慣化の3つのステージ:".localized)
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        StageDescriptionView(
                            title: "最初の3日～1週間".localized,
                            description: "最も意志力が必要な期間。ここを乗り越えることが重要です。".localized,
                            image: "person.and.arrow.left.and.arrow.right",
                            color: .orange
                        )
                        
                        StageDescriptionView(
                            title: "2～3週間目".localized,
                            description: "少しずつ慣れ始める時期ですが、まだ意識的に続ける必要があります。".localized,
                            image: "arrow.up.forward",
                            color: .blue
                        )
                        
                        StageDescriptionView(
                            title: "約2ヶ月後（66日前後）".localized,
                            description: "無意識で続けられる状態に近づいています。この時点で学習が習慣化したと言えます。".localized,
                            image: "checkmark.circle",
                            color: .green
                        )
                    }
                    .padding(.bottom, 16)
                    
                    Text("ヒント:".localized)
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HabitBulletPoint(text: "毎日同じ時間に学習すると習慣化しやすくなります".localized)
                        HabitBulletPoint(text: "小さく始めて、徐々に時間を増やしていくのが効果的です".localized)
                        HabitBulletPoint(text: "「学習のきっかけ」を決めておくと継続しやすくなります（例：夕食後に5分）".localized)
                    }
                }
                .padding()
            }
            .navigationTitle("習慣化チャレンジ".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// 箇条書き項目の表示用コンポーネント
struct HabitBulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.body)
                .foregroundColor(.blue)
            
            Text(text)
                .font(.body)
        }
    }
}
// ステージ説明用コンポーネント
struct StageDescriptionView: View {
    let title: String
    let description: String
    let image: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: image)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
}
