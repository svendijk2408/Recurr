import SwiftUI

enum AppColors {
    // Primary colors
    static let primary = Color(hex: "6366F1")       // Indigo
    static let secondary = Color(hex: "8B5CF6")     // Purple
    static let accent = Color(hex: "EC4899")        // Pink

    // Semantic colors
    static let income = Color(hex: "10B981")        // Green - for income
    static let expense = Color(hex: "EF4444")       // Red - for expenses

    // Neutral colors
    #if os(iOS)
    static let cardBackground = Color(.systemBackground).opacity(0.8)
    #else
    static let cardBackground = Color(nsColor: .windowBackgroundColor).opacity(0.8)
    #endif
    static let secondaryText = Color.secondary

    // Gradient colors for glass effect
    static let glassGradient = LinearGradient(
        colors: [.white.opacity(0.5), primary.opacity(0.1), .clear],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Background gradient
    static let backgroundGradient = LinearGradient(
        colors: [primary.opacity(0.1), secondary.opacity(0.05), accent.opacity(0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

enum AppSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48

    static let cardCornerRadius: CGFloat = 20
    static let buttonCornerRadius: CGFloat = 12
    static let iconSize: CGFloat = 44
    static let smallIconSize: CGFloat = 32
}

enum AppStrings {
    // Tab titles
    static let overview = "Overzicht"
    static let subscriptions = "Abonnementen"
    static let settings = "Instellingen"

    // Dashboard
    static let balance = "Balans"
    static let monthlyIncome = "Maandelijkse inkomsten"
    static let monthlyExpenses = "Maandelijkse uitgaven"
    static let upcomingPayments = "Aankomende betalingen"
    static let noUpcomingPayments = "Geen aankomende betalingen"

    // Subscriptions
    static let addSubscription = "Abonnement toevoegen"
    static let editSubscription = "Abonnement bewerken"
    static let deleteSubscription = "Verwijderen"
    static let noSubscriptions = "Nog geen abonnementen"
    static let addFirstSubscription = "Voeg je eerste abonnement toe"

    // Form fields
    static let name = "Naam"
    static let amount = "Bedrag"
    static let category = "Categorie"
    static let frequency = "Frequentie"
    static let startDate = "Startdatum"
    static let nextPayment = "Volgende betaling"
    static let notes = "Notities"
    static let isIncome = "Dit is een inkomst"
    static let isActive = "Actief"

    // Cost breakdown
    static let perDay = "Per dag"
    static let perWeek = "Per week"
    static let perMonth = "Per maand"
    static let perYear = "Per jaar"

    // Buttons
    static let save = "Opslaan"
    static let cancel = "Annuleer"
    static let delete = "Verwijder"
    static let edit = "Bewerk"

    // Settings
    static let appearance = "Weergave"
    static let theme = "Thema"
    static let currency = "Valuta"
    static let about = "Over Recurr"
    static let version = "Versie"

    // Theme options
    static let themeSystem = "Systeem"
    static let themeLight = "Licht"
    static let themeDark = "Donker"
}

enum AppDefaults {
    static let currency = "EUR"
    static let currencySymbol = "€"
}
