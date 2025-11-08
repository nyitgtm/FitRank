import Foundation
import FirebaseFirestore

@MainActor
class VoteService: ObservableObject {
    static let shared = VoteService()
    private let db = Firestore.firestore()
    
    @Published var voteCounts: [String: (upvotes: Int, downvotes: Int)] = [:]
    @Published var userVotes: [String: VoteType] = [:] // workoutId -> voteType
    
    private init() {}
    
    // MARK: - Vote Management
    
    /// Toggle vote on a workout (upvote/downvote)
    func toggleVote(workoutId: String, userId: String, voteType: VoteType) async throws {
        let voteRef = db.collection("workouts").document(workoutId)
            .collection("votes").document(userId)
        
        let voteDoc = try await voteRef.getDocument()
        
        if voteDoc.exists {
            let existingVote = try voteDoc.data(as: Vote.self)
            
            // If clicking the same vote type, remove it
            if existingVote.voteTypeEnum == voteType {
                try await voteRef.delete()
                userVotes.removeValue(forKey: workoutId)
            } else {
                // Switch to different vote type
                let newVote = Vote(userId: userId, voteType: voteType)
                try voteRef.setData(from: newVote)
                userVotes[workoutId] = voteType
            }
        } else {
            // Create new vote
            let newVote = Vote(userId: userId, voteType: voteType)
            try voteRef.setData(from: newVote)
            userVotes[workoutId] = voteType
        }
        
        // Refresh vote counts
        await fetchVoteCounts(workoutId: workoutId)
    }
    
    /// Fetch vote counts for a workout
    func fetchVoteCounts(workoutId: String) async {
        do {
            let votesSnapshot = try await db.collection("workouts").document(workoutId)
                .collection("votes").getDocuments()
            
            var upvotes = 0
            var downvotes = 0
            
            for document in votesSnapshot.documents {
                let vote = try document.data(as: Vote.self)
                if vote.voteTypeEnum == .upvote {
                    upvotes += 1
                } else {
                    downvotes += 1
                }
            }
            
            voteCounts[workoutId] = (upvotes, downvotes)
        } catch {
            print("Error fetching vote counts: \(error)")
        }
    }
    
    /// Fetch user's vote for a specific workout
    func fetchUserVote(workoutId: String, userId: String) async {
        do {
            let voteDoc = try await db.collection("workouts").document(workoutId)
                .collection("votes").document(userId).getDocument()
            
            if voteDoc.exists {
                let vote = try voteDoc.data(as: Vote.self)
                userVotes[workoutId] = vote.voteTypeEnum
            } else {
                userVotes.removeValue(forKey: workoutId)
            }
        } catch {
            print("Error fetching user vote: \(error)")
        }
    }
    
    /// Fetch multiple workout vote counts at once
    func fetchMultipleVoteCounts(workoutIds: [String]) async {
        await withTaskGroup(of: Void.self) { group in
            for workoutId in workoutIds {
                group.addTask {
                    await self.fetchVoteCounts(workoutId: workoutId)
                }
            }
        }
    }
    
    /// Get net vote score (upvotes - downvotes)
    func getNetScore(workoutId: String) -> Int {
        guard let counts = voteCounts[workoutId] else { return 0 }
        return counts.upvotes - counts.downvotes
    }
    
    /// Get form rating (0.0 to 1.0)
    func getFormRating(workoutId: String) -> Double {
        guard let counts = voteCounts[workoutId] else { return 0.0 }
        let total = counts.upvotes + counts.downvotes
        guard total > 0 else { return 0.0 }
        return Double(counts.upvotes) / Double(total)
    }
}
