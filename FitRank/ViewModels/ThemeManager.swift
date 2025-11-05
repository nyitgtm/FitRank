import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case light
    case dark
    case ocean
    case sunset
    case forest

    var id: String { self.rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .ocean: return .dark // Ocean uses dark mode with cyan accents
        case .sunset: return .light // Sunset uses light mode with warm colors
        case .forest: return .dark // Forest uses dark mode with green accents
        }
    }

    var accentColor: Color {
        switch self {
        case .light: return .blue
        case .dark: return .blue
        case .ocean: return Color.cyan
        case .sunset: return Color.orange
        case .forest: return Color.green
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .light: return Color(.systemBackground)
        case .dark: return Color(.systemBackground)
        case .ocean: return Color(red: 0.05, green: 0.15, blue: 0.25) // Deep ocean blue
        case .sunset: return Color(red: 1.0, green: 0.95, blue: 0.9) // Warm sunset
        case .forest: return Color(red: 0.1, green: 0.15, blue: 0.1) // Dark forest green
        }
    }
    
    var cardBackgroundColor: Color {
        switch self {
        case .light: return Color(.systemBackground)
        case .dark: return Color(.systemBackground)
        case .ocean: return Color(red: 0.1, green: 0.2, blue: 0.35)
        case .sunset: return Color.white
        case .forest: return Color(red: 0.15, green: 0.25, blue: 0.15)
        }
    }

    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .ocean: return "Ocean"
        case .sunset: return "Sunset"
        case .forest: return "Forest"
        }
    }
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var selectedTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: "app_theme")
        }
    }
    
    // Computed property for backward compatibility
    var isDarkMode: Bool {
        get { selectedTheme == .dark }
        set { selectedTheme = newValue ? .dark : .light }
    }
    
    private init() {
        let stored = UserDefaults.standard.string(forKey: "app_theme")
        self.selectedTheme = AppTheme(rawValue: stored ?? "") ?? .light
    }
}


