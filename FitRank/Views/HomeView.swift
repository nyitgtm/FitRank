import SwiftUI
import PhotosUI
import FirebaseAuth

struct HomeView: View {
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @StateObject private var userViewModel = UserViewModel()
    @StateObject private var gymRepository = GymRepository()
    @StateObject private var friendRequestVM = FriendRequestViewModel()
    @StateObject private var friendsVM = FriendsListViewModel()
    @State private var selectedFilter: WorkoutFilter = .all
    @State private var showingUpload = false
    @State private var showingLeaderboard = false
    @State private var showingUserSearch = false
    @State private var showingFriendRequests = false
    @State private var showingFriendsList = false
    @State private var showingFullScreenHeatmap = false
    @State private var showingItemShop = false
    @State private var hasLoadedGyms = false

    enum WorkoutFilter: String, CaseIterable {
        case all = "All"
        case following = "Following"
        case team = "Team"
        case trending = "Trending"

        var color: Color {
            switch self {
            case .all: return .blue
            case .following: return .green
            case .team: return .orange
            case .trending: return .red
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom FitRank Header
                FitRankHeaderView()
                    .padding(.vertical, 8)

                // Filter tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(WorkoutFilter.allCases, id: \.self) { filter in
                            FilterTabView(
                                filter: filter,
                                isSelected: selectedFilter == filter,
                                friendsCount: filter == .following ? friendsVM.friends.count : nil
                            ) {
                                if filter == .following {
                                    // Show friends list popup when tapping Following
                                    showingFriendsList = true
                                } else {
                                    selectedFilter = filter
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 12)

                // Workout feed
                ScrollView {
                    VStack(spacing: 20) {
                        // My Workouts Section (Top 3 recent)
                        MyWorkoutsSection(
                            workoutViewModel: workoutViewModel,
                            userViewModel: userViewModel
                        )
                        .padding(.top, 8)
                        
                        // Heatmap section at the bottom
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "map.fill")
                                    .foregroundColor(.blue)
                                Text("Gym Heatmap")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            
                            // Loading state or mini heatmap preview
                            if !hasLoadedGyms {
                                HeatmapLoadingBox()
                                    .frame(height: 300)
                                    .padding(.horizontal, 20)
                            } else {
                                // Mini heatmap preview (clickable)
                                Heatmap(gymRepository: gymRepository)
                                    .frame(height: 300)
                                    .cornerRadius(16)
                                    .padding(.horizontal, 20)
                                    .onTapGesture {
                                        showingFullScreenHeatmap = true
                                    }
                                    .overlay(
                                        // Subtle tap hint overlay
                                        VStack {
                                            Spacer()
                                            HStack {
                                                Spacer()
                                                HStack(spacing: 4) {
                                                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                                                        .font(.caption2)
                                                    Text("Tap to expand")
                                                        .font(.caption2)
                                                        .fontWeight(.medium)
                                                }
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(.ultraThinMaterial)
                                                .cornerRadius(12)
                                                .padding(12)
                                            }
                                        }
                                    )
                            }
                        }
                        .padding(.vertical, 16)
                    }
                    .padding(.bottom, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Leaderboard button (trophy icon)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingLeaderboard = true
                    } label: {
                        Image(systemName: "trophy.fill")
                            .font(.title3)
                            .foregroundColor(.yellow)
                            .shadow(color: .orange.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // Item Shop button
                        Button {
                            showingItemShop = true
                        } label: {
                            ZStack {
                                Image(systemName: "cart.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.purple, .pink],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                // Sparkle effect
                                Image(systemName: "sparkles")
                                    .font(.system(size: 8))
                                    .foregroundColor(.yellow)
                                    .offset(x: 10, y: -8)
                            }
                        }
                        
                        // Friend Requests Bell with badge
                        Button {
                            showingFriendRequests = true
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: friendRequestVM.unreadCount > 0 ? "bell.badge.fill" : "bell.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(friendRequestVM.unreadCount > 0 ? .blue : .secondary)
                                
                                if friendRequestVM.unreadCount > 0 {
                                    Text("\(friendRequestVM.unreadCount)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(minWidth: 16, minHeight: 16)
                                        .background(Color.red)
                                        .clipShape(Circle())
                                        .offset(x: 8, y: -8)
                                }
                            }
                        }
                        
                        // Search button
                        Button {
                            showingUserSearch = true
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        // Upload button
                        Button { showingUpload = true } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingUpload) { UploadView() }
        .sheet(isPresented: $showingLeaderboard) { LeaderboardView() }
        .sheet(isPresented: $showingUserSearch) {
            UserSearchView()
        }
        .sheet(isPresented: $showingFriendRequests) {
            FriendRequestNotificationsView()
        }
        .sheet(isPresented: $showingFriendsList) {
            FriendsListView()
        }
        .sheet(isPresented: $showingItemShop) {
            ItemShopView()
        }
        .fullScreenCover(isPresented: $showingFullScreenHeatmap) {
            FullScreenHeatmapView(isPresented: $showingFullScreenHeatmap, gymRepository: gymRepository)
        }
        .task {
            // Ensure user is loaded on first appear
            if let userId = Auth.auth().currentUser?.uid {
                await userViewModel.fetchUserProfile(userId: userId)
            }
            
            // Fetch gyms
            gymRepository.fetchGyms()
            friendRequestVM.loadFriendRequests()
            friendsVM.loadFriends()
        }
        .onChange(of: gymRepository.gyms.count) { oldValue, newValue in
            if newValue > 0 {
                hasLoadedGyms = true
            }
        }
    }
}

// Sleek FitRank header with dark gym aesthetic
struct FitRankHeaderView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Dark metallic dumbbell icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.05, green: 0.05, blue: 0.05),  // Deep black
                                Color(red: 0.2, green: 0.2, blue: 0.22),    // Dark charcoal
                                Color(red: 0.5, green: 0.52, blue: 0.55)    // Silver
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 62, height: 62)
                    .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
                
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? .black : .white)
            }
            
            // FitRank text - adaptive to dark mode
            Text("FitRank")
                .font(.system(size: 45, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: colorScheme == .dark ? [
                            Color.white,
                            Color(red: 0.85, green: 0.85, blue: 0.85),
                            Color(red: 0.7, green: 0.7, blue: 0.7)
                        ] : [
                            Color(red: 0.15, green: 0.15, blue: 0.15),
                            Color(red: 0.3, green: 0.32, blue: 0.35),
                            Color(red: 0.42, green: 0.44, blue: 0.47)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.3, green: 0.3, blue: 0.3).opacity(0.5),
                            Color(red: 0.6, green: 0.62, blue: 0.65).opacity(0.5)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2
                )
        )
        .padding(.horizontal, 20)
    }
}

struct FilterTabView: View {
    let filter: HomeView.WorkoutFilter
    let isSelected: Bool
    let friendsCount: Int?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(filter.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let count = friendsCount, count > 0 {
                    Text("(\(count))")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(isSelected ? .white : filter.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? filter.color : filter.color.opacity(0.1))
            .cornerRadius(16)
        }
    }
}

// Loading box for heatmap
struct HeatmapLoadingBox: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                
                Text("Loading Gyms...")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("Fetching nearby gym data")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.7))
            }
        }
    }
}

// Preview box for heatmap (clickable)
struct HeatmapPreviewBox: View {
    let gymCount: Int
    
    var body: some View {
        ZStack {
            // Blurred background to suggest map content
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.1),
                            Color.green.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                )
            
            VStack(spacing: 12) {
                Image(systemName: "map.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                
                Text("\(gymCount) Gyms Loaded")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Tap to view full heatmap")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    Image(systemName: "hand.tap.fill")
                        .foregroundColor(.blue)
                    Text("Tap Here")
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.blue.opacity(0.15))
                .cornerRadius(20)
            }
        }
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// Full screen heatmap view
struct FullScreenHeatmapView: View {
    @Binding var isPresented: Bool
    @ObservedObject var gymRepository: GymRepository
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // The heatmap fills the entire screen
            Heatmap(gymRepository: gymRepository)
                .edgesIgnoringSafeArea(.all)
            
            // Done button in top left
            VStack {
                HStack {
                    Button {
                        isPresented = false
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                            Text("Done")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.4), radius: 5, x: 0, y: 2)
                    }
                    .padding(.leading, 20)
                    .padding(.top, 30)
                    
                    Spacer()
                }
                
                Spacer()
            }
        }
    }
}
