import SwiftUI

struct UserWorkoutsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var workoutViewModel: WorkoutViewModel
    let userId: String
    let userName: String
    let userUsername: String
    
    @State private var showingDeleteAlert = false
    @State private var workoutToDelete: Workout?
    
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
                            // User info header
                            UserInfoHeader(name: userName, username: userUsername)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                            
                            // Personal Records (S, B, D)
                            PersonalRecordsCard(
                                squat: bestSquat,
                                bench: bestBench,
                                deadlift: bestDeadlift
                            )
                            .padding(.horizontal, 20)
                            
                            // Workout cards with delete
                            ForEach(workoutViewModel.userWorkouts) { workout in
                                WorkoutCardWithDelete(
                                    workout: workout,
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

// MARK: - User Info Header
struct UserInfoHeader: View {
    let name: String
    let username: String
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile icon
            Circle()
                .fill(LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.white)
                        .font(.title3)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text("@\(username)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
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

// MARK: - Workout Card with Delete
struct WorkoutCardWithDelete: View {
    let workout: Workout
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with lift type and delete button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.liftTypeEnum.displayName)
                        .font(.headline)
                        .fontWeight(.bold)
                    
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
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
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
