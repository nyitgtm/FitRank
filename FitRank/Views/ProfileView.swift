import SwiftUI
import Foundation
import FirebaseAuth
import Combine
import FirebaseFirestore

struct ProfileView: View {
    @StateObject private var userViewModel = UserViewModel()
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @StateObject private var teamRepository = TeamRepository()
    @StateObject private var friendsVM = FriendsListViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @Binding var showSignInView: Bool
    @State private var teamName: String = "Loading..."
    @State private var equippedBadge: ShopItem?
    @State private var showingFriendsList = false
    @State private var showingUserWorkouts = false
    @State private var showingItemShop = false

    @State private var showingBlockedUsers = false
    @State private var showingDeleteConfirmation = false
    @State private var deleteErrorMessage: String?
    
    var body: some View {
        ZStack {
            themeManager.selectedTheme.backgroundColor
                .ignoresSafeArea()
            
            if userViewModel.isLoading {
                ProgressView("Loading profile...")
                    .font(.headline)
                    .foregroundColor(.secondary)
            } else if let user = userViewModel.currentUser {
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // Header
                        ModernProfileHeaderView(user: user, equippedBadge: equippedBadge)
                            .padding(.top, 8)
                            
                            // Stats Row
                            ProfileStatsRow(
                                friendsCount: friendsVM.friends.count,
                                workoutCount: workoutViewModel.userWorkouts.count,
                                tokens: user.tokens,
                                onFriendsClick: { showingFriendsList = true },
                                onWorkoutsClick: { showingUserWorkouts = true },
                                onTokensClick: { showingItemShop = true }
                            )
                            
                            // Info Cards
                            VStack(spacing: 20) {
                                ProfileInfoCard(icon: "person.circle", title: "Full Name", value: user.name)
                                ProfileInfoCard(icon: "at", title: "Username", value: "@\(user.username)")
                                ProfileInfoCard(icon: "flag", title: "Team", value: teamName)
                                ProfileInfoCard(icon: "shield.lefthalf.fill", title: "Role", value: user.isCoach ? "Coach" : "Member")
                            }
                            
                            // Appearance Navigation Button
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Settings")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                NavigationLink(destination: AppearanceView()) {
                                    AppearanceNavigationCard(currentTheme: themeManager.selectedTheme)
                                }
                                
                                // Blocked Users Button
                                ModernActionButton(
                                    icon: "hand.raised.slash.fill",
                                    title: "Blocked Users",
                                    color: .red
                                ) {
                                    showingBlockedUsers = true
                                }
                            }
                            
                            // Sign Out Button
                            VStack(spacing: 16) {
                                ModernActionButton(
                                    icon: "rectangle.portrait.and.arrow.right",
                                    title: "Sign Out",
                                    color: .red
                                ) {
                                    userViewModel.signOut()
                                    showSignInView = true
                                }
                                
                                // Delete Account Button
                                Button(action: {
                                    showingDeleteConfirmation = true
                                }) {
                                    Text("Delete Account")
                                        .font(.caption)
                                        .foregroundColor(.red.opacity(0.8))
                                        .padding(.top, 8)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 30)
                        }
                        } else {
                        ProgressView("Loading profile...")
                        }
                        }
                        .navigationTitle("Profile")
                        .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await loadUserAndWorkouts()
            }
            .task {
                await loadUserAndWorkouts()
                friendsVM.loadFriends()
            }
            .sheet(isPresented: $showingFriendsList) {
                FriendsListView()
            }
            .sheet(isPresented: $showingUserWorkouts) {
                if let userId = Auth.auth().currentUser?.uid,
                   let user = userViewModel.currentUser {
                    UserWorkoutsView(
                        workoutViewModel: workoutViewModel,
                        userId: userId,
                        userName: user.name,
                        userUsername: user.username
                    )
                }
            }
            .sheet(isPresented: $showingItemShop) {
                ItemShopView()
            }
            .sheet(isPresented: $showingBlockedUsers) {
                BlockedUsersView()
            }
            .alert("Delete Account?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await deleteAccount()
                    }
                }
            } message: {
                Text("Your account will be suspended in a couple of hours and all content deleted in a business week.")
            }
            .alert("Error", isPresented: Binding<Bool>(
                get: { deleteErrorMessage != nil },
                set: { if !$0 { deleteErrorMessage = nil } }
            )) {
                Button("OK") { }
            } message: {
                if let errorMessage = deleteErrorMessage {
                    Text(errorMessage)
                }
            }
            .preferredColorScheme(themeManager.selectedTheme.colorScheme)
            .accentColor(themeManager.selectedTheme.accentColor)
            }
    
    // MARK: - Helper function
    private func loadUserAndWorkouts() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("ProfileView: No authenticated user found")
            showSignInView = true
            return
        }
        
        print("ProfileView: Fetching user with UID: \(uid)")
        
        do {
            // Fetch teams first
            await teamRepository.fetchTeams()
            
            if let user = try await UserRepository().getUser(uid: uid) {
                print("ProfileView: User fetched successfully - \(user.username)")
                userViewModel.currentUser = user
                
                // Resolve team name from team reference
                if let team = teamRepository.getTeam(byReference: user.team) {
                    teamName = team.name
                } else {
                    teamName = "No Team"
                }
                
                // Load equipped badge
                await loadEquippedBadge(userId: uid)
                
                // Fetch actual user workouts
                await workoutViewModel.fetchAllUserWorkouts(userId: uid)
            } else {
                print("ProfileView: User document not found in Firestore for UID: \(uid)")
                showSignInView = true
            }
        } catch {
            print("ProfileView: Error fetching user - \(error.localizedDescription)")
            print("ProfileView: Full error - \(error)")
            showSignInView = true
        }
    }
    
    private func loadEquippedBadge(userId: String) async {
        let db = Firestore.firestore()
        
        do {
            // Get user's equipped badge ID
            let userDoc = try await db.collection("users").document(userId).getDocument()
            guard let equippedBadgeId = userDoc.data()?["equippedBadgeId"] as? String else {
                print("No equipped badge")
                return
            }
            
            // Fetch the badge details from shopItems
            let badgeDoc = try await db.collection("shopItems").document(equippedBadgeId).getDocument()
            let data = badgeDoc.data()
            
            guard let name = data?["name"] as? String,
                  let description = data?["description"] as? String,
                  let price = data?["price"] as? Int,
                  let rarityString = data?["rarity"] as? String,
                  let categoryString = data?["category"] as? String,
                  let rarity = ItemRarity(rawValue: rarityString),
                  let category = ShopItemType(rawValue: categoryString) else {
                return
            }
            
            let isActive = data?["isActive"] as? Bool ?? true
            let isFeatured = data?["isFeatured"] as? Bool ?? false
            let purchaseCount = data?["purchaseCount"] as? Int ?? 0
            let imageUrl = data?["imageUrl"] as? String
            
            let createdAt = (data?["createdAt"] as? Timestamp)?.dateValue()
            let availableUntil = (data?["availableUntil"] as? Timestamp)?.dateValue()
            
            equippedBadge = ShopItem(
                id: badgeDoc.documentID,
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
            
            print("✅ Loaded equipped badge: \(name)")
            
        } catch {
            print("❌ Failed to load equipped badge: \(error)")
        }
    }
    
    private func deleteAccount() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        do {
            try await UserRepository().markUserForDeletion(uid: uid)
            userViewModel.signOut()
            showSignInView = true
        } catch {
            print("Error deleting account: \(error)")
            deleteErrorMessage = "Failed to delete account. Please try again."
        }
    }
}

// MARK: - Modernized Components

struct ModernProfileHeaderView: View {
    let user: User
    let equippedBadge: ShopItem?
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Picture with Badge
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                
                // Equipped Badge
                if let badge = equippedBadge {
                    if let imageUrl = badge.imageUrl, !imageUrl.isEmpty {
                        AsyncImage(url: URL(string: imageUrl)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 35, height: 35)
                                    .background(
                                        Circle()
                                            .fill(badge.rarity.color.opacity(0.9))
                                            .frame(width: 40, height: 40)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(badge.rarity.color, lineWidth: 2)
                                            .frame(width: 40, height: 40)
                                    )
                                    .shadow(color: badge.rarity.color.opacity(0.5), radius: 4, x: 0, y: 2)
                            case .failure, .empty:
                                Image(systemName: badge.iconName)
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                                    .frame(width: 35, height: 35)
                                    .background(
                                        Circle()
                                            .fill(badge.rarity.color.opacity(0.9))
                                            .frame(width: 40, height: 40)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(badge.rarity.color, lineWidth: 2)
                                            .frame(width: 40, height: 40)
                                    )
                                    .shadow(color: badge.rarity.color.opacity(0.5), radius: 4, x: 0, y: 2)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .offset(x: 5, y: 5)
                    }
                }
            }
            
            VStack(spacing: 4) {
                Text(user.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Text("@\(user.username)")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    // Badge name next to username
                    if let badge = equippedBadge {
                        HStack(spacing: 4) {
                            Text("•")
                                .foregroundColor(.secondary)
                            
                            Text(badge.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(badge.rarity.color)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(badge.rarity.color.opacity(0.15))
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(badge.rarity.color.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                }
            }
            
            if user.isCoach {
                Label("Coach", systemImage: "shield.fill")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .cornerRadius(12)
            }
        }
        .padding(.vertical, 20)
    }
}

struct ProfileStatsRow: View {
    let friendsCount: Int
    let workoutCount: Int
    let tokens: Int
    let onFriendsClick: () -> Void
    let onWorkoutsClick: () -> Void
    let onTokensClick: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // Friends
            Button(action: onFriendsClick) {
                VStack(spacing: 6) {
                    Text("\(friendsCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Friends")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            
            Divider()
                .frame(height: 40)
            
            // Workouts
            Button(action: onWorkoutsClick) {
                VStack(spacing: 6) {
                    Text("\(workoutCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Workouts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            
            Divider()
                .frame(height: 40)
            
            // Tokens
            Button(action: onTokensClick) {
                VStack(spacing: 6) {
                    Text("\(tokens)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Tokens")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

struct ProfileInfoCard: View {
    let icon: String
    let title: String
    let value: String
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(themeManager.selectedTheme.accentColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(RoundedRectangle(cornerRadius: 12).fill(themeManager.selectedTheme.cardBackgroundColor))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 0.5)
        )
    }
}

struct ModernActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Appearance Navigation Card

struct AppearanceNavigationCard: View {
    let currentTheme: AppTheme
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconForTheme(currentTheme))
                .font(.title2)
                .foregroundColor(currentTheme.accentColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("APPEARANCE")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(currentTheme.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 0.5)
        )
    }
    
    private func iconForTheme(_ theme: AppTheme) -> String {
        switch theme {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
//        case .ocean: return "drop.fill"
//        case .sunset: return "sun.horizon.fill"
//        case .forest: return "leaf.fill"
        }
    }
}

// MARK: - Blocked Users View

struct BlockedUsersView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var userRepository = UserRepository()
    @State private var blockedUsers: [User] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading blocked users...")
                } else if blockedUsers.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No blocked users")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List {
                        ForEach(blockedUsers) { user in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(user.name)
                                        .font(.headline)
                                    Text("@\(user.username)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button("Unblock") {
                                    Task {
                                        await unblockUser(user)
                                    }
                                }
                                .buttonStyle(.bordered)
                                .tint(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Blocked Users")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadBlockedUsers()
            }
        }
    }
    
    private func loadBlockedUsers() async {
        isLoading = true
        guard let currentUserId = Auth.auth().currentUser?.uid,
              let currentUser = try? await userRepository.getUser(uid: currentUserId),
              let blockedIds = currentUser.blockedUsers,
              !blockedIds.isEmpty else {
            blockedUsers = []
            isLoading = false
            return
        }
        
        do {
            blockedUsers = try await userRepository.getUsers(ids: blockedIds)
        } catch {
            print("Error loading blocked users: \(error)")
        }
        isLoading = false
    }
    
    private func unblockUser(_ user: User) async {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              let blockedUserId = user.id else { return }
        
        do {
            try await userRepository.unblockUser(currentUserId: currentUserId, blockedUserId: blockedUserId)
            // Remove from local list
            blockedUsers.removeAll { $0.id == blockedUserId }
        } catch {
            print("Error unblocking user: \(error)")
        }
    }
}

#Preview {
    ProfileView(showSignInView: .constant(false))
}
