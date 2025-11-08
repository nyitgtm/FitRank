import SwiftUI

struct ThemedBackground: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager
    func body(content: Content) -> some View {
        ZStack {
            themeManager.selectedTheme.gradientBackground
                .ignoresSafeArea()
            content
        }
    }
}

extension View {
    func themedBackground() -> some View {
        self.modifier(ThemedBackground())
    }
}

