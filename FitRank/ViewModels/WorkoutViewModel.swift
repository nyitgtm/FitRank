import Foundation
import CoreLocation
import FirebaseAuth

@MainActor
class WorkoutViewModel: ObservableObject {
    @Published var workouts: [Workout] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firebaseService = FirebaseService.shared
    private let userViewModel = UserViewModel()
    
    // MARK: - Mock Data for Development
    
    private func generateMockWorkouts() -> [Workout] {
        return [
            Workout(
                userId: "user1",
                teamId: "/teams/0",
                videoUrl: "https://example.com/videos/workout1.mp4",
                weight: 225,
                liftType: .bench,
                gymId: "gIlZvXqqfaj3qdCfAUns"
            ),
            Workout(
                userId: "user2",
                teamId: "/teams/1",
                videoUrl: "https://example.com/videos/workout2.mp4",
                weight: 315,
                liftType: .squat,
                gymId: "gIlZvXqqfaj3qdCfAUns"
            ),
            Workout(
                userId: "user3",
                teamId: "/teams/2",
                videoUrl: "https://example.com/videos/workout3.mp4",
                weight: 405,
                liftType: .deadlift,
                gymId: "gIlZvXqqfaj3qdCfAUns"
            )
        ]
    }
    
    func fetchWorkouts() {
        isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.workouts = self.generateMockWorkouts()
            self.isLoading = false
        }
    }
    
    // MARK: - Workout Creation
    
    func createWorkout(weight: Int, liftType: String, gymId: String, videoURL: URL) async {
        isLoading = true
        errorMessage = nil
        
        // Convert string to LiftType enum
        let liftTypeEnum: LiftType
        switch liftType {
        case "Bench Press": liftTypeEnum = .bench
        case "Squat": liftTypeEnum = .squat
        case "Deadlift": liftTypeEnum = .deadlift
        default: liftTypeEnum = .bench
        }
        
        do {
            let workout = Workout(
                userId: userViewModel.currentUser?.id ?? "",
                teamId: userViewModel.currentUser?.team ?? "/teams/0",
                videoUrl: videoURL.absoluteString,
                weight: weight,
                liftType: liftTypeEnum,
                gymId: gymId
            )
            
            try await firebaseService.createWorkout(workout)
            await fetchWorkouts()
        } catch {
            errorMessage = "Failed to create workout: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
