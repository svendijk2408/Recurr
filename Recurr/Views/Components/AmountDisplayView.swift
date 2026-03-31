import SwiftUI

struct AmountDisplayView: View {
    let amount: Decimal
    let isIncome: Bool
    let showSign: Bool
    let size: AmountSize

    enum AmountSize {
        case small
        case medium
        case large
        case xlarge

        var font: Font {
            switch self {
            case .small: return .subheadline
            case .medium: return .title3
            case .large: return .title2
            case .xlarge: return .largeTitle
            }
        }

        var fontWeight: Font.Weight {
            switch self {
            case .small: return .medium
            case .medium: return .semibold
            case .large: return .bold
            case .xlarge: return .bold
            }
        }
    }

    init(
        amount: Decimal,
        isIncome: Bool = false,
        showSign: Bool = false,
        size: AmountSize = .medium
    ) {
        self.amount = amount
        self.isIncome = isIncome
        self.showSign = showSign
        self.size = size
    }

    private var displayColor: Color {
        if showSign {
            return amount >= 0 ? AppColors.income : AppColors.expense
        }
        return isIncome ? AppColors.income : AppColors.expense
    }

    private var formattedAmount: String {
        let absAmount = abs(amount.doubleValue)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = AppDefaults.currency
        formatter.locale = Locale(identifier: "nl_NL")

        if size == .small {
            formatter.maximumFractionDigits = absAmount >= 100 ? 0 : 2
        }

        let formatted = formatter.string(from: NSDecimalNumber(decimal: Decimal(absAmount))) ?? "€0,00"

        if showSign && amount != 0 {
            let sign = amount > 0 ? "+" : "-"
            // Remove the currency symbol, add sign, then add currency back
            let withoutSign = formatted.replacingOccurrences(of: "-", with: "")
            return sign + withoutSign.trimmingCharacters(in: .whitespaces)
        }

        return formatted
    }

    var body: some View {
        Text(formattedAmount)
            .font(size.font)
            .fontWeight(size.fontWeight)
            .foregroundStyle(displayColor)
            .monospacedDigit()
    }
}

// MARK: - Balance Display

struct BalanceDisplayView: View {
    let balance: Decimal
    let size: AmountDisplayView.AmountSize

    init(balance: Decimal, size: AmountDisplayView.AmountSize = .large) {
        self.balance = balance
        self.size = size
    }

    var body: some View {
        AmountDisplayView(
            amount: balance,
            isIncome: balance >= 0,
            showSign: true,
            size: size
        )
    }
}

// MARK: - Cost Breakdown View

struct CostBreakdownView: View {
    let breakdown: CostCalculator.CostBreakdown
    let isIncome: Bool

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            breakdownRow(label: AppStrings.perDay, amount: breakdown.perDay)
            breakdownRow(label: AppStrings.perWeek, amount: breakdown.perWeek)
            breakdownRow(label: AppStrings.perMonth, amount: breakdown.perMonth)
            breakdownRow(label: AppStrings.perYear, amount: breakdown.perYear)
        }
    }

    private func breakdownRow(label: String, amount: Decimal) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            AmountDisplayView(
                amount: amount,
                isIncome: isIncome,
                size: .small
            )
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: AppSpacing.lg) {
        // Different sizes
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Sizes").font(.headline)
            AmountDisplayView(amount: 9.99, isIncome: false, size: .small)
            AmountDisplayView(amount: 29.99, isIncome: false, size: .medium)
            AmountDisplayView(amount: 99.99, isIncome: false, size: .large)
            AmountDisplayView(amount: 299.99, isIncome: false, size: .xlarge)
        }

        Divider()

        // Income vs expense
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Income vs Expense").font(.headline)
            AmountDisplayView(amount: 1500, isIncome: true, size: .large)
            AmountDisplayView(amount: 500, isIncome: false, size: .large)
        }

        Divider()

        // Balance with sign
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Balance").font(.headline)
            BalanceDisplayView(balance: 1000.50)
            BalanceDisplayView(balance: -250.00)
        }
    }
    .padding()
}
