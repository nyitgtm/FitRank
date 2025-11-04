//
//  ShopModels.swift
//  FitRank
//

import Foundation
import SwiftUI

enum ItemRarity: String, Codable {
    case common = "Common"
    case rare = "Rare"
    case epic = "Epic"
    case legendary = "Legendary"
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .common: return [Color.gray.opacity(0.8), Color.gray]
        case .rare: return [Color.blue.opacity(0.8), Color.blue]
        case .epic: return [Color.purple.opacity(0.8), Color.purple]
        case .legendary: return [Color.orange.opacity(0.8), Color.red]
        }
    }
}

enum ShopItemType: String, Codable {
    case theme = "Theme"
    case badge = "Badge"
    case effect = "Effect"
    case title = "Title"
}

struct ShopItem: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let price: Int // in tokens
    let rarity: ItemRarity
    let type: ShopItemType
    let iconName: String
    let previewImageName: String?
    let isNew: Bool
    let expiresAt: Date? // For limited time items
    
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
    
    var timeRemaining: String? {
        guard let expiresAt = expiresAt else { return nil }
        let interval = expiresAt.timeIntervalSince(Date())
        if interval <= 0 { return "Expired" }
        
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct UserInventory: Codable {
    var tokens: Int = 0
    var ownedItemIds: Set<String> = []
    var equippedThemeId: String?
    var equippedBadgeId: String?
    var equippedTitleId: String?
}

// Sample shop items
extension ShopItem {
    static let sampleItems: [ShopItem] = [
        ShopItem(
            id: "theme_dark_mode",
            name: "Dark Titan",
            description: "Sleek dark theme with neon accents",
            price: 500,
            rarity: .legendary,
            type: .theme,
            iconName: "moon.stars.fill",
            previewImageName: nil,
            isNew: true,
            expiresAt: Date().addingTimeInterval(86400 * 2) // 2 days
        ),
        ShopItem(
            id: "theme_ocean",
            name: "Ocean Breeze",
            description: "Calm blue gradient theme",
            price: 300,
            rarity: .epic,
            type: .theme,
            iconName: "water.waves",
            previewImageName: nil,
            isNew: false,
            expiresAt: nil
        ),
        ShopItem(
            id: "badge_fire",
            name: "Fire Badge",
            description: "Show your intensity",
            price: 150,
            rarity: .rare,
            type: .badge,
            iconName: "flame.fill",
            previewImageName: nil,
            isNew: false,
            expiresAt: nil
        ),
        ShopItem(
            id: "badge_lightning",
            name: "Lightning Strike",
            description: "Speed and power combined",
            price: 200,
            rarity: .epic,
            type: .badge,
            iconName: "bolt.fill",
            previewImageName: nil,
            isNew: true,
            expiresAt: Date().addingTimeInterval(86400) // 1 day
        ),
        ShopItem(
            id: "title_beast",
            name: "Beast Mode",
            description: "Legendary title for champions",
            price: 400,
            rarity: .legendary,
            type: .title,
            iconName: "crown.fill",
            previewImageName: nil,
            isNew: false,
            expiresAt: nil
        ),
        ShopItem(
            id: "theme_sunset",
            name: "Sunset Warrior",
            description: "Warm orange and pink gradients",
            price: 250,
            rarity: .rare,
            type: .theme,
            iconName: "sunset.fill",
            previewImageName: nil,
            isNew: false,
            expiresAt: nil
        )
    ]
}
