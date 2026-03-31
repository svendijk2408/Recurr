import SwiftUI

// MARK: - Color Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Date Extensions

extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }

    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }

    var isThisMonth: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var relativeDescription: String {
        if isToday {
            return "Vandaag"
        } else if isTomorrow {
            return "Morgen"
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "nl_NL")

            if isThisWeek {
                formatter.dateFormat = "EEEE"
            } else if isThisMonth {
                formatter.dateFormat = "d MMMM"
            } else {
                formatter.dateFormat = "d MMM yyyy"
            }
            return formatter.string(from: self)
        }
    }

    var shortDescription: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: self)
    }

    var fullDescription: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.dateStyle = .long
        return formatter.string(from: self)
    }

    func daysUntil() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: self)
        return calendar.dateComponents([.day], from: today, to: target).day ?? 0
    }
}

// MARK: - Decimal Extensions

extension Decimal {
    var currencyFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = AppDefaults.currency
        formatter.locale = Locale(identifier: "nl_NL")
        return formatter.string(from: self as NSDecimalNumber) ?? "\(AppDefaults.currencySymbol)0,00"
    }

    var shortCurrencyFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = AppDefaults.currency
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.maximumFractionDigits = 0

        let doubleValue = NSDecimalNumber(decimal: self).doubleValue
        if abs(doubleValue) >= 1000 {
            formatter.maximumFractionDigits = 0
        } else {
            formatter.maximumFractionDigits = 2
        }

        return formatter.string(from: self as NSDecimalNumber) ?? "\(AppDefaults.currencySymbol)0"
    }

    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }
}

// MARK: - Double Extensions

extension Double {
    var asDecimal: Decimal {
        Decimal(self)
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle(padding: CGFloat = AppSpacing.md) -> some View {
        self
            .padding(padding)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.5), AppColors.primary.opacity(0.1), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }

    func bounceAnimation() -> some View {
        self.animation(.spring(response: 0.4, dampingFraction: 0.6), value: UUID())
    }
}

// MARK: - String Extensions

extension String {
    var nilIfEmpty: String? {
        self.isEmpty ? nil : self
    }
}
