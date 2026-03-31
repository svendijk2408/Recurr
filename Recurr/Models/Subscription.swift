import Foundation
import SwiftData

@Model
final class Subscription {
    // All properties need default values for CloudKit compatibility
    var id: UUID = UUID()
    var name: String = ""
    var amount: Decimal = 0
    var currency: String = "EUR"
    var isIncome: Bool = false

    // Store raw values for enums
    var categoryRaw: String = "other"
    var frequencyTypeRaw: String = "monthly"
    var customFrequencyUnitRaw: String?

    var frequencyInterval: Int = 1
    var notes: String?

    var startDate: Date = Date()
    var nextPaymentDate: Date = Date()

    var iconName: String?
    @Attribute(.externalStorage)
    var customImageData: Data?

    var isActive: Bool = true
    var createdAt: Date = Date()

    // MARK: - Trial Period
    var hasTrial: Bool = false
    var trialEndDate: Date?
    var trialCancelled: Bool = false
    var trialReminderDays: Int?  // Days before trial ends to remind

    // MARK: - Notifications
    var paymentReminderHours: Int?  // Hours before payment to remind

    // MARK: - Account/Card
    var accountId: UUID?

    // MARK: - Tags (stored as comma-separated UUIDs)
    var tagIds: String = ""

    // MARK: - Importance Rating (1-5, only for expenses)
    var importanceRating: Int?

    // MARK: - Profile
    var profileId: UUID?

    // MARK: - VAT/BTW (only for business profiles)
    var vatPercentage: Int?  // 0, 9, or 21

    // MARK: - Computed Properties

    var category: SubscriptionCategory {
        get { SubscriptionCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var frequencyType: FrequencyType {
        get { FrequencyType(rawValue: frequencyTypeRaw) ?? .monthly }
        set { frequencyTypeRaw = newValue.rawValue }
    }

    var customFrequencyUnit: CustomFrequencyUnit? {
        get {
            guard let raw = customFrequencyUnitRaw else { return nil }
            return CustomFrequencyUnit(rawValue: raw)
        }
        set { customFrequencyUnitRaw = newValue?.rawValue }
    }

    var frequencyDisplayName: String {
        if frequencyType == .custom, let unit = customFrequencyUnit {
            let unitName = frequencyInterval == 1 ? unit.singularName : unit.displayName
            return "Elke \(frequencyInterval) \(unitName)"
        }
        return frequencyType.displayName
    }

    /// Check if currently in trial period
    var isInTrial: Bool {
        guard hasTrial, let endDate = trialEndDate else { return false }
        return !trialCancelled && Date() < endDate
    }

    /// Check if trial has expired (not cancelled, but past end date)
    var trialExpired: Bool {
        guard hasTrial, let endDate = trialEndDate else { return false }
        return !trialCancelled && Date() >= endDate
    }

    /// Days remaining in trial
    var trialDaysRemaining: Int? {
        guard isInTrial, let endDate = trialEndDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: endDate).day
    }

    /// Tag UUIDs as array
    var tagUUIDs: [UUID] {
        get {
            guard !tagIds.isEmpty else { return [] }
            return tagIds.split(separator: ",").compactMap { UUID(uuidString: String($0)) }
        }
        set {
            tagIds = newValue.map { $0.uuidString }.joined(separator: ",")
        }
    }

    /// VAT rate object
    var vatRate: VATRate? {
        get {
            guard let percentage = vatPercentage else { return nil }
            return VATRate(rawValue: percentage)
        }
        set {
            vatPercentage = newValue?.rawValue
        }
    }

    /// Amount excluding VAT (when amount is including VAT)
    var amountExcludingVAT: Decimal {
        guard let rate = vatRate, rate != .zero else { return amount }
        return amount / rate.multiplier
    }

    /// Amount including VAT (when amount is excluding VAT)
    var amountIncludingVAT: Decimal {
        guard let rate = vatRate, rate != .zero else { return amount }
        return amount * rate.multiplier
    }

    /// VAT amount
    var vatAmount: Decimal {
        guard let rate = vatRate, rate != .zero else { return 0 }
        // Assuming amount is including VAT
        return amount - amountExcludingVAT
    }

    // MARK: - Initialization

    init(
        name: String = "",
        amount: Decimal = 0,
        currency: String = AppDefaults.currency,
        isIncome: Bool = false,
        category: SubscriptionCategory = .other,
        frequencyType: FrequencyType = .monthly,
        frequencyInterval: Int = 1,
        customFrequencyUnit: CustomFrequencyUnit? = nil,
        startDate: Date = Date(),
        nextPaymentDate: Date? = nil,
        iconName: String? = nil,
        customImageData: Data? = nil,
        notes: String? = nil,
        isActive: Bool = true,
        hasTrial: Bool = false,
        trialEndDate: Date? = nil,
        trialReminderDays: Int? = nil,
        paymentReminderHours: Int? = nil,
        accountId: UUID? = nil,
        tagUUIDs: [UUID] = [],
        importanceRating: Int? = nil,
        profileId: UUID? = nil,
        vatPercentage: Int? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.currency = currency
        self.isIncome = isIncome
        self.categoryRaw = category.rawValue
        self.frequencyTypeRaw = frequencyType.rawValue
        self.frequencyInterval = frequencyInterval
        self.customFrequencyUnitRaw = customFrequencyUnit?.rawValue
        self.startDate = startDate
        self.nextPaymentDate = nextPaymentDate ?? startDate
        self.iconName = iconName
        self.customImageData = customImageData
        self.notes = notes
        self.isActive = isActive
        self.createdAt = Date()
        self.hasTrial = hasTrial
        self.trialEndDate = trialEndDate
        self.trialCancelled = false
        self.trialReminderDays = trialReminderDays
        self.paymentReminderHours = paymentReminderHours
        self.accountId = accountId
        self.tagIds = tagUUIDs.map { $0.uuidString }.joined(separator: ",")
        self.importanceRating = importanceRating
        self.profileId = profileId
        self.vatPercentage = vatPercentage
    }

    // MARK: - Methods

    /// Calculate the next payment date based on the frequency
    func calculateNextPaymentDate(from date: Date = Date()) -> Date {
        let calendar = Calendar.current
        var nextDate = nextPaymentDate

        // If nextPaymentDate is in the past, calculate the next one
        while nextDate < date {
            switch frequencyType {
            case .daily:
                nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate) ?? nextDate
            case .weekly:
                nextDate = calendar.date(byAdding: .weekOfYear, value: 1, to: nextDate) ?? nextDate
            case .biweekly:
                nextDate = calendar.date(byAdding: .weekOfYear, value: 2, to: nextDate) ?? nextDate
            case .monthly:
                nextDate = calendar.date(byAdding: .month, value: 1, to: nextDate) ?? nextDate
            case .quarterly:
                nextDate = calendar.date(byAdding: .month, value: 3, to: nextDate) ?? nextDate
            case .yearly:
                nextDate = calendar.date(byAdding: .year, value: 1, to: nextDate) ?? nextDate
            case .custom:
                if let unit = customFrequencyUnit {
                    switch unit {
                    case .days:
                        nextDate = calendar.date(byAdding: .day, value: frequencyInterval, to: nextDate) ?? nextDate
                    case .weeks:
                        nextDate = calendar.date(byAdding: .weekOfYear, value: frequencyInterval, to: nextDate) ?? nextDate
                    case .months:
                        nextDate = calendar.date(byAdding: .month, value: frequencyInterval, to: nextDate) ?? nextDate
                    case .years:
                        nextDate = calendar.date(byAdding: .year, value: frequencyInterval, to: nextDate) ?? nextDate
                    }
                } else {
                    nextDate = calendar.date(byAdding: .month, value: frequencyInterval, to: nextDate) ?? nextDate
                }
            }
        }

        return nextDate
    }

    /// Update the next payment date to the next occurrence
    func advanceToNextPayment() {
        nextPaymentDate = calculateNextPaymentDate(from: Date())
    }

    /// Cancel trial period
    func cancelTrial() {
        trialCancelled = true
        isActive = false
    }

    /// Convert trial to active subscription (trial ended without cancellation)
    func convertTrialToSubscription() {
        guard trialExpired else { return }
        hasTrial = false
        trialEndDate = nil
        // nextPaymentDate should be set to when first payment is due
    }
}

// MARK: - Importance Rating

enum ImportanceRating: Int, CaseIterable, Identifiable {
    case veryLow = 1
    case low = 2
    case medium = 3
    case high = 4
    case essential = 5

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .veryLow: return "Niet belangrijk"
        case .low: return "Weinig belangrijk"
        case .medium: return "Gemiddeld"
        case .high: return "Belangrijk"
        case .essential: return "Essentieel"
        }
    }

    var iconName: String {
        switch self {
        case .veryLow: return "star"
        case .low: return "star.leadinghalf.filled"
        case .medium: return "star.fill"
        case .high: return "star.fill"
        case .essential: return "star.fill"
        }
    }

    var starCount: Int {
        rawValue
    }
}
