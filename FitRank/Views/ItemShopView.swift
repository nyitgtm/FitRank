//
//  ItemShopView.swift
//  FitRank
//

import SwiftUI

struct ItemShopView: View {
    @StateObject private var viewModel = ShopViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: ShopTab = .featured
    
    enum ShopTab: String, CaseIterable {
        case featured = "Featured"
        case themes = "Themes"
        case badges = "Badges"
        case titles = "Titles"
    }
    
    var filteredItems: [ShopItem] {
        switch selectedTab {
        case .featured:
            return viewModel.shopItems.filter { $0.isNew || $0.expiresAt != nil }
        case .themes:
            return viewModel.shopItems.filter { $0.type == .theme }
        case .badges:
            return viewModel.shopItems.filter { $0.type == .badge }
        case .titles:
            return viewModel.shopItems.filter { $0.type == .title }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.08, blue: 0.15),
                        Color(red: 0.1, green: 0.12, blue: 0.2)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Token balance header
                    TokenBalanceHeader(tokens: viewModel.inventory.tokens)
                        .padding()
                    
                    // Tab selector
                    ShopTabSelector(selectedTab: $selectedTab)
                        .padding(.horizontal)
                    
                    // Shop items grid
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            ForEach(filteredItems) { item in
                                ShopItemCard(
                                    item: item,
                                    isOwned: viewModel.inventory.ownedItemIds.contains(item.id),
                                    isEquipped: isItemEquipped(item)
                                ) {
                                    if viewModel.inventory.ownedItemIds.contains(item.id) {
                                        viewModel.equipItem(item)
                                    } else {
                                        viewModel.purchaseItem(item)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Item Shop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .alert("Purchase Successful!", isPresented: $viewModel.showingPurchaseSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                if let item = viewModel.lastPurchasedItem {
                    Text("You've unlocked \(item.name)!")
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    private func isItemEquipped(_ item: ShopItem) -> Bool {
        switch item.type {
        case .theme:
            return viewModel.inventory.equippedThemeId == item.id
        case .badge:
            return viewModel.inventory.equippedBadgeId == item.id
        case .title:
            return viewModel.inventory.equippedTitleId == item.id
        case .effect:
            return false
        }
    }
}

// MARK: - Token Balance Header
struct TokenBalanceHeader: View {
    let tokens: Int
    
    var body: some View {
        HStack {
            Image(systemName: "star.circle.fill")
                .font(.title)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Your Balance")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Text("\(tokens) Tokens")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [.yellow.opacity(0.5), .orange.opacity(0.5)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 2
                        )
                )
        )
    }
}

// MARK: - Shop Tab Selector
struct ShopTabSelector: View {
    @Binding var selectedTab: ItemShopView.ShopTab
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(ItemShopView.ShopTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = tab
                    }
                }) {
                    Text(tab.rawValue)
                        .font(.subheadline)
                        .fontWeight(selectedTab == tab ? .bold : .medium)
                        .foregroundColor(selectedTab == tab ? .black : .white)
                        .lineLimit(1)                     
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selectedTab == tab ?
                            Color.white :
                            Color.white.opacity(0.2)
                        )
                        .cornerRadius(20)

                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Shop Item Card
struct ShopItemCard: View {
    let item: ShopItem
    let isOwned: Bool
    let isEquipped: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Top section with icon and rarity
            ZStack(alignment: .topLeading) {
                // Gradient background based on rarity
                LinearGradient(
                    gradient: Gradient(colors: item.rarity.gradientColors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 140)
                
                // New badge
                if item.isNew {
                    HStack {
                        Text("NEW")
                            .font(.caption2)
                            .fontWeight(.black)
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.yellow)
                            .cornerRadius(4)
                        Spacer()
                    }
                    .padding(8)
                }
                
                // Icon in center
                VStack {
                    Spacer()
                    Image(systemName: item.iconName)
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    Spacer()
                }
            }
            
            // Bottom section with info
            VStack(alignment: .leading, spacing: 8) {
                // Rarity and name
                HStack {
                    Text(item.rarity.rawValue.uppercased())
                        .font(.caption2)
                        .fontWeight(.black)
                        .foregroundColor(item.rarity.color)
                    
                    Spacer()
                    
                    // Time remaining if limited
                    if let timeRemaining = item.timeRemaining {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                            Text(timeRemaining)
                                .font(.caption2)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.orange)
                    }
                }
                
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(item.description)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
                
                Spacer()
                
                // Purchase/Equip button
                Button(action: onTap) {
                    HStack {
                        if isOwned {
                            if isEquipped {
                                Text("EQUIPPED")
                                    .font(.caption)
                                    .fontWeight(.black)
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                            } else {
                                Text("EQUIP")
                                    .font(.caption)
                                    .fontWeight(.black)
                            }
                        } else {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                            Text("\(item.price)")
                                .font(.caption)
                                .fontWeight(.black)
                        }
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        isEquipped ? Color.green :
                        isOwned ? Color.cyan :
                        Color.white
                    )
                    .cornerRadius(8)
                }
                .disabled(isEquipped)
            }
            .padding(12)
            .background(Color(red: 0.15, green: 0.17, blue: 0.25))
        }
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(item.rarity.color.opacity(0.5), lineWidth: 2)
        )
        .shadow(color: item.rarity.color.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    ItemShopView()
}
