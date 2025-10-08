import SwiftUI
import PhotosUI

struct HomeView: View {
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @StateObject private var userViewModel = UserViewModel()
    @State private var selectedFilter: WorkoutFilter = .all
    @State private var showingUpload = false
    @State private var showingLeaderboard = false

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
                                isSelected: selectedFilter == filter
                            ) {
                                selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 12)

                // Workout feed
                if workoutViewModel.isLoading {
                    Spacer()
                    ProgressView("Loading workouts...")
                        .scaleEffect(1.2)
                    Spacer()
                } else if workoutViewModel.workouts.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)

                        Text("No workouts yet")
                            .font(.title2).fontWeight(.medium)
                            .foregroundColor(.primary)

                        Text("Be the first to upload a workout!")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button("Upload Workout") { showingUpload = true }
                            .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Workout cards
                            ForEach(workoutViewModel.workouts) { workout in
                                WorkoutCardView(workout: workout)
                                    .padding(.horizontal, 20)
                            }
                            
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
                                
                                // Embedded mini heatmap
                                Heatmap()
                                    .frame(height: 300)
                                    .cornerRadius(16)
                                    .padding(.horizontal, 20)
                            }
                            .padding(.vertical, 16)
                        }
                        .padding(.vertical, 16)
                    }
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
                    Button { showingUpload = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
        }
        .sheet(isPresented: $showingUpload) { UploadView() }
        .sheet(isPresented: $showingLeaderboard) { LeaderboardView() }
        .onAppear { workoutViewModel.fetchWorkouts() }
    }
}

// Sleek FitRank header with dark gym aesthetic
struct FitRankHeaderView: View {
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
                    .foregroundColor(.white)
            }
            
            // FitRank text with dark red/orange gradient
            Text("FitRank")
                .font(.system(size: 45, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.15, green: 0.15, blue: 0.15),      // Dark gray (start)
                            Color(red: 0.3, green: 0.32, blue: 0.35),       // Darker medium (middle)
                            Color(red: 0.42, green: 0.44, blue: 0.47)       // Subdued silver (end)
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
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(filter.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : filter.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? filter.color : filter.color.opacity(0.1))
                .cornerRadius(16)
        }
    }
}
