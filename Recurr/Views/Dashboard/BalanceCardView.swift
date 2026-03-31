import SwiftUI

struct BalanceCardView: View {
    let monthlyIncome: Decimal
    let monthlyExpenses: Decimal

    var balance: Decimal {
        monthlyIncome - monthlyExpenses
    }

    var body: some View {
        LiquidGlassCard(accentColor: balance >= 0 ? AppColors.income : AppColors.expense) {
            VStack(spacing: AppSpacing.lg) {
                // Balance header
                VStack(spacing: AppSpacing.xs) {
                    Text(AppStrings.balance)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    BalanceDisplayView(balance: balance, size: .xlarge)

                    Text("per maand")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Income vs Expenses breakdown
                HStack(spacing: AppSpacing.xl) {
                    VStack(spacing: AppSpacing.xxs) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppColors.income)

                        AmountDisplayView(
                            amount: monthlyIncome,
                            isIncome: true,
                            size: .medium
                        )

                        Text("Inkomsten")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Divider
                    Rectangle()
                        .fill(.secondary.opacity(0.3))
                        .frame(width: 1, height: 50)

                    VStack(spacing: AppSpacing.xxs) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppColors.expense)

                        AmountDisplayView(
                            amount: monthlyExpenses,
                            isIncome: false,
                            size: .medium
                        )

                        Text("Uitgaven")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Compact Balance Card

struct CompactBalanceCard: View {
    let monthlyIncome: Decimal
    let monthlyExpenses: Decimal

    var balance: Decimal {
        monthlyIncome - monthlyExpenses
    }

    var body: some View {
        LiquidGlassCard(accentColor: balance >= 0 ? AppColors.income : AppColors.expense) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("Maandelijkse balans")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    BalanceDisplayView(balance: balance, size: .large)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: AppSpacing.xxs) {
                    HStack(spacing: AppSpacing.xxs) {
                        Image(systemName: "arrow.down")
                            .font(.caption)
                            .foregroundStyle(AppColors.income)
                        Text(monthlyIncome.shortCurrencyFormatted)
                            .font(.caption)
                            .foregroundStyle(AppColors.income)
                    }

                    HStack(spacing: AppSpacing.xxs) {
                        Image(systemName: "arrow.up")
                            .font(.caption)
                            .foregroundStyle(AppColors.expense)
                        Text(monthlyExpenses.shortCurrencyFormatted)
                            .font(.caption)
                            .foregroundStyle(AppColors.expense)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: AppSpacing.lg) {
        BalanceCardView(
            monthlyIncome: 3500,
            monthlyExpenses: 1850.50
        )

        CompactBalanceCard(
            monthlyIncome: 3500,
            monthlyExpenses: 1850.50
        )

        BalanceCardView(
            monthlyIncome: 1500,
            monthlyExpenses: 2100.75
        )
    }
    .padding()
}
