//
//  ShopViewModel.swift
//  FitRank
//

import Foundation

@MainActor
class ShopViewModel: ObservableObject {
    @Published var inventory: UserInventory = UserInventory()
    @Published var shopItems: [ShopItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingPurchaseSuccess = false
    @Published var lastPurchasedItem: ShopItem?
    
    private let userDefaults = UserDefaults.standard
    private let inventoryKey = "userInventory"
    
    init() {
        loadInventory()
        loadShopItems()
    }
    
    func loadInventory() {
        if let data = userDefaults.data(forKey: inventoryKey),
           let decoded = try? JSONDecoder().decode(UserInventory.self, from: data) {
            inventory = decoded
        } else {
            // Default starting tokens
            inventory = UserInventory(tokens: 1000)
            saveInventory()
        }
    }
    
    func saveInventory() {
        if let encoded = try? JSONEncoder().encode(inventory) {
            userDefaults.set(encoded, forKey: inventoryKey)
        }
    }
    
    func loadShopItems() {
        // In a real app, this would fetch from Firebase
        shopItems = ShopItem.sampleItems
    }
    
    func purchaseItem(_ item: ShopItem) {
        guard inventory.tokens >= item.price else {
            errorMessage = "Not enough tokens!"
            return
        }
        
        guard !inventory.ownedItemIds.contains(item.id) else {
            errorMessage = "You already own this item!"
            return
        }
        
        // Deduct tokens
        inventory.tokens -= item.price
        
        // Add to owned items
        inventory.ownedItemIds.insert(item.id)
        
        // Auto-equip if it's the first of its type
        switch item.type {
        case .theme:
            if inventory.equippedThemeId == nil {
                inventory.equippedThemeId = item.id
            }
        case .badge:
            if inventory.equippedBadgeId == nil {
                inventory.equippedBadgeId = item.id
            }
        case .title:
            if inventory.equippedTitleId == nil {
                inventory.equippedTitleId = item.id
            }
        case .effect:
            break
        }
        
        saveInventory()
        lastPurchasedItem = item
        showingPurchaseSuccess = true
    }
    
    func equipItem(_ item: ShopItem) {
        guard inventory.ownedItemIds.contains(item.id) else { return }
        
        switch item.type {
        case .theme:
            inventory.equippedThemeId = item.id
        case .badge:
            inventory.equippedBadgeId = item.id
        case .title:
            inventory.equippedTitleId = item.id
        case .effect:
            break
        }
        
        saveInventory()
    }
    
    func addTokens(_ amount: Int) {
        inventory.tokens += amount
        saveInventory()
    }
    
    func resetInventory() {
        inventory = UserInventory(tokens: 1000)
        saveInventory()
    }
}
