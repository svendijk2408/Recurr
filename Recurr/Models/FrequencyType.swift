import Foundation

enum FrequencyType: String, Codable, CaseIterable, Identifiable {
    case daily = "daily"
    case weekly = "weekly"
    case biweekly = "biweekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case yearly = "yearly"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily: return "Dagelijks"
        case .weekly: return "Wekelijks"
        case .biweekly: return "Tweewekelijks"
        case .monthly: return "Maandelijks"
        case .quarterly: return "Per kwartaal"
        case .yearly: return "Jaarlijks"
        case .custom: return "Aangepast"
        }
    }

    var shortName: String {
        switch self {
        case .daily: return "dag"
        case .weekly: return "week"
        case .biweekly: return "2 weken"
        case .monthly: return "maand"
        case .quarterly: return "kwartaal"
        case .yearly: return "jaar"
        case .custom: return "aangepast"
        }
    }

    /// Number of days in one period for this frequency type
    var baseDays: Decimal {
        switch self {
        case .daily: return 1
        case .weekly: return 7
        case .biweekly: return 14
        case .monthly: return Decimal(string: "30.4375")! // 365.25 / 12
        case .quarterly: return Decimal(string: "91.3125")! // 365.25 / 4
        case .yearly: return Decimal(string: "365.25")!
        case .custom: return 1 // Will be multiplied by interval
        }
    }

    /// Whether this frequency type supports custom intervals
    var supportsInterval: Bool {
        self == .custom
    }
}

enum CustomFrequencyUnit: String, Codable, CaseIterable, Identifiable {
    case days = "days"
    case weeks = "weeks"
    case months = "months"
    case years = "years"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .days: return "dagen"
        case .weeks: return "weken"
        case .months: return "maanden"
        case .years: return "jaren"
        }
    }

    var singularName: String {
        switch self {
        case .days: return "dag"
        case .weeks: return "week"
        case .months: return "maand"
        case .years: return "jaar"
        }
    }

    var baseDays: Decimal {
        switch self {
        case .days: return 1
        case .weeks: return 7
        case .months: return Decimal(string: "30.4375")!
        case .years: return Decimal(string: "365.25")!
        }
    }
}
