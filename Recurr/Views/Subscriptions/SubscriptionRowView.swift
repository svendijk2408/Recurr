import SwiftUI

struct SubscriptionRowView: View {
    let subscription: Subscription

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            // Icon
            SubscriptionIconView(subscription: subscription, size: .medium)

            // Info
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(subscription.name)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: AppSpacing.xs) {
                    CategoryBadge(category: subscription.category)
                    FrequencyDisplayView(subscription: subscription)
                }
            }

            Spacer()

            // Amount
            VStack(alignment: .trailing, spacing: AppSpacing.xxs) {
                AmountDisplayView(
                    amount: subscription.amount,
                    isIncome: subscription.isIncome,
                    size: .medium
                )

                Text(subscription.nextPaymentDate.relativeDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, AppSpacing.xs)
        .opacity(subscription.isActive ? 1 : 0.5)
    }
}

// MARK: - Compact Row View

struct SubscriptionCompactRowView: View {
    let subscription: Subscription

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            SubscriptionIconView(subscription: subscription, size: .small)

            Text(subscription.name)
                .font(.subheadline)
                .lineLimit(1)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                AmountDisplayView(
                    amount: subscription.amount,
                    isIncome: subscription.isIncome,
                    size: .small
                )

                Text(subscription.nextPaymentDate.shortDescription)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    List {
        SubscriptionRowView(
            subscription: Subscription(
                name: "Netflix",
                amount: 15.99,
                category: .streaming,
                frequencyType: .monthly
            )
        )

        SubscriptionRowView(
            subscription: Subscription(
                name: "Salaris",
                amount: 3500,
                isIncome: true,
                category: .salary,
                frequencyType: .monthly
            )
        )

        Section("Compact") {
            SubscriptionCompactRowView(
                subscription: Subscription(
                    name: "Spotify",
                    amount: 9.99,
                    category: .music,
                    frequencyType: .monthly
                )
            )
        }
    }
}
