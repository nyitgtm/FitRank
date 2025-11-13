import Foundation
import FirebaseAuth
import Combine

@MainActor
class RatingViewModel: ObservableObject {
    @Published var userRatings: [String: RatingValue] = [:] // workoutId: rating
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firebaseService = FirebaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Rating Management
    
    func rateWorkout(workoutId: String, rating: RatingValue) async {
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = "User not authenticated"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Check if user already rated this workout
            if let existingRating = userRatings[workoutId] {
                if existingRating == rating {
                    // User is trying to rate the same way again, remove the rating
                    await removeRating(workoutId: workoutId)
                    return
                } else {
                    // User is changing their rating, remove the old one first
                    await removeRating(workoutId: workoutId)
                }
            }
            
            // Create new rating
            let newRating = Rating(
                userID: currentUser.uid,
                workoutId: workoutId,
                value: rating
            )
            
            try await firebaseService.createRating(newRating)
            
            // Update local state
            userRatings[workoutId] = rating
            
        } catch {
            errorMessage = "Failed to rate workout: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func removeRating(workoutId: String) async {
        // In a real implementation, you might want to store the rating ID
        // and delete it from Firestore. For now, we'll just remove it locally.
        userRatings.removeValue(forKey: workoutId)
    }
    
    // MARK: - Rating Queries
    
    func getUserRating(for workoutId: String) async {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        do {
            let rating = try await firebaseService.getUserRating(
                userId: currentUser.uid,
                workoutId: workoutId
            )
            
            if let rating = rating {
                userRatings[workoutId] = rating.value
            } else {
                userRatings.removeValue(forKey: workoutId)
            }
        } catch {
            print("Failed to get user rating: \(error.localizedDescription)")
        }
    }
    
    func getUserRatings(for workoutIds: [String]) async {
        await withTaskGroup(of: Void.self) { group in
            for workoutId in workoutIds {
                group.addTask {
                    await self.getUserRating(for: workoutId)
                }
            }
        }
    }
    
    // MARK: - Rating Statistics (Legacy - use VoteService instead)
    
    func getRatingStats(for workout: Workout) -> (upvotes: Int, downvotes: Int, totalVotes: Int, formRating: Double) {
        // Note: Stats now tracked in votes subcollection
        // This method is deprecated, use VoteService.shared instead
        return (0, 0, 0, 0.0)
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
}

