import SwiftUI

struct UserWorkoutsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var workoutViewModel: WorkoutViewModel
    let userId: String
    let userName: String
    
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
                            // Stats header
                            WorkoutStatsHeader(workouts: workoutViewModel.userWorkouts)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                            
                            // Workout cards
                            ForEach(workoutViewModel.userWorkouts) { workout in
                                WorkoutCardView(workout: workout)
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
        .onAppear {
            Task {
                await workoutViewModel.fetchAllUserWorkouts(userId: userId)
            }
        }
    }
}

// Stats header showing aggregate info
struct WorkoutStatsHeader: View {
    let workouts: [Workout]
    
    private var totalWorkouts: Int {
        workouts.count
    }
    
    private var totalWeight: Int {
        workouts.reduce(0) { $0 + $1.weight }
    }
    
    private var totalUpvotes: Int {
        workouts.reduce(0) { $0 + $1.upvotes }
    }
    
    private var favoriteLift: String {
        let liftCounts = Dictionary(grouping: workouts, by: { $0.liftType })
        let mostFrequent = liftCounts.max { $0.value.count < $1.value.count }
        if let liftTypeString = mostFrequent?.key,
           let liftType = LiftType(rawValue: liftTypeString) {
            return liftType.displayName
        }
        return "N/A"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                StatBox(
                    title: "Total",
                    value: "\(totalWorkouts)",
                    icon: "number.circle.fill",
                    color: .blue
                )
                
                StatBox(
                    title: "Weight Lifted",
                    value: "\(totalWeight) lbs",
                    icon: "scalemass.fill",
                    color: .orange
                )
            }
            
            HStack(spacing: 12) {
                StatBox(
                    title: "Upvotes",
                    value: "\(totalUpvotes)",
                    icon: "hand.thumbsup.fill",
                    color: .green
                )
                
                StatBox(
                    title: "Favorite",
                    value: favoriteLift,
                    icon: "star.fill",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    UserWorkoutsView(
        workoutViewModel: WorkoutViewModel(),
        userId: "user1",
        userName: "John Doe"
    )
}
