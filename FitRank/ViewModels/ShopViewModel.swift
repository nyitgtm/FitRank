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
            
            var items: [ShopItem] = []
            
            for document in snapshot.documents {
                let data = document.data()
                
                // Manually create item with document ID
                guard let name = data["name"] as? String,
                      let description = data["description"] as? String,
                      let price = data["price"] as? Int,
                      let rarityString = data["rarity"] as? String,
                      let categoryString = data["category"] as? String,
                      let rarity = ItemRarity(rawValue: rarityString),
                      let category = ShopItemType(rawValue: categoryString) else {
                    print("⚠️ Skipping item \(document.documentID) - missing required fields")
                    continue
                }
                
                let isActive = data["isActive"] as? Bool ?? true
                let isFeatured = data["isFeatured"] as? Bool ?? false
                let purchaseCount = data["purchaseCount"] as? Int ?? 0
                let imageUrl = data["imageUrl"] as? String
                
                // Handle timestamps
                let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
                let availableUntil = (data["availableUntil"] as? Timestamp)?.dateValue()
                
                let item = ShopItem(
                    id: document.documentID,
                    name: name,
                    description: description,
                    price: price,
                    rarity: rarity,
                    category: category,
                    imageUrl: imageUrl,
                    isActive: isActive,
                    isFeatured: isFeatured,
                    createdAt: createdAt,
                    availableUntil: availableUntil,
                    purchaseCount: purchaseCount
                )
                
                // Only add active items
                if item.isActive && !item.isExpired {
                    items.append(item)
                    print("✅ Loaded item: \(item.name) (ID: \(document.documentID))")
                }
            }
            
            shopItems = items.sorted { item1, item2 in
                // Sort by: featured first, then by rarity, then by price
                if item1.isFeatured != item2.isFeatured {
                    return item1.isFeatured
                }
                if item1.rarity != item2.rarity {
                    return item1.rarity.rawValue < item2.rarity.rawValue
                }
                return item1.price > item2.price
            }
            
            print("✅ Loaded \(shopItems.count) shop items total")
            
        } catch {
            print("❌ Failed to load shop items: \(error)")
        }
    }
    
    private func loadLocalPurchases() {
        if let savedIds = UserDefaults.standard.array(forKey: userDefaultsKey) as? [String] {
            inventory.ownedItemIds = Set(savedIds)
            print("✅ Loaded \(savedIds.count) local purchases")
        }
    }
    
    private func saveLocalPurchase(_ itemId: String) {
        var purchases = UserDefaults.standard.array(forKey: userDefaultsKey) as? [String] ?? []
        if !purchases.contains(itemId) {
            purchases.append(itemId)
            UserDefaults.standard.set(purchases, forKey: userDefaultsKey)
            print("💾 Saved purchase locally: \(itemId)")
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
        
        // For merchandise, allow repurchase. For other items, check if already owned
        if item.type != .merchandise && inventory.ownedItemIds.contains(item.id) {
            errorMessage = "You already own this item!"
            return
        }
        
        print("🛒 Attempting to purchase: \(item.name) (ID: \(item.id)) for \(item.price) tokens")
        
        Task {
            do {
                // Create a batch write
                let batch = db.batch()
                
                // 1. Deduct tokens from user
                let userRef = db.collection("users").document(userId)
                batch.updateData([
                    "tokens": FieldValue.increment(Int64(-item.price))
                ], forDocument: userRef)
                
                // 2. Increment purchase count for item (only if document exists)
                let itemRef = db.collection("shopItems").document(item.id)
                
                // Check if document exists first
                let itemDoc = try await itemRef.getDocument()
                if itemDoc.exists {
                    batch.updateData([
                        "purchaseCount": FieldValue.increment(Int64(1))
                    ], forDocument: itemRef)
                } else {
                    print("⚠️ Shop item document doesn't exist: \(item.id)")
                }
                
                // 3. Record purchase in user's purchases subcollection
                // For merchandise, use a unique document ID with timestamp
                let purchaseDocId = item.type == .merchandise ?
                    "\(item.id)_\(Int(Date().timeIntervalSince1970))" : item.id
                
                let purchaseRef = db.collection("users").document(userId).collection("purchases").document(purchaseDocId)
                batch.setData([
                    "itemId": item.id,
                    "itemName": item.name,
                    "price": item.price,
                    "purchasedAt": FieldValue.serverTimestamp(),
                    "category": item.category.rawValue
                ], forDocument: purchaseRef)
                
                // Commit batch
                try await batch.commit()
                
                // Update local inventory
                inventory.tokens -= item.price
                
                // Only save to owned items if it's not merchandise (or first purchase)
                if item.type != .merchandise {
                    inventory.ownedItemIds.insert(item.id)
                    saveLocalPurchase(item.id)
                } else if !inventory.ownedItemIds.contains(item.id) {
                    // First time purchasing this merchandise
                    inventory.ownedItemIds.insert(item.id)
                    saveLocalPurchase(item.id)
                }
                
                // Auto-equip or apply the item
                if item.type != .merchandise {
                    switch item.category {
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
                    case .appicon:
                        // Immediately apply the app icon
                        await equipItem(item)
                    case .merchandise:
                        break
                    }
                }
                
                // Update purchase count in local item
                if let index = shopItems.firstIndex(where: { $0.id == item.id }) {
                    shopItems[index].purchaseCount += 1
                }
                
                lastPurchasedItem = item
                showingPurchaseSuccess = true
                
                print("✅ Successfully purchased \(item.name)")
                
            } catch {
                errorMessage = "Purchase failed: \(error.localizedDescription)"
                print("❌ Purchase failed: \(error)")
            }
        }
    }
    
    func equipItem(_ item: ShopItem) async {
        guard inventory.ownedItemIds.contains(item.id) else { return }
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        switch item.category {
        case .theme:
            inventory.equippedThemeId = item.id
            try? await db.collection("users").document(userId).updateData([
                "equippedThemeId": item.id
            ])
            print("✅ Equipped theme: \(item.name)")
        case .badge:
            inventory.equippedBadgeId = item.id
            try? await db.collection("users").document(userId).updateData([
                "equippedBadgeId": item.id
            ])
            print("✅ Equipped badge: \(item.name)")
        case .title:
            inventory.equippedTitleId = item.id
            try? await db.collection("users").document(userId).updateData([
                "equippedTitleId": item.id
            ])
            print("✅ Equipped title: \(item.name)")
        case .appicon:
            // Apply the app icon
            if let appIcon = item.appIcon {
                AppIconManager.shared.setIcon(appIcon)
            }
        case .merchandise:
            break
        }
    }
}
