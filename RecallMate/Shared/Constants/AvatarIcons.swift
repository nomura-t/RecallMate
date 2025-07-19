import SwiftUI

// MARK: - Avatar Icon System
// 軽量なアイコンシステム - 画像ファイルを使わずにSFSymbolsとカラーの組み合わせで表現

struct AvatarIcon: Identifiable, Codable, Equatable {
    let id: String
    let symbolName: String
    let backgroundColor: Color
    let foregroundColor: Color
    let displayName: String
    
    init(id: String, symbolName: String, backgroundColor: Color, foregroundColor: Color = .white, displayName: String) {
        self.id = id
        self.symbolName = symbolName
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.displayName = displayName
    }
}

// MARK: - Color Extensions for Codable
extension Color: Codable {
    enum CodingKeys: String, CodingKey {
        case red, green, blue, alpha
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let red = try container.decode(Double.self, forKey: .red)
        let green = try container.decode(Double.self, forKey: .green)
        let blue = try container.decode(Double.self, forKey: .blue)
        let alpha = try container.decode(Double.self, forKey: .alpha)
        
        self.init(red: red, green: green, blue: blue, opacity: alpha)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        guard let components = cgColor?.components else {
            throw EncodingError.invalidValue(self, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unable to encode color"))
        }
        
        try container.encode(components[0], forKey: .red)
        try container.encode(components[1], forKey: .green)
        try container.encode(components[2], forKey: .blue)
        try container.encode(components.count > 3 ? components[3] : 1.0, forKey: .alpha)
    }
}

// MARK: - Available Avatar Icons
struct AvatarIcons {
    static let allIcons: [AvatarIcon] = [
        // 学習関連
        AvatarIcon(id: "book", symbolName: "book.fill", backgroundColor: .blue, displayName: "本"),
        AvatarIcon(id: "graduationcap", symbolName: "graduationcap.fill", backgroundColor: .indigo, displayName: "卒業帽"),
        AvatarIcon(id: "brain", symbolName: "brain.head.profile", backgroundColor: .purple, displayName: "脳"),
        AvatarIcon(id: "lightbulb", symbolName: "lightbulb.fill", backgroundColor: .yellow, foregroundColor: .black, displayName: "電球"),
        AvatarIcon(id: "trophy", symbolName: "trophy.fill", backgroundColor: .orange, displayName: "トロフィー"),
        
        // 動物
        AvatarIcon(id: "cat", symbolName: "cat.fill", backgroundColor: .pink, displayName: "猫"),
        AvatarIcon(id: "dog", symbolName: "dog.fill", backgroundColor: .brown, displayName: "犬"),
        AvatarIcon(id: "rabbit", symbolName: "rabbit.fill", backgroundColor: .green, displayName: "うさぎ"),
        AvatarIcon(id: "bird", symbolName: "bird.fill", backgroundColor: .cyan, displayName: "鳥"),
        AvatarIcon(id: "tortoise", symbolName: "tortoise.fill", backgroundColor: .mint, displayName: "亀"),
        
        // 自然
        AvatarIcon(id: "leaf", symbolName: "leaf.fill", backgroundColor: .green, displayName: "葉"),
        AvatarIcon(id: "flame", symbolName: "flame.fill", backgroundColor: .red, displayName: "炎"),
        AvatarIcon(id: "snowflake", symbolName: "snowflake", backgroundColor: .cyan, displayName: "雪"),
        AvatarIcon(id: "sun", symbolName: "sun.max.fill", backgroundColor: .yellow, foregroundColor: .black, displayName: "太陽"),
        AvatarIcon(id: "moon", symbolName: "moon.fill", backgroundColor: .indigo, displayName: "月"),
        
        // 食べ物
        AvatarIcon(id: "apple", symbolName: "apple.logo", backgroundColor: .red, displayName: "リンゴ"),
        AvatarIcon(id: "carrot", symbolName: "carrot.fill", backgroundColor: .orange, displayName: "人参"),
        AvatarIcon(id: "cup", symbolName: "cup.and.saucer.fill", backgroundColor: .brown, displayName: "コーヒー"),
        
        // 職業・趣味
        AvatarIcon(id: "music", symbolName: "music.note", backgroundColor: .purple, displayName: "音楽"),
        AvatarIcon(id: "camera", symbolName: "camera.fill", backgroundColor: .gray, displayName: "カメラ"),
        AvatarIcon(id: "paintbrush", symbolName: "paintbrush.fill", backgroundColor: .pink, displayName: "絵筆"),
        AvatarIcon(id: "gamecontroller", symbolName: "gamecontroller.fill", backgroundColor: .blue, displayName: "ゲーム"),
        AvatarIcon(id: "scissors", symbolName: "scissors", backgroundColor: .mint, displayName: "ハサミ"),
        
        // 抽象・幾何
        AvatarIcon(id: "circle", symbolName: "circle.fill", backgroundColor: .blue, displayName: "円"),
        AvatarIcon(id: "diamond", symbolName: "diamond.fill", backgroundColor: .purple, displayName: "ダイヤ"),
        AvatarIcon(id: "star", symbolName: "star.fill", backgroundColor: .yellow, foregroundColor: .black, displayName: "星"),
        AvatarIcon(id: "heart", symbolName: "heart.fill", backgroundColor: .red, displayName: "ハート"),
        AvatarIcon(id: "bolt", symbolName: "bolt.fill", backgroundColor: .orange, displayName: "稲妻")
    ]
    
    static let defaultIcon = allIcons.first { $0.id == "book" } ?? allIcons[0]
    
    static func icon(for id: String) -> AvatarIcon {
        return allIcons.first { $0.id == id } ?? defaultIcon
    }
}

// MARK: - Avatar Icon View
struct AvatarIconView: View {
    let icon: AvatarIcon
    let size: CGFloat
    
    init(icon: AvatarIcon, size: CGFloat = UIConstants.mediumAvatarSize) {
        self.icon = icon
        self.size = size
    }
    
    var body: some View {
        Circle()
            .fill(icon.backgroundColor)
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: icon.symbolName)
                    .font(.system(size: size * 0.5, weight: .medium))
                    .foregroundColor(icon.foregroundColor)
            )
    }
}

// MARK: - Avatar Icon Selector
struct AvatarIconSelector: View {
    @Binding var selectedIcon: AvatarIcon
    @State private var showingSelector = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.smallSpacing) {
            Text("アイコン")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            
            Button(action: {
                showingSelector = true
            }) {
                HStack {
                    AvatarIconView(icon: selectedIcon, size: 40)
                    
                    VStack(alignment: .leading) {
                        Text(selectedIcon.displayName)
                            .font(.subheadline)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("タップして変更")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(UIConstants.mediumSpacing)
                .background(AppColors.backgroundSecondary)
                .cornerRadius(UIConstants.mediumCornerRadius)
            }
            .sheet(isPresented: $showingSelector) {
                AvatarIconSelectorSheet(selectedIcon: $selectedIcon)
            }
        }
    }
}

// MARK: - Avatar Icon Selector Sheet
struct AvatarIconSelectorSheet: View {
    @Binding var selectedIcon: AvatarIcon
    @Environment(\.dismiss) private var dismiss
    
    let columns = Array(repeating: GridItem(.flexible()), count: 4)
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: UIConstants.mediumSpacing) {
                    ForEach(AvatarIcons.allIcons) { icon in
                        Button(action: {
                            selectedIcon = icon
                            dismiss()
                        }) {
                            VStack(spacing: UIConstants.smallSpacing) {
                                AvatarIconView(icon: icon, size: 50)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedIcon.id == icon.id ? AppColors.primary : Color.clear, lineWidth: 2)
                                    )
                                
                                Text(icon.displayName)
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
            .navigationTitle("アイコンを選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}