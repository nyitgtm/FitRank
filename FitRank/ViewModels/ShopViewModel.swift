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
    private let userDefaultsKey = "purchasedItemIds"
    
    init() {
        Task {
            await loadInventory()
            await loadShopItems()
        }
        loadLocalPurchases()
    }
    
    // MARK: - Load Functions
    
    func loadInventory() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let userDoc = try await db.collection("users").document(userId).getDocument()
            if let tokens = userDoc.data()?["tokens"] as? Int {
                inventory.tokens = tokens
            }
            
            // Load equipped items from Firebase
            if let equippedTheme = userDoc.data()?["equippedThemeId"] as? String {
                inventory.equippedThemeId = equippedTheme
            }
            if let equippedBadge = userDoc.data()?["equippedBadgeId"] as? String {
                inventory.equippedBadgeId = equippedBadge
            }
            if let equippedTitle = userDoc.data()?["equippedTitleId"] as? String {
                inventory.equippedTitleId = equippedTitle
            }
        } catch {
            print("Failed to load tokens: \(error)")
        }
    }
    
    func loadShopItems() async {
        do {
            let snapshot = try await db.collection("shopItems").getDocuments()
            
            if snapshot.documents.isEmpty {
                // Initialize shop items in Firestore
                await initializeShopItems()
            } else {
                // Load from Firestore
                shopItems = snapshot.documents.compactMap { doc -> ShopItem? in
                    try? doc.data(as: ShopItem.self)
                }
            }
        } catch {
            print("Failed to load shop items: \(error)")
            shopItems = ShopItem.allItems // Fallback to local items
        }
    }
    
    private func initializeShopItems() async {
        let allItems = ShopItem.allItems
        
        for item in allItems {
            do {
                try db.collection("shopItems").document(item.id).setData(from: item)
            } catch {
                print("Failed to initialize item \(item.id): \(error)")
            }
        }
        
        shopItems = allItems
    }
    
    private func loadLocalPurchases() {
        if let savedIds = UserDefaults.standard.array(forKey: userDefaultsKey) as? [String] {
            inventory.ownedItemIds = Set(savedIds)
        }
    }
    
    private func saveLocalPurchase(_ itemId: String) {
        var purchases = UserDefaults.standard.array(forKey: userDefaultsKey) as? [String] ?? []
        if !purchases.contains(itemId) {
            purchases.append(itemId)
            UserDefaults.standard.set(purchases, forKey: userDefaultsKey)
        }
    }
    
    // MARK: - Shop Actions
    
    func refreshTokenBalance() async {
        await loadInventory()
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
                // Create a batch write
                let batch = db.batch()
                
                // 1. Deduct tokens from user
                let userRef = db.collection("users").document(userId)
                batch.updateData([
                    "tokens": FieldValue.increment(Int64(-item.price))
                ], forDocument: userRef)
                
                // 2. Increment purchase count for item
                let itemRef = db.collection("shopItems").document(item.id)
                batch.updateData([
                    "purchaseCount": FieldValue.increment(Int64(1))
                ], forDocument: itemRef)
                
                // 3. Record purchase in user's purchases subcollection
                let purchaseRef = db.collection("users").document(userId).collection("purchases").document(item.id)
                batch.setData([
                    "itemId": item.id,
                    "itemName": item.name,
                    "price": item.price,
                    "purchasedAt": FieldValue.serverTimestamp(),
                    "type": item.type.rawValue
                ], forDocument: purchaseRef)
                
                // Commit batch
                try await batch.commit()
                
                // Update local inventory
                inventory.tokens -= item.price
                inventory.ownedItemIds.insert(item.id)
                
                // Save purchase locally
                saveLocalPurchase(item.id)
                
                // Auto-equip if it's the first of its type
                switch item.type {
                case .theme:
                    if inventory.equippedThemeId == nil {
                        await equipItem(item)
                    }
                case .badge:
                    if inventory.equippedBadgeId == nil {
                        await equipItem(item)
                    }
                case .title:
                    if inventory.equippedTitleId == nil {
                        await equipItem(item)
                    }
                case .merchandise:
                    break // Merchandise doesn't get equipped
                }
                
                // Update purchase count in local item
                if let index = shopItems.firstIndex(where: { $0.id == item.id }) {
                    shopItems[index].purchaseCount += 1
                }
                
                lastPurchasedItem = item
                showingPurchaseSuccess = true
                
            } catch {
                errorMessage = "Purchase failed: \(error.localizedDescription)"
            }
        }
    }
    
    func equipItem(_ item: ShopItem) async {
        guard inventory.ownedItemIds.contains(item.id) else { return }
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        switch item.type {
        case .theme:
            inventory.equippedThemeId = item.id
            try? await db.collection("users").document(userId).updateData([
                "equippedThemeId": item.id
            ])
        case .badge:
            inventory.equippedBadgeId = item.id
            try? await db.collection("users").document(userId).updateData([
                "equippedBadgeId": item.id
            ])
        case .title:
            inventory.equippedTitleId = item.id
            try? await db.collection("users").document(userId).updateData([
                "equippedTitleId": item.id
            ])
        case .merchandise:
            break
        }
    }
}
