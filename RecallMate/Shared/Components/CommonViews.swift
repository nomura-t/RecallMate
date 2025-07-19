import SwiftUI

// MARK: - Common Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    let isEnabled: Bool
    
    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: UIConstants.buttonHeight)
            .background(isEnabled ? AppColors.primary : AppColors.secondary)
            .cornerRadius(UIConstants.mediumCornerRadius)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(AnimationConstants.quickAnimation, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(AppColors.primary)
            .frame(maxWidth: .infinity)
            .frame(height: UIConstants.buttonHeight)
            .background(AppColors.backgroundSecondary)
            .overlay(
                RoundedRectangle(cornerRadius: UIConstants.mediumCornerRadius)
                    .stroke(AppColors.divider, lineWidth: 1)
            )
            .cornerRadius(UIConstants.mediumCornerRadius)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(AnimationConstants.quickAnimation, value: configuration.isPressed)
    }
}

// MARK: - Common Card View

struct CardView<Content: View>: View {
    let content: Content
    let padding: CGFloat
    let cornerRadius: CGFloat
    
    init(
        padding: CGFloat = UIConstants.contentPadding,
        cornerRadius: CGFloat = UIConstants.mediumCornerRadius,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(AppColors.cardBackground)
            .cornerRadius(cornerRadius)
            .shadow(radius: SystemConstants.cardElevation)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let subtitle: String?
    
    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.smallSpacing) {
            Text(title)
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Common Empty State View

struct CommonEmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        description: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: UIConstants.mediumSpacing) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(AppColors.textTertiary)
            
            VStack(spacing: UIConstants.smallSpacing) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, UIConstants.extraLargeSpacing)
            }
        }
        .padding(UIConstants.extraLargeSpacing)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Avatar View

struct AvatarView: View {
    let imageURL: String?
    let name: String
    let size: CGFloat
    
    init(imageURL: String?, name: String, size: CGFloat = UIConstants.mediumAvatarSize) {
        self.imageURL = imageURL
        self.name = name
        self.size = size
    }
    
    var body: some View {
        Group {
            if let imageURL = imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    placeholderView
                }
            } else {
                placeholderView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
    
    private var placeholderView: some View {
        Circle()
            .fill(AppColors.backgroundTertiary)
            .overlay(
                Text(String(name.prefix(1)).uppercased())
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
            )
    }
}

// MARK: - Tag View

struct TagView: View {
    let text: String
    let isRemovable: Bool
    let onRemove: (() -> Void)?
    
    init(_ text: String, isRemovable: Bool = false, onRemove: (() -> Void)? = nil) {
        self.text = text
        self.isRemovable = isRemovable
        self.onRemove = onRemove
    }
    
    var body: some View {
        HStack(spacing: UIConstants.smallSpacing) {
            Text(text)
                .font(.caption)
                .foregroundColor(AppColors.primary)
            
            if isRemovable {
                Button(action: onRemove ?? {}) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(AppColors.primary)
                }
            }
        }
        .padding(.horizontal, UIConstants.smallSpacing)
        .padding(.vertical, 4)
        .background(AppColors.primary.opacity(0.1))
        .cornerRadius(UIConstants.smallCornerRadius)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let text: String
    let color: Color
    
    init(_ text: String, color: Color = AppColors.success) {
        self.text = text
        self.color = color
    }
    
    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, UIConstants.smallSpacing)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(UIConstants.smallCornerRadius)
    }
}

// MARK: - View Extensions

extension View {
    func primaryButton(isEnabled: Bool = true) -> some View {
        self.buttonStyle(PrimaryButtonStyle(isEnabled: isEnabled))
    }
    
    func secondaryButton() -> some View {
        self.buttonStyle(SecondaryButtonStyle())
    }
}

// MARK: - Card Modifier

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(UIConstants.contentPadding)
            .background(AppColors.cardBackground)
            .cornerRadius(UIConstants.mediumCornerRadius)
            .shadow(radius: SystemConstants.cardElevation)
    }
}