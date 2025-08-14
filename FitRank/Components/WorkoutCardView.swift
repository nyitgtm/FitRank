import SwiftUI

// MARK: - Helper Views

struct TeamBadgeView: View {
    let team: String
    @StateObject private var teamRepository = TeamRepository()
    
    private func getTeamColor(_ team: String) -> Color {
        if let teamData = teamRepository.getTeam(byReference: team) {
            return Color(hex: teamData.color) ?? .gray
        }
        return .gray
    }
    
    private func getTeamName(_ team: String) -> String {
        if let teamData = teamRepository.getTeam(byReference: team) {
            return teamData.name
        }
        return "Unknown Team"
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(getTeamColor(team))
                .frame(width: 8, height: 8)
            
            Text(getTeamName(team))
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(getTeamColor(team).opacity(0.1))
        .cornerRadius(8)
        .onAppear {
            Task {
                await teamRepository.fetchTeams()
            }
        }
    }
}

struct StatusBadgeView: View {
    let status: WorkoutStatus
    
    private var statusColor: Color {
        switch status {
        case .published: return .green
        case .pending: return .orange
        case .removed: return .red
        }
    }
    
    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor)
            .cornerRadius(8)
    }
}

struct VideoPlaceholderView: View {
    let videoURL: String
    
    var body: some View {
        // For now, show a placeholder since we don't have actual video playback
        VStack(spacing: 12) {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("Video Available")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Tap to play")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGray6))
    }
}

// MARK: - Main View

struct WorkoutCardView: View {
    let workout: Workout
    
    // Mock user data for development
    private var userName: String {
        switch workout.userId {
        case "user1": return "Fitrank Control"
        case "user2": return "John Doe"
        case "user3": return "Jane Smith"
        default: return "Unknown User"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with user info and team
            HStack {
                TeamBadgeView(team: workout.teamId)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(userName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(workout.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status badge
                StatusBadgeView(status: workout.status)
            }
            
            // Video placeholder
            VideoPlaceholderView(videoURL: workout.videoUrl)
                .frame(height: 200)
                .cornerRadius(12)
            
            // Workout details
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.liftType.displayName)
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text("\(workout.weight) lbs")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    // Stats
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: "eye.fill")
                                .foregroundColor(.secondary)
                            Text("\(workout.views)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 8) {
                            Image(systemName: "hand.thumbsup.fill")
                                .foregroundColor(.green)
                            Text("\(workout.upvotes)")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        
                        HStack(spacing: 8) {
                            Image(systemName: "hand.thumbsdown.fill")
                                .foregroundColor(.red)
                            Text("\(workout.downvotes)")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Action buttons
                HStack(spacing: 16) {
                    Button {
                        // Like functionality
                    } label: {
                        HStack {
                            Image(systemName: "hand.thumbsup")
                            Text("Like")
                        }
                        .foregroundColor(.green)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(20)
                    }
                    
                    Button {
                        // Comment functionality
                    } label: {
                        HStack {
                            Image(systemName: "bubble.left")
                            Text("Comment")
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(20)
                    }
                    
                    Spacer()
                    
                    Button {
                        // Report functionality
                    } label: {
                        Image(systemName: "flag")
                            .foregroundColor(.red)
                            .padding(8)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(20)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    WorkoutCardView(workout: Workout(
        userId: "user1",
        teamId: "/teams/0",
        videoUrl: "https://example.com/video.mp4",
        weight: 225,
        liftType: .bench,
        gymId: "gym1"
    ))
}
