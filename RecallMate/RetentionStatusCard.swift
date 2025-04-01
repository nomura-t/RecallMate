import SwiftUI

struct RetentionStatusCard: View {
    let retentionPercentage: Int
    
    init(retentionPercentage: Int) {
        self.retentionPercentage = max(0, min(100, retentionPercentage))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ヘッダー部分
            HStack {
                Text("記憶定着度")
                    .font(.headline)
                
                Spacer()
                
                Text("\(retentionPercentage)%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(retentionColor)
            }
            
            // プログレスバー
            MemoryRetentionProgressBar(retentionPercentage: retentionPercentage, showLabel: false)
            
            // 記憶度説明
            HStack(alignment: .top) {
                Image(systemName: statusIcon)
                    .foregroundColor(retentionColor)
                
                Text(retentionDescription)
                    .font(.subheadline)
            }
            
            // 詳細説明
            Text(retentionDetailedDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.primary.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // 記憶度に応じた色を返す
    private var retentionColor: Color {
        switch retentionPercentage {
        case 81...100:
            return .green
        case 51...80:
            return .yellow
        case 21...50:
            return .orange
        default:
            return .red
        }
    }
    
    // 記憶度に応じたアイコンを返す
    private var statusIcon: String {
        switch retentionPercentage {
        case 81...100:
            return "brain.head.profile"
        case 51...80:
            return "brain"
        case 21...50:
            return "questionmark.circle"
        default:
            return "exclamationmark.triangle"
        }
    }
    
    // 記憶度に応じた説明テキストを返す
    private var retentionDescription: String {
        switch retentionPercentage {
        case 91...100:
            return "完璧に覚えた！自信満々！"
        case 81...90:
            return "十分に理解、自分の言葉で説明可能"
        case 71...80:
            return "だいたい理解している"
        case 61...70:
            return "要点は覚えている"
        case 51...60:
            return "基本概念は思い出せる"
        case 41...50:
            return "断片的に覚えている"
        case 31...40:
            return "うっすらと覚えている"
        case 21...30:
            return "ほとんど忘れている"
        case 1...20:
            return "ほぼ完全に忘れている"
        default:
            return "全く覚えていない"
        }
    }
    
    // 記憶度に応じた詳細説明を返す
    private var retentionDetailedDescription: String {
        switch retentionPercentage {
        case 91...100:
            return "試験でも即答できる状態です。この記憶は長期間保持される可能性が高いです。次回の復習は長めの間隔を空けても大丈夫でしょう。"
        case 81...90:
            return "概念をしっかり把握し、自分の言葉で説明できます。細部に不安はありますが、基本的な理解は定着しています。"
        case 71...80:
            return "主要な部分は説明できますが、一部詳細が曖昧です。より定着させるには、アクティブリコールを続けることが効果的です。"
        case 61...70:
            return "要点は覚えていますが、説明するとき少し詰まることがあります。復習間隔を少し短くすると効果的です。"
        case 51...60:
            return "基本的な概念は思い出せますが、詳細を思い出すのに時間がかかります。より頻繁な復習が必要です。"
        case 41...50:
            return "断片的に覚えていますが、全体像が不明確です。短い間隔での復習と、関連付けを強化する学習が有効です。"
        case 31...40:
            return "うっすらと覚えていますが、思い出すのに大きなヒントが必要です。基礎から再確認することをお勧めします。"
        case 21...30:
            return "ほとんど忘れており、わずかな記憶の断片しか残っていません。より基本的な部分から学び直す必要があります。"
        case 1...20:
            return "ほぼ完全に忘れています。学習したことを認識できる程度です。もう一度基礎から学び直しましょう。"
        default:
            return "全く覚えていません。まったく新しい情報のように感じるでしょう。初めから学習し直す必要があります。"
        }
    }
}

// プレビュー
struct RetentionStatusCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                RetentionStatusCard(retentionPercentage: 95)
                RetentionStatusCard(retentionPercentage: 85)
                RetentionStatusCard(retentionPercentage: 70)
                RetentionStatusCard(retentionPercentage: 55)
                RetentionStatusCard(retentionPercentage: 40)
                RetentionStatusCard(retentionPercentage: 25)
                RetentionStatusCard(retentionPercentage: 10)
                RetentionStatusCard(retentionPercentage: 0)
            }
            .padding()
        }
    }
}
