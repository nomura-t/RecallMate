import SwiftUI

struct MemoryRetentionProgressBar: View {
    let retentionPercentage: Int
    let showLabel: Bool
    
    init(retentionPercentage: Int, showLabel: Bool = true) {
        self.retentionPercentage = max(0, min(100, retentionPercentage))
        self.showLabel = showLabel
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // プログレスバー
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景バー
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                    
                    // 進捗バー
                    RoundedRectangle(cornerRadius: 8)
                        .fill(retentionColor)
                        .frame(width: CGFloat(retentionPercentage) / 100.0 * geometry.size.width, height: 12)
                }
            }
            .frame(height: 12)
            
            // ラベル表示（オプション）
            if showLabel {
                HStack {
                    Text(retentionDescription)
                        .font(.caption)
                        .foregroundColor(retentionColor)
                    
                    Spacer()
                    
                    Text("\(retentionPercentage)%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(retentionColor)
                        .frame(width: 50, alignment: .trailing) // 幅を固定し、右寄せにする
                }
            }
        }
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
}

// 使用例
struct MemoryRetentionProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 24) {
            MemoryRetentionProgressBar(retentionPercentage: 100)
            MemoryRetentionProgressBar(retentionPercentage: 85)
            MemoryRetentionProgressBar(retentionPercentage: 70)
            MemoryRetentionProgressBar(retentionPercentage: 55)
            MemoryRetentionProgressBar(retentionPercentage: 40)
            MemoryRetentionProgressBar(retentionPercentage: 25)
            MemoryRetentionProgressBar(retentionPercentage: 10)
            MemoryRetentionProgressBar(retentionPercentage: 0)
        }
        .padding()
    }
}
