import SwiftUI
import FirebaseAuth

struct PublicProfileView: View {
    let userId: String
    @StateObject private var viewModel = PublicProfileViewModel()
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showBlockAlert = false
    @State private var selectedWorkout: Workout?
    @State private var commentingWorkout: Workout?
    
    var body: some View {
        NavigationView {
            ScrollView {
                if viewModel.isLoading {
                    ProgressView("Loading profile...")
                        .padding(.top, 50)
                } else if let user = viewModel.user {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
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
                                .shadow(radius: 5)
                            
                            VStack(spacing: 4) {
                                Text(user.name)
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                Text("@\(user.username)")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                if user.isCoach {
                                    Label("Coach", systemImage: "shield.fill")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.orange.opacity(0.15))
                                        .foregroundColor(.orange)
                                        .cornerRadius(8)
                                        .padding(.top, 4)
                                }
                            }
                        }
                        .padding(.top, 20)
                        
                        // Action Buttons
                        if viewModel.friendStatus != .selfProfile {
                            HStack(spacing: 12) {
                                Button {
                                    if viewModel.friendStatus == .none {
                                        Task {
                                            await viewModel.sendFriendRequest(targetUserId: userId)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: friendStatusIcon)
                                        Text(friendStatusText)
                                    }
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(friendStatusColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                                .disabled(viewModel.friendStatus != .none)
                                
                                Button {
                                    showBlockAlert = true
                                } label: {
                                    Image(systemName: "hand.raised.slash.fill")
                                        .font(.system(size: 20))
                                        .frame(width: 50, height: 50)
                                        .background(Color.red.opacity(0.1))
                                        .foregroundColor(.red)
                                        .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Stats Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            StatBox(title: "Friends", value: "\(viewModel.friendsCount)")
                            StatBox(title: "Workouts", value: "\(viewModel.workoutCount)")
                            StatBox(title: "Tokens", value: "\(user.tokens)")
                        }
                        .padding(.horizontal)
                        
                        // Best SQD
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Best Lifts")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            HStack(spacing: 12) {
                                BestLiftCard(lift: "Squat", weight: viewModel.bestSquat, color: .red)
                                BestLiftCard(lift: "Bench", weight: viewModel.bestBench, color: .blue)
                                BestLiftCard(lift: "Deadlift", weight: viewModel.bestDeadlift, color: .green)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Favorite Gym
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Favorite Gym")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            HStack {
                                Image(systemName: "dumbbell.fill")
                                    .foregroundColor(.purple)
                                    .frame(width: 30)
                                
                                Text(viewModel.favoriteGym)
                                    .font(.body)
                                    .fontWeight(.medium)
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        
                        // Workouts List (Preview)
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Recent Workouts")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            if workoutViewModel.isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else if workoutViewModel.userWorkouts.isEmpty {
                                Text("No published workouts yet")
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach(workoutViewModel.userWorkouts.prefix(5)) { workout in
                                        PublicWorkoutCard(
                                            workout: workout,
                                            onTap: {
                                                selectedWorkout = workout
                                            },
                                            onComment: {
                                                commentingWorkout = workout
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.bottom, 30)
                } else {
                    Text("User not found")
                        .foregroundColor(.secondary)
                        .padding(.top, 50)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadUser(userId: userId)
                await workoutViewModel.fetchAllUserWorkouts(userId: userId)
            }
            .alert("Block User?", isPresented: $showBlockAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Block", role: .destructive) {
                    Task {
                        await viewModel.blockUser(targetUserId: userId)
                        dismiss()
                    }
                }
            } message: {
                Text("They will no longer be able to see your content or interact with you.")
            }
            .sheet(item: $selectedWorkout) { workout in
                WorkoutDetailView(workout: workout)
            }
            .sheet(item: $commentingWorkout) { workout in
                if let workoutID = workout.id {
                    CommentsSheetView(workoutID: workoutID)
                        .presentationDragIndicator(.visible)
                        .presentationDetents([.medium, .large])
                }
            }
        }
    }
    
    private var friendStatusText: String {
        switch viewModel.friendStatus {
        case .none: return "Add Friend"
        case .pending: return "Requested"
        case .friends: return "Friends"
        case .selfProfile: return "You"
        }
    }
    
    private var friendStatusIcon: String {
        switch viewModel.friendStatus {
        case .none: return "person.badge.plus"
        case .pending: return "clock.fill"
        case .friends: return "person.2.fill"
        case .selfProfile: return "person.fill"
        }
    }
    
    private var friendStatusColor: Color {
        switch viewModel.friendStatus {
        case .none: return .blue
        case .pending: return .orange
        case .friends: return .green
        case .selfProfile: return .gray
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct BestLiftCard: View {
    let lift: String
    let weight: Int
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(lift)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
                .textCase(.uppercase)
            
            Text("\(weight)")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("lbs")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// Simplified workout card for public profile (no delete button)
struct PublicWorkoutCard: View {
    let workout: Workout
    let onTap: () -> Void
    let onComment: () -> Void
    @ObservedObject private var voteService = VoteService.shared
    @State private var upvotes: Int = 0
    @State private var downvotes: Int = 0
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with lift type
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.liftTypeEnum.displayName)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("\(workout.weight) lbs")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    // Play icon
                    Image(systemName: "play.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                }
                
                Divider()
                
                // Stats
                HStack(spacing: 20) {
                    WorkoutStatItem(icon: "eye.fill", value: "\(workout.views)", color: .secondary)
                    WorkoutStatItem(icon: "hand.thumbsup", value: "\(upvotes)", color: .green)
                    WorkoutStatItem(icon: "hand.thumbsdown", value: "\(downvotes)", color: .red)
                    
                    // Comment button
                    Button {
                        onComment()
                    } label: {
                        WorkoutStatItem(icon: "text.bubble", value: "Comment", color: .blue)
                    }
                }
                
                // Date
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(workout.createdAt, style: .relative)
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                    
                    Spacer()
                }
                
                // Tap to view hint
                HStack {
                    Spacer()
                    Text("Tap to view")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .task {
            if let id = workout.id {
                await voteService.fetchVoteCounts(workoutId: id)
                if let counts = voteService.voteCounts[id] {
                    upvotes = counts.upvotes
                    downvotes = counts.downvotes
                }
            }
        }
        .onReceive(voteService.$voteCounts) { _ in
            if let id = workout.id, let counts = voteService.voteCounts[id] {
                upvotes = counts.upvotes
                downvotes = counts.downvotes
            }
        }
    }
}
