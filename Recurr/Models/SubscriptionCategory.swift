import SwiftUI

enum SubscriptionCategory: String, Codable, CaseIterable, Identifiable {
    // Expense categories
    case streaming = "streaming"
    case music = "music"
    case gaming = "gaming"
    case software = "software"
    case utilities = "utilities"
    case insurance = "insurance"
    case health = "health"
    case fitness = "fitness"
    case news = "news"
    case education = "education"
    case food = "food"
    case transportation = "transportation"
    case housing = "housing"
    case other = "other"

    // Income categories
    case salary = "salary"
    case freelance = "freelance"
    case investment = "investment"
    case rental = "rental"
    case otherIncome = "otherIncome"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .streaming: return "Streaming"
        case .music: return "Muziek"
        case .gaming: return "Gaming"
        case .software: return "Software"
        case .utilities: return "Nuts & Telecom"
        case .insurance: return "Verzekeringen"
        case .health: return "Gezondheid"
        case .fitness: return "Fitness"
        case .news: return "Nieuws & Media"
        case .education: return "Educatie"
        case .food: return "Eten & Drinken"
        case .transportation: return "Vervoer"
        case .housing: return "Wonen"
        case .other: return "Overig"
        case .salary: return "Salaris"
        case .freelance: return "Freelance"
        case .investment: return "Beleggingen"
        case .rental: return "Verhuur"
        case .otherIncome: return "Overige inkomsten"
        }
    }

    var iconName: String {
        switch self {
        case .streaming: return "play.tv.fill"
        case .music: return "music.note"
        case .gaming: return "gamecontroller.fill"
        case .software: return "app.badge.fill"
        case .utilities: return "bolt.fill"
        case .insurance: return "shield.fill"
        case .health: return "heart.fill"
        case .fitness: return "figure.run"
        case .news: return "newspaper.fill"
        case .education: return "book.fill"
        case .food: return "fork.knife"
        case .transportation: return "car.fill"
        case .housing: return "house.fill"
        case .other: return "ellipsis.circle.fill"
        case .salary: return "banknote.fill"
        case .freelance: return "briefcase.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .rental: return "key.fill"
        case .otherIncome: return "plus.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .streaming: return Color(hex: "E50914") // Netflix red
        case .music: return Color(hex: "1DB954") // Spotify green
        case .gaming: return Color(hex: "9147FF") // Twitch purple
        case .software: return Color(hex: "007AFF") // Apple blue
        case .utilities: return Color(hex: "FFB800") // Yellow
        case .insurance: return Color(hex: "00C853") // Green
        case .health: return Color(hex: "FF4081") // Pink
        case .fitness: return Color(hex: "FF5722") // Orange
        case .news: return Color(hex: "607D8B") // Blue grey
        case .education: return Color(hex: "3F51B5") // Indigo
        case .food: return Color(hex: "FF9800") // Orange
        case .transportation: return Color(hex: "2196F3") // Blue
        case .housing: return Color(hex: "795548") // Brown
        case .other: return Color(hex: "9E9E9E") // Grey
        case .salary: return Color(hex: "10B981") // Green
        case .freelance: return Color(hex: "06B6D4") // Cyan
        case .investment: return Color(hex: "8B5CF6") // Purple
        case .rental: return Color(hex: "F59E0B") // Amber
        case .otherIncome: return Color(hex: "6366F1") // Indigo
        }
    }

    var isIncomeCategory: Bool {
        switch self {
        case .salary, .freelance, .investment, .rental, .otherIncome:
            return true
        default:
            return false
        }
    }

    static var expenseCategories: [SubscriptionCategory] {
        allCases.filter { !$0.isIncomeCategory }
    }

    static var incomeCategories: [SubscriptionCategory] {
        allCases.filter { $0.isIncomeCategory }
    }
}
