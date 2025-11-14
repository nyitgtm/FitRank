//
//  ShopModels.swift
//  FitRank
//

import Foundation
import SwiftUI

enum ItemRarity: String, Codable {
    case common = "common"
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"
    
    var displayName: String {
        rawValue.capitalized
    }
    
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
    case theme = "theme"
    case badge = "badge"
    case merchandise = "merchandise"
    case title = "title"
    
    var displayName: String {
        switch self {
        case .theme: return "Theme"
        case .badge: return "Badge"
        case .merchandise: return "Merch"
        case .title: return "Title"
        }
    }
}

struct ShopItem: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let price: Int
    let rarity: ItemRarity
    let category: ShopItemType
    let imageUrl: String?
    let isActive: Bool
    let isFeatured: Bool
    let createdAt: Date?
    let availableUntil: Date?
    var purchaseCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case price
        case rarity
        case category
        case imageUrl
        case isActive
        case isFeatured
        case createdAt
        case availableUntil
        case purchaseCount
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Use document ID if available, otherwise generate one
        id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        price = try container.decode(Int.self, forKey: .price)
        rarity = try container.decode(ItemRarity.self, forKey: .rarity)
        category = try container.decode(ShopItemType.self, forKey: .category)
        imageUrl = try? container.decode(String.self, forKey: .imageUrl)
        isActive = (try? container.decode(Bool.self, forKey: .isActive)) ?? true
        isFeatured = (try? container.decode(Bool.self, forKey: .isFeatured)) ?? false
        createdAt = try? container.decode(Date.self, forKey: .createdAt)
        availableUntil = try? container.decode(Date.self, forKey: .availableUntil)
        purchaseCount = (try? container.decode(Int.self, forKey: .purchaseCount)) ?? 0
    }
    
    init(id: String, name: String, description: String, price: Int, rarity: ItemRarity, category: ShopItemType, imageUrl: String? = nil, isActive: Bool = true, isFeatured: Bool = false, createdAt: Date? = nil, availableUntil: Date? = nil, purchaseCount: Int = 0) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.rarity = rarity
        self.category = category
        self.imageUrl = imageUrl
        self.isActive = isActive
        self.isFeatured = isFeatured
        self.createdAt = createdAt
        self.availableUntil = availableUntil
        self.purchaseCount = purchaseCount
    }
    
    var type: ShopItemType {
        category
    }
    
    var isNew: Bool {
        guard let createdAt = createdAt else { return false }
        let daysSinceCreation = Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
        return daysSinceCreation <= 7 // Items are "new" for 7 days
    }
    
    var isExpired: Bool {
        guard let availableUntil = availableUntil else { return false }
        return Date() > availableUntil
    }
    
    var timeRemaining: String? {
        guard let availableUntil = availableUntil else { return nil }
        let interval = availableUntil.timeIntervalSince(Date())
        if interval <= 0 { return "Expired" }
        
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var iconName: String {
        // Return SF Symbol based on category and name
        switch category {
        case .theme:
            if name.lowercased().contains("dark") {
                return "moon.stars.fill"
            } else if name.lowercased().contains("ocean") {
                return "water.waves"
            } else if name.lowercased().contains("sunset") {
                return "sunset.fill"
            } else if name.lowercased().contains("forest") {
                return "leaf.fill"
            } else {
                return "paintbrush.fill"
            }
        case .badge:
            if name.lowercased().contains("fire") {
                return "flame.fill"
            } else if name.lowercased().contains("lightning") {
                return "bolt.fill"
            } else if name.lowercased().contains("diamond") {
                return "diamond.fill"
            } else if name.lowercased().contains("star") {
                return "star.fill"
            } else {
                return "seal.fill"
            }
        case .merchandise:
            if name.lowercased().contains("shirt") || name.lowercased().contains("tshirt") {
                return "tshirt.fill"
            } else if name.lowercased().contains("hoodie") {
                return "rectangle.fill"
            } else if name.lowercased().contains("bottle") {
                return "waterbottle.fill"
            } else if name.lowercased().contains("towel") {
                return "rectangle.split.3x1.fill"
            } else {
                return "bag.fill"
            }
        case .title:
            if name.lowercased().contains("beast") || name.lowercased().contains("champion") {
                return "crown.fill"
            } else if name.lowercased().contains("warrior") {
                return "shield.fill"
            } else {
                return "person.fill"
            }
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
