import SwiftUI

struct MyWorkoutsSection: View {
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @ObservedObject var userViewModel: UserViewModel
    @State private var showingAllWorkouts = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                Text("My Recent Workouts")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                if !workoutViewModel.userWorkouts.isEmpty {
                    Button {
                        showingAllWorkouts = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("View All")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Content
            if workoutViewModel.isLoading {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Loading workouts...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 40)
                    Spacer()
                }
            } else if workoutViewModel.userWorkouts.isEmpty {
                EmptyWorkoutsCard()
                    .padding(.horizontal, 20)
            } else {
                // Show top 3 workouts
                VStack(spacing: 16) {
                    ForEach(workoutViewModel.userWorkouts) { workout in
                        WorkoutCardView(workout: workout)
                            .padding(.horizontal, 20)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingAllWorkouts) {
            if let userId = userViewModel.currentUser?.id {
                UserWorkoutsView(
                    workoutViewModel: workoutViewModel,
                    userId: userId,
                    userName: userViewModel.currentUser?.name ?? "User"
                )
            }
        }
        .onAppear {
            if let userId = userViewModel.currentUser?.id {
                Task {
                    await workoutViewModel.fetchTop3UserWorkouts(userId: userId)
                }
            }
        }
        .onChange(of: userViewModel.currentUser?.id) { oldValue, newValue in
            if let userId = newValue {
                Task {
                    await workoutViewModel.fetchTop3UserWorkouts(userId: userId)
                }
            }
        }
    }
}

struct EmptyWorkoutsCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Workouts Yet")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Upload your first workout to get started!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

#Preview {
    MyWorkoutsSection(
        workoutViewModel: WorkoutViewModel(),
        userViewModel: UserViewModel()
    )
}
