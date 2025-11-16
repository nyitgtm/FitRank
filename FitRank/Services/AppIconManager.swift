//
//  AppIconManager.swift
//  FitRank
//
//  Manages alternate app icons that users can purchase and equip
//

import UIKit
import SwiftUI

class AppIconManager: ObservableObject {
    static let shared = AppIconManager()
    
    @Published var currentIcon: AppIcon = .primary
    
    private init() {
        // Load current icon on init
        loadCurrentIcon()
    }
    
    enum AppIcon: String, CaseIterable, Codable {
        case primary = "AppIcon"
         case gold = "AppIcon-Gold"
         case platinum = "AppIcon-Platinum"
         case diamond = "AppIcon-Diamond"
         case limited = "AppIcon-Limited"
//        case gold = "AppIcon"
//        case platinum = "AppIcon"
//        case diamond = "AppIcon"
//        case limited = "AppIcon"
        
        var displayName: String {
            switch self {
            case .primary: return "Classic"
            case .gold: return "Gold"
            case .platinum: return "Plat"
            case .diamond: return "Diamond"
            case .limited: return "Limited"
            }
        }
        
        var description: String {
            switch self {
            case .primary: return "The original FitRank icon"
            case .gold: return "Luxury gold-themed icon"
            case .platinum: return "Sleek platinum design"
            case .diamond: return "Exclusive diamond-studded icon"
            case .limited: return "Special limited time icon"
            }
        }
        
        var iconName: String? {
            // nil means primary app icon
            self == .primary ? nil : rawValue
        }
        
        var previewImageName: String {
            // For displaying in the shop
            rawValue
        }
    }
    
    func setIcon(_ icon: AppIcon) {
        guard UIApplication.shared.supportsAlternateIcons else {
            print("⚠️ Alternate icons not supported")
            return
        }

        if let iconName = icon.iconName {
    if let path = Bundle.main.path(forResource: iconName, ofType: "appiconset") {
        print("✅ Found app icon set at: \(path)")
    } else {
        print("❌ Cannot find app icon set: \(iconName)")
    }
}

        
        UIApplication.shared.setAlternateIconName(icon.iconName) { error in
            if let error = error {
                print("❌ Failed to set app icon: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.currentIcon = icon
                    self.saveCurrentIcon(icon)
                    print("✅ App icon changed to: \(icon.displayName)")
                    AppIconManager.shared.resetToPrimaryIcon()
                }
            }
        }
    }
    
    private func loadCurrentIcon() {
        if let iconName = UIApplication.shared.alternateIconName,
           let icon = AppIcon(rawValue: iconName) {
            currentIcon = icon
        } else {
            currentIcon = .primary
        }
    }
    
    private func saveCurrentIcon(_ icon: AppIcon) {
        UserDefaults.standard.set(icon.rawValue, forKey: "currentAppIcon")
    }
    
    func supportsAlternateIcons() -> Bool {
        return UIApplication.shared.supportsAlternateIcons
    }

    func resetToPrimaryIcon() {
        guard UIApplication.shared.supportsAlternateIcons else { return }
    
    UIApplication.shared.setAlternateIconName(nil) { error in
            if let error = error {
                print("❌ Failed to reset icon: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.currentIcon = .primary
                    self.saveCurrentIcon(.primary)
                    print("✅ Reset to primary app icon")
                }
            }
        }
    }

}

// MARK: - Shop Item Extension for App Icons

extension ShopItem {
    var appIcon: AppIconManager.AppIcon? {
        // Map shop item IDs to app icons
        switch self.id {
        case "appicon_gold":
            return .gold
        case "appicon_platinum":
            return .platinum
        case "appicon_diamond":
            return .diamond
        case "appicon_limited":
            return .limited
        default:
            return .primary
        }
    }
}
