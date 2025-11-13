import SwiftUI

struct VoteCounts: Equatable {
    let upvotes: Int
    let downvotes: Int
}

struct CompactWorkoutCard: View {
    let workout: Workout
    let onTap: () -> Void
    
    @StateObject private var voteService = VoteService.shared
    @State private var voteCounts: VoteCounts = VoteCounts(upvotes: 0, downvotes: 0)
    
    private var observedVoteCounts: VoteCounts? {
        guard let counts = voteService.voteCounts[workout.id ?? ""] else { return nil }
        return VoteCounts(upvotes: counts.upvotes, downvotes: counts.downvotes)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
            // Lift type icon and weight
            HStack(spacing: 8) {
                Image(systemName: workout.liftTypeEnum.icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.blue.opacity(0.1)))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(workout.liftTypeEnum.displayName)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("\(workout.weight) lbs")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
            
            Divider()
            
            // Stats row (now with actual vote data)
            HStack(spacing: 16) {
                StatPill(icon: "eye.fill", value: "\(workout.views)", color: .secondary)
                StatPill(icon: "hand.thumbsup.fill", value: "\(voteCounts.upvotes)", color: .green)
                StatPill(icon: "hand.thumbsdown.fill", value: "\(voteCounts.downvotes)", color: .red)
            }
            
            Spacer() // is this too much space, i think it looks fine lwk
            
            // Time stamp
            HStack {
                Image(systemName: "clock")
                    .font(.caption2)
                Text(workout.createdAt, style: .relative)
                    .font(.caption2)
                Spacer()
                
                // Status badge
                Text(workout.statusEnum.displayName)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(workout.statusEnum))
                    .cornerRadius(8)
            }
            .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(width: 220, height: 200)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        }
        .buttonStyle(PlainButtonStyle())
        .task {
            // Load vote counts when card appears
            if let workoutId = workout.id {
                await voteService.fetchVoteCounts(workoutId: workoutId)
                if let counts = voteService.voteCounts[workoutId] {
                    voteCounts = VoteCounts(upvotes: counts.upvotes, downvotes: counts.downvotes)
                }
            }
        }
        .onChange(of: observedVoteCounts) { _, newValue in
            // Update when vote counts change
            if let newValue = newValue {
                voteCounts = newValue
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

struct StatPill: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    CompactWorkoutCard(workout: Workout(
        userId: "user1",
        teamId: "/teams/0",
        videoUrl: "https://example.com/video.mp4",
        weight: 225,
        liftType: "bench",
        gymId: "gym1",
        status: "published"
    ), onTap: {})
    .padding()
}
