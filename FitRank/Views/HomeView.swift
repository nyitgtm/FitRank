import SwiftUI
import PhotosUI

struct HomeView: View {
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @StateObject private var userViewModel = UserViewModel()
    @State private var selectedFilter: WorkoutFilter = .all
    @State private var showingUpload = false

    // NEW: use this to push CommunityView when the purple chip is tapped
    @State private var goToCommunity = false
    @State private var showingCommunity = false
    @State private var showingNutrition = false   // REPLACED: Now for nutrition

    enum WorkoutFilter: String, CaseIterable {
        case all = "All"
        case following = "Following"
        case team = "Team"
        case trending = "Trending"
        case community = "Community"

        var color: Color {
            switch self {
            case .all: return .blue
            case .following: return .green
            case .team: return .orange
            case .trending: return .red
            case .community: return .purple
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {

                // Hidden link that pushes the Community page
                NavigationLink(
                    destination: CommunityView()
                        .navigationBarTitleDisplayMode(.inline),
                    isActive: $goToCommunity
                ) { EmptyView() }
                .hidden()

                // Filter tabs (purple Community chip lives here)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(WorkoutFilter.allCases, id: \.self) { filter in
                            FilterTabView(
                                filter: filter,
                                isSelected: selectedFilter == filter
                            ) {
                                selectedFilter = filter
                                if filter == .community {
                                    goToCommunity = true   // push CommunityView
                                }
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
                            ForEach(workoutViewModel.workouts) { workout in
                                WorkoutCardView(workout: workout)
                                    .padding(.horizontal, 20)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("FitRank")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                // REPLACED: Community button with Nutrition button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingNutrition = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Nutrition")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
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
        .sheet(isPresented: $showingCommunity) { CommunityView() }
        // CHANGE THIS ONE LINE ONLY:
        .sheet(isPresented: $showingNutrition) { NutritionMainView() }  // CHANGED: Now opens Nutrition Hub instead of direct calculator
        .onAppear { workoutViewModel.fetchWorkouts() }
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

