//
//  FitRankApp.swift
//  FitRank
//
//  Created by Navraj Singh on 6/7/25.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct FitRankApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // ✅ Use the shared singleton instance
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager) // ✅ Make theme accessible everywhere
                .preferredColorScheme(themeManager.selectedTheme.colorScheme) // ✅ Apply Light / Dark Modes
                .accentColor(themeManager.selectedTheme.accentColor) // ✅ Apply theme accent color
        }
    }
}


