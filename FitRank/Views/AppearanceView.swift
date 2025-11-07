import SwiftUI

struct AppearanceView: View {
    @ObservedObject var themeManager = ThemeManager.shared

    var body: some View {
        Form {
            Section(header: Text("Select Theme")) {
                ForEach(AppTheme.allCases) { theme in
                    HStack(spacing: 12) {
                        Image(systemName: iconForTheme(theme))
                            .font(.title3)
                            .foregroundColor(theme.accentColor)
                            .frame(width: 30)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(theme.displayName)
                                    .font(.body)

                                if theme.isPremium && !themeManager.isUnlocked(theme) {
                                    Label("Premium", systemImage: "lock.fill")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Text(themeDescription(theme))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if theme == themeManager.selectedTheme {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard themeManager.isUnlocked(theme) || !theme.isPremium else { return }
                        withAnimation(.easeInOut(duration: 0.2)) {
                            themeManager.selectedTheme = theme
                        }
                    }
                    .contextMenu {
                        // Developer-only local unlock to simulate future IAP
                        if theme.isPremium && !themeManager.isUnlocked(theme) {
                            Button {
                                themeManager.unlock(theme)
                            } label: {
                                Label("Unlock Locally", systemImage: "key.fill")
                            }
                        }
                    }
                }
            }

            Section(footer: Text("Your theme is stored only on this device. It is not synced to your account or the cloud.")) {
                EmptyView()
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(themeManager.selectedTheme.colorScheme)
        .tint(themeManager.selectedTheme.accentColor)
    }

    private func iconForTheme(_ theme: AppTheme) -> String {
        switch theme {
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        case .ocean:  return "drop.fill"
        case .sunset: return "sun.horizon.fill"
        case .forest: return "leaf.fill"
        }
    }

    private func themeDescription(_ theme: AppTheme) -> String {
        switch theme {
        case .light:  return "Bright, standard interface"
        case .dark:   return "Dark UI, ideal in low light"
        case .ocean:  return "Teal accents with cool tones"
        case .sunset: return "Warm accents with orange notes"
        case .forest: return "Green accents with natural hues"
        }
    }
}
