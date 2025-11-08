//
//  ItemShopView.swift
//  FitRank
//

import SwiftUI
import FirebaseAuth

enum ClaimType {
    case comments
    case uploads
    case likes
}

struct ItemShopView: View {
    @StateObject private var viewModel = ShopViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var dailyTasks: DailyTasks?
    @State private var isLoadingTasks = false
    @State private var isClaiming = false
    @State private var showClaimSuccess = false
    @State private var claimedAmount = 0
    @State private var currentTime = Date()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
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
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Token balance header
                        TokenBalanceHeader(tokens: viewModel.inventory.tokens)
                            .padding(.horizontal)
                        
                        // Daily Tasks Section
                        DailyTasksCard(
                            dailyTasks: dailyTasks,
                            isLoading: isLoadingTasks,
                            isClaiming: isClaiming,
                            currentTime: currentTime,
                            onClaimComments: { claimRewards(type: .comments) },
                            onClaimUploads: { claimRewards(type: .uploads) },
                            onClaimLikes: { claimRewards(type: .likes) }
                        )
                        .padding(.horizontal)
                        
                        // Shop items grid
                        Text("Shop Items")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            ForEach(viewModel.shopItems) { item in
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
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Shop & Earn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await loadDailyTasks()
                            await viewModel.refreshTokenBalance()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.white)
                    }
                }
            }
            .task {
                await loadDailyTasks()
            }
            .onReceive(timer) { time in
                currentTime = time
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
            .alert("Rewards Claimed! 🎉", isPresented: $showClaimSuccess) {
                Button("Awesome!", role: .cancel) { }
            } message: {
                Text("You earned \(claimedAmount) coins!")
            }
        }
    }
    
    private func loadDailyTasks() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoadingTasks = true
        do {
            dailyTasks = try await DailyTasksService.shared.getTodaysTasks(userId: userId)
        } catch {
            print("Failed to load daily tasks: \(error)")
        }
        isLoadingTasks = false
    }
    
    private func claimRewards(type: ClaimType) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            isClaiming = true
            do {
                let amount: Int
                
                switch type {
                case .comments:
                    amount = try await DailyTasksService.shared.claimCommentRewards(userId: userId)
                case .uploads:
                    amount = try await DailyTasksService.shared.claimUploadRewards(userId: userId)
                case .likes:
                    amount = try await DailyTasksService.shared.claimLikeRewards(userId: userId)
                }
                
                // Update tasks
                await loadDailyTasks()
                
                // Refresh token balance
                await viewModel.refreshTokenBalance()
                
                // Show success
                claimedAmount = amount
                showClaimSuccess = true
                
                // Haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
            } catch {
                print("Failed to claim rewards: \(error)")
                viewModel.errorMessage = error.localizedDescription
            }
            isClaiming = false
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

// MARK: - Daily Tasks Card
struct DailyTasksCard: View {
    let dailyTasks: DailyTasks?
    let isLoading: Bool
    let isClaiming: Bool
    let currentTime: Date
    let onClaimComments: () -> Void
    let onClaimUploads: () -> Void
    let onClaimLikes: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checklist")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                Text("Daily Coin Tasks")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
            }
            
            if let tasks = dailyTasks {
                VStack(spacing: 12) {
                    // Comments Progress
                    DailyTaskRow(
                        icon: "bubble.left.fill",
                        title: "Leave Comments",
                        current: tasks.commentsCount,
                        max: DailyTasks.maxComments,
                        coinsPerAction: DailyTasks.coinsPerComment,
                        canClaim: tasks.canClaimComments,
                        isClaimed: tasks.commentsClaimed,
                        timeRemaining: tasks.commentsTimeRemaining,
                        isClaiming: isClaiming,
                        onClaim: onClaimComments
                    )
                    
                    // Upload Progress
                    DailyTaskRow(
                        icon: "arrow.up.circle.fill",
                        title: "Upload Workout",
                        current: tasks.uploadsCount,
                        max: DailyTasks.maxUploads,
                        coinsPerAction: DailyTasks.coinsPerUpload,
                        canClaim: tasks.canClaimUploads,
                        isClaimed: tasks.uploadsClaimed,
                        timeRemaining: tasks.uploadsTimeRemaining,
                        isClaiming: isClaiming,
                        onClaim: onClaimUploads
                    )
                    
                    // Likes Progress
                    DailyTaskRow(
                        icon: "heart.fill",
                        title: "Like Posts",
                        current: tasks.likesCount,
                        max: DailyTasks.maxLikes,
                        coinsPerAction: DailyTasks.coinsPerLike,
                        canClaim: tasks.canClaimLikes,
                        isClaimed: tasks.likesClaimed,
                        timeRemaining: tasks.likesTimeRemaining,
                        isClaiming: isClaiming,
                        onClaim: onClaimLikes
                    )
                }
            } else {
                Text("Loading tasks...")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.subheadline)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 2)
                )
        )
    }
}

// MARK: - Daily Task Row
struct DailyTaskRow: View {
    let icon: String
    let title: String
    let current: Int
    let max: Int
    let coinsPerAction: Int
    let canClaim: Bool
    let isClaimed: Bool
    let timeRemaining: TimeInterval
    let isClaiming: Bool
    let onClaim: () -> Void
    
    var progress: Double {
        Double(current) / Double(max)
    }
    
    var isComplete: Bool {
        current >= max
    }
    
    var totalCoins: Int {
        current * coinsPerAction
    }
    
    var formattedTimeRemaining: String {
        let hours = Int(timeRemaining) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.cyan)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    // TIMER RIGHT UNDER TITLE
                    if isClaimed && timeRemaining > 0 {
                        Text("⏱️ \(formattedTimeRemaining)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                            .monospacedDigit()
                    }
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text("\(totalCoins)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                }
            }
            
            HStack {
                Text("\(current)/\(max)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                if isClaimed && timeRemaining <= 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                        Text("Ready!")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.green)
                } else if isClaimed {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                        Text("Claimed")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.green)
                } else if canClaim {
                    Button(action: onClaim) {
                        HStack(spacing: 4) {
                            if isClaiming {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            } else {
                                Image(systemName: "gift.fill")
                                    .font(.caption)
                                Text("CLAIM!")
                                    .font(.caption)
                                    .fontWeight(.bold)
                            }
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(8)
                    }
                    .disabled(isClaiming)
                } else if isComplete {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                        Text("Complete!")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.green)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.2))
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: isComplete ? [.green, .green] : [.cyan, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
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
                
                Text("\(tokens) Coins")
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
