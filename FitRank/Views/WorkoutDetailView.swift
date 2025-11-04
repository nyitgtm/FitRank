import SwiftUI

struct WorkoutDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var gymRepository = GymRepository()
    @StateObject private var teamRepository = TeamRepository()
    @StateObject private var userRepository = UserRepository()
    let workout: Workout
    
    @State private var workoutUser: User?
    
    private var gymName: String {
        if let gymId = workout.gymId,
           let gym = gymRepository.gyms.first(where: { $0.id == gymId }) {
            return gym.name
        }
        return "Unknown Gym"
    }
    
    private var gymAddress: String? {
        if let gymId = workout.gymId,
           let gym = gymRepository.gyms.first(where: { $0.id == gymId }) {
            return gym.location.address
        }
        return nil
    }
    
    private var teamName: String {
        if let team = teamRepository.getTeam(byReference: workout.teamId) {
            return team.name
        }
        return "Unknown Team"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Video Player
                    VideoPlayerView(videoURL: workout.videoUrl)
                        .frame(height: 400)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                    
                    // Main info card
                    VStack(spacing: 16) {
                        // Lift type with icon
                        HStack {
                            Image(systemName: workout.liftTypeEnum.icon)
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(workout.liftTypeEnum.displayName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("\(workout.weight) lbs")
                                    .font(.system(size: 36, weight: .black, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                            
                            Spacer()
                        }
                        
                        Divider()
                        
                        // Status badge
                        HStack {
                            Text("Status")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(workout.statusEnum.displayName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(statusColor(workout.statusEnum))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    
                    // Engagement stats
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(.orange)
                            Text("Engagement")
                                .font(.headline)
                                .fontWeight(.bold)
                            Spacer()
                        }
                        
                        HStack(spacing: 12) {
                            EngagementBox(
                                icon: "eye.fill",
                                label: "Views",
                                value: "\(workout.views)",
                                color: .gray
                            )
                            
                            EngagementBox(
                                icon: "hand.thumbsup.fill",
                                label: "Upvotes",
                                value: "\(workout.upvotes)",
                                color: .green
                            )
                            
                            EngagementBox(
                                icon: "hand.thumbsdown.fill",
                                label: "Downvotes",
                                value: "\(workout.downvotes)",
                                color: .red
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    
                    // Location info
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                            Text("Location")
                                .font(.headline)
                                .fontWeight(.bold)
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            DetailRow(
                                label: "Gym",
                                value: gymName,
                                icon: "building.2.fill"
                            )
                            
                            if let address = gymAddress {
                                DetailRow(
                                    label: "Address",
                                    value: address,
                                    icon: "location.fill"
                                )
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    
                    // Team & User info
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "person.3.fill")
                                .foregroundColor(.purple)
                            Text("Team & User")
                                .font(.headline)
                                .fontWeight(.bold)
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            DetailRow(
                                label: "Username",
                                value: workoutUser?.username ?? "Loading...",
                                icon: "person.fill"
                            )
                            
                            DetailRow(
                                label: "Name",
                                value: workoutUser?.name ?? "Loading...",
                                icon: "person.text.rectangle"
                            )
                            
                            DetailRow(
                                label: "Team",
                                value: teamName,
                                icon: "flag.fill"
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    
                    // Technical info
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("Technical Info")
                                .font(.headline)
                                .fontWeight(.bold)
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            if let workoutId = workout.id {
                                DetailRow(
                                    label: "Workout ID",
                                    value: workoutId,
                                    icon: "number"
                                )
                            }
                            
                            DetailRow(
                                label: "Video URL",
                                value: workout.videoUrl,
                                icon: "video.fill"
                            )
                            
                            DetailRow(
                                label: "Created",
                                value: workout.createdAt.formatted(date: .long, time: .shortened),
                                icon: "clock.fill"
                            )
                            
                            DetailRow(
                                label: "Time Ago",
                                value: workout.createdAt.formatted(.relative(presentation: .named)),
                                icon: "calendar"
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Workout Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .task {
            await gymRepository.fetchGyms()
            await teamRepository.fetchTeams()
            // Fetch user info
            do {
                workoutUser = try await userRepository.getUser(uid: workout.userId)
            } catch {
                print("Error fetching user: \(error)")
            }
        }
    }
    
    private func statusColor(_ status: WorkoutStatus) -> Color {
        switch status {
        case .published: return .green
        case .pending: return .orange
        case .removed: return .red
        }
    }
}

// MARK: - Components

struct EngagementBox: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
                .textSelection(.enabled)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    WorkoutDetailView(workout: Workout(
        id: "workout123",
        userId: "user456",
        teamId: "/teams/0",
        videoUrl: "https://example.com/video.mp4",
        weight: 225,
        liftType: "bench",
        gymId: "gym789",
        status: "published"
    ))
}
