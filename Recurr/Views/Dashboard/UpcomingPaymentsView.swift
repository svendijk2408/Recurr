import SwiftUI

struct UpcomingPaymentsView: View {
    let subscriptions: [Subscription]
    let onSelect: (Subscription) -> Void

    private var upcomingPayments: [Subscription] {
        CostCalculator.upcomingPayments(from: subscriptions, withinDays: 14)
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header
            HStack {
                Label(AppStrings.upcomingPayments, systemImage: "calendar.badge.clock")
                    .font(.headline)

                Spacer()

                if !upcomingPayments.isEmpty {
                    Text("\(upcomingPayments.count)")
                        .font(.caption)
                        .padding(.horizontal, AppSpacing.xs)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(AppColors.primary.opacity(0.2))
                        )
                        .foregroundStyle(AppColors.primary)
                }
            }

            if upcomingPayments.isEmpty {
                // Empty state
                LiquidGlassCard {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppColors.income)

                        VStack(alignment: .leading) {
                            Text(AppStrings.noUpcomingPayments)
                                .font(.subheadline)
                            Text("De komende 14 dagen")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                }
            } else {
                // Upcoming payments list
                VStack(spacing: AppSpacing.sm) {
                    ForEach(upcomingPayments) { subscription in
                        UpcomingPaymentRow(subscription: subscription)
                            .onTapGesture {
                                onSelect(subscription)
                            }
                    }
                }
            }
        }
    }
}

// MARK: - Upcoming Payment Row

struct UpcomingPaymentRow: View {
    let subscription: Subscription

    private var daysUntil: Int {
        subscription.calculateNextPaymentDate().daysUntil()
    }

    private var urgencyColor: Color {
        if daysUntil <= 1 {
            return AppColors.expense
        } else if daysUntil <= 3 {
            return .orange
        } else {
            return AppColors.primary
        }
    }

    var body: some View {
        LiquidGlassCard(accentColor: urgencyColor) {
            HStack(spacing: AppSpacing.sm) {
                SubscriptionIconView(subscription: subscription, size: .small)

                VStack(alignment: .leading, spacing: 2) {
                    Text(subscription.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    Text(subscription.calculateNextPaymentDate().relativeDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                AmountDisplayView(
                    amount: subscription.amount,
                    isIncome: subscription.isIncome,
                    size: .small
                )
            }
        }
    }
}

// MARK: - Today's Payments Widget

struct TodaysPaymentsWidget: View {
    let subscriptions: [Subscription]

    private var todaysPayments: [Subscription] {
        subscriptions.filter { subscription in
            subscription.isActive &&
            subscription.calculateNextPaymentDate().isToday
        }
    }

    private var totalToday: Decimal {
        todaysPayments.reduce(Decimal(0)) { total, sub in
            total + (sub.isIncome ? sub.amount : -sub.amount)
        }
    }

    var body: some View {
        if !todaysPayments.isEmpty {
            LiquidGlassCard(accentColor: totalToday >= 0 ? AppColors.income : AppColors.expense) {
                VStack(spacing: AppSpacing.sm) {
                    HStack {
                        Image(systemName: "calendar.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppColors.primary)

                        Text("Vandaag")
                            .font(.headline)

                        Spacer()

                        BalanceDisplayView(balance: totalToday, size: .medium)
                    }

                    Divider()

                    ForEach(todaysPayments) { subscription in
                        HStack {
                            SubscriptionIconView(subscription: subscription, size: .small)

                            Text(subscription.name)
                                .font(.subheadline)
                                .lineLimit(1)

                            Spacer()

                            AmountDisplayView(
                                amount: subscription.amount,
                                isIncome: subscription.isIncome,
                                showSign: true,
                                size: .small
                            )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let subs = [
        Subscription(name: "Netflix", amount: 15.99, category: .streaming),
        Subscription(name: "Spotify", amount: 9.99, category: .music),
        Subscription(name: "Salaris", amount: 3500, isIncome: true, category: .salary)
    ]

    return VStack(spacing: AppSpacing.lg) {
        UpcomingPaymentsView(subscriptions: subs) { _ in }
        TodaysPaymentsWidget(subscriptions: subs)
    }
    .padding()
}
