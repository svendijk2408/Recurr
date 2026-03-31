import SwiftUI

struct SubscriptionIconView: View {
    let iconName: String?
    let imageData: Data?
    let category: SubscriptionCategory
    let size: IconSize

    enum IconSize {
        case small
        case medium
        case large

        var dimension: CGFloat {
            switch self {
            case .small: return AppSpacing.smallIconSize
            case .medium: return AppSpacing.iconSize
            case .large: return 64
            }
        }

        var iconFont: Font {
            switch self {
            case .small: return .body
            case .medium: return .title3
            case .large: return .title
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 12
            case .large: return 16
            }
        }
    }

    init(
        iconName: String? = nil,
        imageData: Data? = nil,
        category: SubscriptionCategory,
        size: IconSize = .medium
    ) {
        self.iconName = iconName
        self.imageData = imageData
        self.category = category
        self.size = size
    }

    init(subscription: Subscription, size: IconSize = .medium) {
        self.iconName = subscription.iconName
        self.imageData = subscription.customImageData
        self.category = subscription.category
        self.size = size
    }

    var body: some View {
        Group {
            if let imageData = imageData,
               let image = ImageStorageService.image(from: imageData) {
                // Custom image
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if let iconName = iconName, !iconName.isEmpty {
                // Custom SF Symbol
                Image(systemName: iconName)
                    .font(size.iconFont)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(category.color.gradient)
            } else {
                // Category default icon
                Image(systemName: category.iconName)
                    .font(size.iconFont)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(category.color.gradient)
            }
        }
        .frame(width: size.dimension, height: size.dimension)
        .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: AppSpacing.lg) {
        // Different sizes with category icon
        HStack(spacing: AppSpacing.md) {
            SubscriptionIconView(category: .streaming, size: .small)
            SubscriptionIconView(category: .streaming, size: .medium)
            SubscriptionIconView(category: .streaming, size: .large)
        }

        // Different categories
        HStack(spacing: AppSpacing.md) {
            SubscriptionIconView(category: .music, size: .medium)
            SubscriptionIconView(category: .gaming, size: .medium)
            SubscriptionIconView(category: .software, size: .medium)
            SubscriptionIconView(category: .salary, size: .medium)
        }

        // Custom icon
        HStack(spacing: AppSpacing.md) {
            SubscriptionIconView(iconName: "star.fill", category: .other, size: .medium)
            SubscriptionIconView(iconName: "heart.fill", category: .health, size: .medium)
        }
    }
    .padding()
}
