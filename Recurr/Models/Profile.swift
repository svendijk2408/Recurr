import Foundation
import SwiftData
import SwiftUI

@Model
final class Profile {
    var id: UUID = UUID()
    var name: String = ""
    var iconName: String = "person.fill"
    var colorHex: String = "6366F1"
    var isBusiness: Bool = false
    var isDefault: Bool = false
    var createdAt: Date = Date()

    var color: Color {
        Color(hex: colorHex)
    }

    init(
        name: String = "",
        iconName: String = "person.fill",
        colorHex: String = "6366F1",
        isBusiness: Bool = false,
        isDefault: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.isBusiness = isBusiness
        self.isDefault = isDefault
        self.createdAt = Date()
    }
}

// MARK: - VAT Rates (Dutch BTW)

enum VATRate: Int, CaseIterable, Identifiable {
    case zero = 0
    case low = 9
    case high = 21

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .zero: return "0% (vrijgesteld)"
        case .low: return "9% (laag tarief)"
        case .high: return "21% (hoog tarief)"
        }
    }

    var shortName: String {
        "\(rawValue)%"
    }

    var multiplier: Decimal {
        1 + (Decimal(rawValue) / 100)
    }
}
