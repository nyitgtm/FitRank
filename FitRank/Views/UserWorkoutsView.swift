import SwiftUI

struct UserWorkoutsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var workoutViewModel: WorkoutViewModel
    let userId: String
    let userName: String
    let userUsername: String
    
    @State private var showingDeleteAlert = false
    @State private var workoutToDelete: Workout?
    @State private var selectedWorkout: Workout?
    @StateObject private var gymRepository = GymRepository()
    
    // Computed personal records
    private var bestSquat: Int? {
        workouts(for: "squat").max(by: { $0.weight < $1.weight })?.weight
    }
    
    private var bestBench: Int? {
        workouts(for: "bench").max(by: { $0.weight < $1.weight })?.weight
    }
    
    private var bestDeadlift: Int? {
        workouts(for: "deadlift").max(by: { $0.weight < $1.weight })?.weight
    }
    
    // Stats
    private var totalWorkouts: Int {
        workoutViewModel.userWorkouts.count
    }
    
    private var totalWeight: Int {
        workoutViewModel.userWorkouts.reduce(0) { $0 + $1.weight }
    }
    
    private var totalUpvotes: Int {
        workoutViewModel.userWorkouts.reduce(0) { $0 + $1.upvotes }
    }
    
    private var favoriteLift: String {
        let liftCounts = Dictionary(grouping: workoutViewModel.userWorkouts, by: { $0.liftType })
        let mostFrequent = liftCounts.max { $0.value.count < $1.value.count }
        if let liftTypeString = mostFrequent?.key,
           let liftType = LiftType(rawValue: liftTypeString) {
            return liftType.displayName
        }
        return "N/A"
    }
    
    private var favoriteGym: (name: String, address: String?) {        let gymCounts = Dictionary(grouping: workoutViewModel.userWorkouts.compactMap { $0.gymId }, by: { $0 })
        let mostFrequentId = gymCounts.max { $0.value.count < $1.value.count }?.key
        
        if let gymId = mostFrequentId,
           let gym = gymRepository.gyms.first(where: { $0.id == gymId }) {
            return (name: gym.name, address: gym.location.address)
        }
        return (name: "N/A", address: nil)
    }
    
    private func workouts(for liftType: String) -> [Workout] {
        workoutViewModel.userWorkouts.filter { $0.liftType == liftType }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if workoutViewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading workouts...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                } else if workoutViewModel.userWorkouts.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "dumbbell")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary)
                        
                        Text("No Workouts Yet")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Start uploading workouts to see them here!")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Personal Records (S, B, D)
                            PersonalRecordsCard(
                                squat: bestSquat,
                                bench: bestBench,
                                deadlift: bestDeadlift
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            
                            // Overall Stats
                            OverallStatsCard(
                                totalWorkouts: totalWorkouts,
                                totalWeight: totalWeight,
                                totalUpvotes: totalUpvotes,
                                favoriteLift: favoriteLift,
                                favoriteGym: favoriteGym
                            )
                            .padding(.horizontal, 20)
                            
                            // Workout cards with delete
                            ForEach(workoutViewModel.userWorkouts) { workout in
                                WorkoutCardWithDelete(
                                    workout: workout,
                                    onTap: {
                                        selectedWorkout = workout
                                    },
                                    onDelete: {
                                        workoutToDelete = workout
                                        showingDeleteAlert = true
                                    }
                                )
                                .padding(.horizontal, 20)
                            }
                            
                            // Bottom padding
                            Color.clear.frame(height: 20)
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("My Workouts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .sheet(item: $selectedWorkout) { workout in
            WorkoutDetailView(workout: workout)
        }
        .alert("Delete Workout?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                workoutToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let workout = workoutToDelete {
                    deleteWorkout(workout)
                }
            }
        } message: {
            Text("This will permanently delete this workout. This action cannot be undone.")
        }
        .onAppear {
            Task {
                await gymRepository.fetchGyms()
                await workoutViewModel.fetchAllUserWorkouts(userId: userId)
            }
        }
    }
    
    private func deleteWorkout(_ workout: Workout) {
        Task {
            await workoutViewModel.deleteWorkout(workout)
            workoutToDelete = nil
        }
    }
}

// MARK: - Personal Records Card
struct PersonalRecordsCard: View {
    let squat: Int?
    let bench: Int?
    let deadlift: Int?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                    .font(.title3)
                
                Text("Personal Records")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                PRBox(
                    letter: "S",
                    weight: squat,
                    color: .green,
                    title: "Squat"
                )
                
                PRBox(
                    letter: "B",
                    weight: bench,
                    color: .blue,
                    title: "Bench"
                )
                
                PRBox(
                    letter: "D",
                    weight: deadlift,
                    color: .red,
                    title: "Deadlift"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct PRBox: View {
    let letter: String
    let weight: Int?
    let color: Color
    let title: String
    
    var body: some View {
        VStack(spacing: 8) {
            // Letter badge
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 50, height: 50)
                
                Text(letter)
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(.white)
            }
            
            // Weight
            if let weight = weight {
                Text("\(weight)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("lbs")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("—")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                Text("No PR")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Overall Stats Card
struct OverallStatsCard: View {
    let totalWorkouts: Int
    let totalWeight: Int
    let totalUpvotes: Int
    let favoriteLift: String
    let favoriteGym: (name: String, address: String?)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                Text("Overall Stats")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            // Two rows of stats
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    StatMiniBox(
                        title: "Workouts",
                        value: "\(totalWorkouts)",
                        icon: "number.circle.fill",
                        color: .blue
                    )
                    
                    StatMiniBox(
                        title: "Total Weight",
                        value: "\(totalWeight) lbs",
                        icon: "scalemass.fill",
                        color: .orange
                    )
                }
                
                HStack(spacing: 12) {
                    StatMiniBox(
                        title: "Upvotes",
                        value: "\(totalUpvotes)",
                        icon: "hand.thumbsup.fill",
                        color: .green
                    )
                    
                    StatMiniBox(
                        title: "Favorite Lift",
                        value: favoriteLift,
                        icon: "star.fill",
                        color: .purple
                    )
                }
                
                // Favorite gym (full width)
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.red)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Favorite Gym")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(favoriteGym.name)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .lineLimit(1)
                        
                        if let address = favoriteGym.address {
                            Text(address)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct StatMiniBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(title)
                    .font(.caption2)
            }
            .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Workout Card with Delete
struct WorkoutCardWithDelete: View {
    let workout: Workout
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with lift type and delete button
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
                    
                    // Delete button
                    Button(action: onDelete) {
                        Image(systemName: "trash.fill")
                            .font(.title3)
                            .foregroundColor(.red)
                            .padding(8)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Divider()
                
                // Stats
                HStack(spacing: 20) {
                    StatItem(icon: "eye.fill", value: "\(workout.views)", color: .secondary)
                    StatItem(icon: "hand.thumbsup.fill", value: "\(workout.upvotes)", color: .green)
                    StatItem(icon: "hand.thumbsdown.fill", value: "\(workout.downvotes)", color: .red)
                }
                
                // Date and status
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(workout.createdAt, style: .relative)
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(workout.statusEnum.displayName)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor(workout.statusEnum))
                        .cornerRadius(8)
                }
                
                // Tap to view details hint
                HStack {
                    Spacer()
                    Text("Tap for details")
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
        .buttonStyle(PlainButtonStyle())
    }
    
    private func statusColor(_ status: WorkoutStatus) -> Color {
        switch status {
        case .published: return .green
        case .pending: return .orange
        case .removed: return .red
        }
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
    }
}

#Preview {
    UserWorkoutsView(
        workoutViewModel: WorkoutViewModel(),
        userId: "user1",
        userName: "John Doe",
        userUsername: "johndoe"
    )
}
