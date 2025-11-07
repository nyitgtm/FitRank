import Foundation
import CoreLocation
import FirebaseAuth

@MainActor
class WorkoutViewModel: ObservableObject {
    @Published var workouts: [Workout] = []
    @Published var userWorkouts: [Workout] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firebaseService = FirebaseService.shared
    private let userViewModel = UserViewModel()
    private let dailyTasksService = DailyTasksService.shared
    
    // MARK: - Mock Data for Development
    
    private func generateMockWorkouts() -> [Workout] {
        return [
            Workout(
                userId: "user1",
                teamId: "/teams/0",
                videoUrl: "https://example.com/videos/workout1.mp4",
                weight: 225,
                liftType: "bench",
                gymId: "gIlZvXqqfaj3qdCfAUns",
                status: "published"
            ),
            Workout(
                userId: "user2",
                teamId: "/teams/1",
                videoUrl: "https://example.com/videos/workout2.mp4",
                weight: 315,
                liftType: "squat",
                gymId: "gIlZvXqqfaj3qdCfAUns",
                status: "published"
            ),
            Workout(
                userId: "user3",
                teamId: "/teams/2",
                videoUrl: "https://example.com/videos/workout3.mp4",
                weight: 405,
                liftType: "deadlift",
                gymId: "gIlZvXqqfaj3qdCfAUns",
                status: "published"
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
    
    // MARK: - User-Specific Workouts
    
    func fetchUserWorkouts(userId: String, limit: Int? = nil) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedWorkouts = try await firebaseService.getWorkoutsByUser(userId: userId, limit: limit)
            userWorkouts = fetchedWorkouts
        } catch {
            errorMessage = "Failed to fetch workouts: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func fetchTop3UserWorkouts(userId: String) async {
        await fetchUserWorkouts(userId: userId, limit: 3)
    }
    
    func fetchAllUserWorkouts(userId: String) async {
        await fetchUserWorkouts(userId: userId, limit: nil)
    }
    
    // MARK: - Delete Workout
    
    func deleteWorkout(_ workout: Workout) async {
        guard let workoutId = workout.id else { return }
        
        do {
            try await firebaseService.deleteWorkout(workoutId: workoutId)
            // Remove from local array
            userWorkouts.removeAll { $0.id == workoutId }
        } catch {
            errorMessage = "Failed to delete workout: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Workout Creation
    
    func createWorkout(weight: Int, liftType: String, gymId: String, videoURL: URL) async {
        isLoading = true
        errorMessage = nil
        
        // Convert display name to liftType string
        let liftTypeString: String
        switch liftType {
        case "Bench Press": liftTypeString = "bench"
        case "Squat": liftTypeString = "squat"
        case "Deadlift": liftTypeString = "deadlift"
        default: liftTypeString = "bench"
        }
        
        do {
            let workout = Workout(
                userId: userViewModel.currentUser?.id ?? "",
                teamId: userViewModel.currentUser?.team ?? "/teams/0",
                videoUrl: videoURL.absoluteString,
                weight: weight,
                liftType: liftTypeString,
                gymId: gymId,
                status: "pending"
            )
            
            try await firebaseService.createWorkout(workout)
            
            // ✅ TRACK UPLOAD FOR DAILY TASK
            if let userId = Auth.auth().currentUser?.uid {
                do {
                    let result = try await dailyTasksService.trackUpload(userId: userId)
                    print("✅ Upload tracked! Progress: \(result.newCount)/\(DailyTasks.maxUploads)")
                    
                    if result.maxed {
                        print("🎉 Upload task complete! Go claim your 100 coins!")
                    }
                } catch {
                    print("Failed to track upload: \(error)")
                    // Don't fail the workout creation if tracking fails
                }
            }
            
            await fetchWorkouts()
        } catch {
            errorMessage = "Failed to create workout: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
