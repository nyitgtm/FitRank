//
//  ShopViewModel.swift
//  FitRank
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class ShopViewModel: ObservableObject {
    @Published var inventory: UserInventory = UserInventory()
    @Published var shopItems: [ShopItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingPurchaseSuccess = false
    @Published var lastPurchasedItem: ShopItem?
    
    private let db = Firestore.firestore()
    
    init() {
        Task {
            await loadInventory()
        }
        loadShopItems()
    }
    
    func loadInventory() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Get user's token balance from Firebase
            let userDoc = try await db.collection("users").document(userId).getDocument()
            if let tokens = userDoc.data()?["tokens"] as? Int {
                inventory.tokens = tokens
            }
        } catch {
            print("Failed to load tokens: \(error)")
        }
    }
    
    func refreshTokenBalance() async {
        await loadInventory()
    }
    
    func loadShopItems() {
        // In a real app, this would fetch from Firebase
        shopItems = ShopItem.sampleItems
    }
    
    func purchaseItem(_ item: ShopItem) {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Please sign in to purchase items"
            return
        }
        
        guard inventory.tokens >= item.price else {
            errorMessage = "Not enough tokens!"
            return
        }
        
        guard !inventory.ownedItemIds.contains(item.id) else {
            errorMessage = "You already own this item!"
            return
        }
        
        Task {
            do {
                // Deduct tokens in Firebase
                try await db.collection("users").document(userId).updateData([
                    "tokens": FieldValue.increment(Int64(-item.price))
                ])
                
                // Update local inventory
                inventory.tokens -= item.price
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
                
                lastPurchasedItem = item
                showingPurchaseSuccess = true
                
            } catch {
                errorMessage = "Purchase failed: \(error.localizedDescription)"
            }
        }
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
    }
}
