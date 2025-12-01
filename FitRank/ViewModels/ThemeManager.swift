import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable, Codable {
    case light
    case dark
    // case ocean
    // case sunset
    // case forest

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light:  return "Light"
        case .dark:   return "Dark"
        // case .ocean:  return "Ocean"
        // case .sunset: return "Sunset"
        // case .forest: return "Forest"
        }
    }

    var isPremium: Bool {
        switch self {
        case .light, .dark: return false // , .ocean
        default:                    return true
        }
    }


    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light // , .ocean, .sunset, .forest
        case .dark:                             return .dark
        }
    }

    var accentColor: Color {
        switch self {
        case .light:  return .blue
        case .dark:   return .purple
        // case .ocean:  return Color(red: 0.00, green: 0.60, blue: 0.75) // tropical teal-blue
        // case .sunset: return .orange
        // case .forest: return .green
        }
    }

    var backgroundColor: Color {
        switch self {
        case .dark:   return .black
        // case .ocean:  return Color(red: 0.04, green: 0.35, blue: 0.50) // deep sea base
        default:      return Color(.systemGroupedBackground)
        }
    }

    var cardBackgroundColor: Color {
        switch self {
        case .dark:   return Color(.secondarySystemBackground)
        // case .ocean:  return Color(red: 0.12, green: 0.55, blue: 0.70).opacity(0.85)
        default:      return Color(.systemBackground)
        }
    }

    var gradientBackground: LinearGradient {
        switch self {
        // case .ocean:
        //     return LinearGradient(
        //         colors: [
        //             Color(red: 0.00, green: 0.45, blue: 0.65),
        //             Color(red: 0.00, green: 0.65, blue: 0.75),
        //             Color(red: 0.00, green: 0.80, blue: 0.85)
        //         ],
        //         startPoint: .topLeading,
        //         endPoint: .bottomTrailing
        //     )
        case .dark:
            return LinearGradient(colors: [.black, .gray.opacity(0.5)],
                                  startPoint: .top, endPoint: .bottom)
        default:
            return LinearGradient(colors: [.white, .gray.opacity(0.06)],
                                  startPoint: .top, endPoint: .bottom)
        }
    }
}


@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    private init() { loadPersisted() }

    private let kSelectedTheme = "fitrank.selectedTheme"
    private let kUnlocked      = "fitrank.unlockedThemes"

    @Published var selectedTheme: AppTheme = .dark {
        didSet { persist() }
    }
    @Published var unlockedThemes: Set<String> = [] {
        didSet { persist() }
    }

    func isUnlocked(_ theme: AppTheme) -> Bool {
        !theme.isPremium || unlockedThemes.contains(theme.id)
    }

    func unlock(_ theme: AppTheme) {
        guard theme.isPremium else { return }
        unlockedThemes.insert(theme.id)
    }

    func resetToSystemDefaults() {
        selectedTheme = .dark
    }

    private func persist() {
        UserDefaults.standard.set(selectedTheme.id, forKey: kSelectedTheme)
        UserDefaults.standard.set(Array(unlockedThemes), forKey: kUnlocked)
    }

    private func loadPersisted() {
        if let id = UserDefaults.standard.string(forKey: kSelectedTheme),
           let restored = AppTheme(rawValue: id) {
            selectedTheme = restored
        } else {
            selectedTheme = .dark
        }
        if let saved = UserDefaults.standard.array(forKey: kUnlocked) as? [String] {
            unlockedThemes = Set(saved)
        } else {
            unlockedThemes = []
        }
    }
}
