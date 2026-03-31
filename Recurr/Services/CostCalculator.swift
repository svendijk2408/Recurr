import Foundation

struct CostCalculator {
    // Average days per month (365.25 / 12)
    private static let daysPerMonth: Decimal = Decimal(string: "30.4375")!
    // Days per year (accounting for leap years)
    private static let daysPerYear: Decimal = Decimal(string: "365.25")!
    private static let daysPerWeek: Decimal = 7

    // MARK: - Daily Rate Calculation

    /// Calculate the daily rate for a subscription
    static func calculateDailyRate(for subscription: Subscription) -> Decimal {
        calculateDailyRate(
            amount: subscription.amount,
            frequencyType: subscription.frequencyType,
            interval: subscription.frequencyInterval,
            customUnit: subscription.customFrequencyUnit
        )
    }

    /// Calculate the daily rate from amount and frequency
    static func calculateDailyRate(
        amount: Decimal,
        frequencyType: FrequencyType,
        interval: Int = 1,
        customUnit: CustomFrequencyUnit? = nil
    ) -> Decimal {
        let periodDays = calculatePeriodDays(
            frequencyType: frequencyType,
            interval: interval,
            customUnit: customUnit
        )

        guard periodDays > 0 else { return 0 }
        return amount / periodDays
    }

    /// Calculate the number of days in one payment period
    private static func calculatePeriodDays(
        frequencyType: FrequencyType,
        interval: Int,
        customUnit: CustomFrequencyUnit?
    ) -> Decimal {
        let intervalDecimal = Decimal(interval)

        switch frequencyType {
        case .daily:
            return 1
        case .weekly:
            return daysPerWeek
        case .biweekly:
            return daysPerWeek * 2
        case .monthly:
            return daysPerMonth
        case .quarterly:
            return daysPerMonth * 3
        case .yearly:
            return daysPerYear
        case .custom:
            guard let unit = customUnit else { return daysPerMonth }
            return unit.baseDays * intervalDecimal
        }
    }

    // MARK: - Period Cost Calculations

    /// Calculate cost per day
    static func perDay(for subscription: Subscription) -> Decimal {
        calculateDailyRate(for: subscription)
    }

    /// Calculate cost per week
    static func perWeek(for subscription: Subscription) -> Decimal {
        calculateDailyRate(for: subscription) * daysPerWeek
    }

    /// Calculate cost per month
    static func perMonth(for subscription: Subscription) -> Decimal {
        calculateDailyRate(for: subscription) * daysPerMonth
    }

    /// Calculate cost per year
    static func perYear(for subscription: Subscription) -> Decimal {
        calculateDailyRate(for: subscription) * daysPerYear
    }

    // MARK: - Cost Breakdown

    struct CostBreakdown {
        let perDay: Decimal
        let perWeek: Decimal
        let perMonth: Decimal
        let perYear: Decimal

        var formattedPerDay: String { perDay.currencyFormatted }
        var formattedPerWeek: String { perWeek.currencyFormatted }
        var formattedPerMonth: String { perMonth.currencyFormatted }
        var formattedPerYear: String { perYear.currencyFormatted }
    }

    /// Get complete cost breakdown for a subscription
    static func breakdown(for subscription: Subscription) -> CostBreakdown {
        let daily = calculateDailyRate(for: subscription)
        return CostBreakdown(
            perDay: daily,
            perWeek: daily * daysPerWeek,
            perMonth: daily * daysPerMonth,
            perYear: daily * daysPerYear
        )
    }

    // MARK: - Totals Calculation

    /// Calculate total monthly cost/income for multiple subscriptions
    static func totalMonthly(for subscriptions: [Subscription], isIncome: Bool) -> Decimal {
        subscriptions
            .filter { $0.isActive && $0.isIncome == isIncome }
            .reduce(Decimal(0)) { total, subscription in
                total + perMonth(for: subscription)
            }
    }

    /// Calculate total yearly cost/income for multiple subscriptions
    static func totalYearly(for subscriptions: [Subscription], isIncome: Bool) -> Decimal {
        subscriptions
            .filter { $0.isActive && $0.isIncome == isIncome }
            .reduce(Decimal(0)) { total, subscription in
                total + perYear(for: subscription)
            }
    }

    /// Calculate monthly balance (income - expenses)
    static func monthlyBalance(for subscriptions: [Subscription]) -> Decimal {
        let income = totalMonthly(for: subscriptions, isIncome: true)
        let expenses = totalMonthly(for: subscriptions, isIncome: false)
        return income - expenses
    }

    /// Calculate yearly balance (income - expenses)
    static func yearlyBalance(for subscriptions: [Subscription]) -> Decimal {
        let income = totalYearly(for: subscriptions, isIncome: true)
        let expenses = totalYearly(for: subscriptions, isIncome: false)
        return income - expenses
    }

    // MARK: - Upcoming Payments

    /// Get subscriptions with upcoming payments within a number of days
    static func upcomingPayments(
        from subscriptions: [Subscription],
        withinDays days: Int = 30
    ) -> [Subscription] {
        let today = Date().startOfDay
        let endDate = Calendar.current.date(byAdding: .day, value: days, to: today) ?? today

        return subscriptions
            .filter { $0.isActive }
            .filter { subscription in
                let nextPayment = subscription.calculateNextPaymentDate(from: today)
                return nextPayment >= today && nextPayment <= endDate
            }
            .sorted { $0.calculateNextPaymentDate() < $1.calculateNextPaymentDate() }
    }
}
