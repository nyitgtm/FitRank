import SwiftUI

struct AppearanceView: View {
    @ObservedObject var themeManager = ThemeManager.shared

    var body: some View {
        Form {
            Section(header: Text("Select Theme")) {
                ForEach(AppTheme.allCases) { theme in
                    HStack {
                        // Theme icon
                        Image(systemName: iconForTheme(theme))
                            .font(.title3)
                            .foregroundColor(theme.accentColor)
                            .frame(width: 30)
                        
                        Text(theme.displayName)
                            .font(.body)
                        
                        Spacer()
                        
                        if theme == themeManager.selectedTheme {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            themeManager.selectedTheme = theme
                        }
                    }
                }
            }
            
            Section(footer: Text("Theme changes are saved automatically and stored locally on your device.")) {
                EmptyView()
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func iconForTheme(_ theme: AppTheme) -> String {
        switch theme {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .ocean: return "drop.fill"
        case .sunset: return "sun.horizon.fill"
        case .forest: return "leaf.fill"
        }
    }
}

#Preview {
    NavigationView {
        AppearanceView()
    }
}



