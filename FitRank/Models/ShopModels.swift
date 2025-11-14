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
    case merchandise = "Merchandise"
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
    var purchaseCount: Int // Track total purchases from all users
    
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

// Shop items organized by category
extension ShopItem {
    static let themes: [ShopItem] = [
        ShopItem(
            id: "theme_dark_titan",
            name: "Dark Titan",
            description: "Sleek dark theme with neon accents",
            price: 500,
            rarity: .legendary,
            type: .theme,
            iconName: "moon.stars.fill",
            previewImageName: nil,
            isNew: true,
            expiresAt: Date().addingTimeInterval(86400 * 7), // 7 days
            purchaseCount: 0
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
            expiresAt: nil,
            purchaseCount: 0
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
            expiresAt: nil,
            purchaseCount: 0
        ),
        ShopItem(
            id: "theme_forest",
            name: "Forest Green",
            description: "Natural green theme",
            price: 200,
            rarity: .rare,
            type: .theme,
            iconName: "leaf.fill",
            previewImageName: nil,
            isNew: false,
            expiresAt: nil,
            purchaseCount: 0
        )
    ]
    
    static let merchandise: [ShopItem] = [
        ShopItem(
            id: "merch_tshirt",
            name: "FitRank T-Shirt",
            description: "Premium quality workout tee",
            price: 800,
            rarity: .epic,
            type: .merchandise,
            iconName: "tshirt.fill",
            previewImageName: nil,
            isNew: true,
            expiresAt: nil,
            purchaseCount: 0
        ),
        ShopItem(
            id: "merch_hoodie",
            name: "FitRank Hoodie",
            description: "Comfortable hoodie for the gym",
            price: 1200,
            rarity: .legendary,
            type: .merchandise,
            iconName: "rectangle.fill",
            previewImageName: nil,
            isNew: true,
            expiresAt: nil,
            purchaseCount: 0
        ),
        ShopItem(
            id: "merch_bottle",
            name: "Water Bottle",
            description: "Stay hydrated in style",
            price: 400,
            rarity: .rare,
            type: .merchandise,
            iconName: "waterbottle.fill",
            previewImageName: nil,
            isNew: false,
            expiresAt: nil,
            purchaseCount: 0
        ),
        ShopItem(
            id: "merch_towel",
            name: "Gym Towel",
            description: "Microfiber workout towel",
            price: 300,
            rarity: .rare,
            type: .merchandise,
            iconName: "rectangle.split.3x1.fill",
            previewImageName: nil,
            isNew: false,
            expiresAt: nil,
            purchaseCount: 0
        )
    ]
    
    static let badges: [ShopItem] = [
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
            expiresAt: nil,
            purchaseCount: 0
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
            expiresAt: Date().addingTimeInterval(86400 * 3), // 3 days
            purchaseCount: 0
        ),
        ShopItem(
            id: "badge_diamond",
            name: "Diamond Badge",
            description: "Unbreakable determination",
            price: 350,
            rarity: .legendary,
            type: .badge,
            iconName: "diamond.fill",
            previewImageName: nil,
            isNew: false,
            expiresAt: nil,
            purchaseCount: 0
        ),
        ShopItem(
            id: "badge_star",
            name: "Rising Star",
            description: "For the up-and-comers",
            price: 100,
            rarity: .common,
            type: .badge,
            iconName: "star.fill",
            previewImageName: nil,
            isNew: false,
            expiresAt: nil,
            purchaseCount: 0
        )
    ]
    
    static let titles: [ShopItem] = [
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
            expiresAt: nil,
            purchaseCount: 0
        ),
        ShopItem(
            id: "title_warrior",
            name: "Gym Warrior",
            description: "For the dedicated",
            price: 250,
            rarity: .epic,
            type: .title,
            iconName: "shield.fill",
            previewImageName: nil,
            isNew: false,
            expiresAt: nil,
            purchaseCount: 0
        ),
        ShopItem(
            id: "title_rookie",
            name: "Rookie",
            description: "Just getting started",
            price: 50,
            rarity: .common,
            type: .title,
            iconName: "person.fill",
            previewImageName: nil,
            isNew: false,
            expiresAt: nil,
            purchaseCount: 0
        )
    ]
    
    static var allItems: [ShopItem] {
        themes + merchandise + badges + titles
    }
}
