import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return AppStrings.themeSystem
        case .light: return AppStrings.themeLight
        case .dark: return AppStrings.themeDark
        }
    }

    var iconName: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

@Observable
final class ThemeService {
    private static let themeKey = "app_theme"

    var currentTheme: AppTheme {
        didSet {
            saveTheme()
        }
    }

    init() {
        if let savedTheme = UserDefaults.standard.string(forKey: Self.themeKey),
           let theme = AppTheme(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .system
        }
    }

    private func saveTheme() {
        UserDefaults.standard.set(currentTheme.rawValue, forKey: Self.themeKey)
    }

    var preferredColorScheme: ColorScheme? {
        currentTheme.colorScheme
    }
}

// MARK: - Environment Key

struct ThemeServiceKey: EnvironmentKey {
    static let defaultValue = ThemeService()
}

extension EnvironmentValues {
    var themeService: ThemeService {
        get { self[ThemeServiceKey.self] }
        set { self[ThemeServiceKey.self] = newValue }
    }
}
