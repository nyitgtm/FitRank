import Foundation
import FirebaseFirestore
import FirebaseAuth

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - User Operations
    
    func createUser(_ user: User) async throws {
        guard let userId = user.id else {
            throw FirebaseError.invalidUserId
        }
        
        try await db.collection("users").document(userId).setData(from: user)
    }
    
    func getUser(userId: String) async throws -> User {
        let document = try await db.collection("users").document(userId).getDocument()
        guard let user = try? document.data(as: User.self) else {
            throw FirebaseError.decodingError
        }
        return user
    }
    
    func updateUser(_ user: User) async throws {
        guard let userId = user.id else {
            throw FirebaseError.invalidUserId
        }
        
        try await db.collection("users").document(userId).setData(from: user)
    }
    
    func checkUsernameAvailability(_ username: String) async throws -> Bool {
        let snapshot = try await db.collection("users")
            .whereField("username", isEqualTo: username)
            .getDocuments()
        
        return snapshot.documents.isEmpty
    }
    
    // MARK: - Workout Operations
    
    func createWorkout(_ workout: Workout) async throws -> String {
        let documentRef = try await db.collection("workouts").addDocument(from: workout)
        return documentRef.documentID
    }
    
    func getWorkouts(limit: Int = 50) async throws -> [Workout] {
        let snapshot = try await db.collection("workouts")
            .whereField("status", isEqualTo: WorkoutStatus.published.rawValue)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try document.data(as: Workout.self)
        }
    }
    
    func getWorkoutsByTeam(teamId: String, limit: Int = 50) async throws -> [Workout] {
        let snapshot = try await db.collection("workouts")
            .whereField("teamId", isEqualTo: teamId)
            .whereField("status", isEqualTo: WorkoutStatus.published.rawValue)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try document.data(as: Workout.self)
        }
    }
    
    func getWorkout(workoutId: String) async throws -> Workout {
        let document = try await db.collection("workouts").document(workoutId).getDocument()
        guard let workout = try? document.data(as: Workout.self) else {
            throw FirebaseError.decodingError
        }
        return workout
    }
    
    func updateWorkout(_ workout: Workout) async throws {
        guard let workoutId = workout.id else {
            throw FirebaseError.invalidWorkoutId
        }
        
        try await db.collection("workouts").document(workoutId).setData(from: workout)
    }
    
    func deleteWorkout(workoutId: String) async throws {
        try await db.collection("workouts").document(workoutId).delete()
    }
    
    // MARK: - Rating Operations
    
    func createRating(_ rating: Rating) async throws {
        // Check if user already rated this workout
        let existingRating = try await getUserRating(userId: rating.userID, workoutId: rating.workoutId)
        if existingRating != nil {
            throw FirebaseError.duplicateRating
        }
        
        try await db.collection("ratings").addDocument(from: rating)
        
        // Update workout vote counts
        try await updateWorkoutVotes(workoutId: rating.workoutId, ratingValue: rating.value)
    }
    
    func getUserRating(userId: String, workoutId: String) async throws -> Rating? {
        let snapshot = try await db.collection("ratings")
            .whereField("userID", isEqualTo: userId)
            .whereField("workoutId", isEqualTo: workoutId)
            .getDocuments()
        
        return try snapshot.documents.first?.data(as: Rating.self)
    }
    
    private func updateWorkoutVotes(workoutId: String, ratingValue: RatingValue) async throws {
        let workoutRef = db.collection("workouts").document(workoutId)
        
        // Get current workout data
        let workoutDoc = try await workoutRef.getDocument()
        guard var workout = try? workoutDoc.data(as: Workout.self) else {
            throw FirebaseError.decodingError
        }
        
        // Update vote counts
        if ratingValue == .upvote {
            workout.upvotes += 1
        } else {
            workout.downvotes += 1
        }
        
        // Save updated workout
        try await workoutRef.setData(from: workout)
    }
    
    // MARK: - Comment Operations
    
    func createComment(_ comment: Comment) async throws {
        try await db.collection("comments").addDocument(from: comment)
    }
    
    func getComments(workoutId: String) async throws -> [Comment] {
        let snapshot = try await db.collection("comments")
            .whereField("workoutID", isEqualTo: workoutId)
            .order(by: "timestamp", descending: false)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try document.data(as: Comment.self)
        }
    }
    
    func deleteComment(commentId: String) async throws {
        try await db.collection("comments").document(commentId).delete()
    }
    
    // MARK: - Gym Operations
    
    func fetchGyms() async throws -> [Gym] {
        let snapshot = try await db.collection("gyms").getDocuments()
        return try snapshot.documents.compactMap { document in
            try document.data(as: Gym.self)
        }
    }
    
    func getGym(id: String) async throws -> Gym? {
        let document = try await db.collection("gyms").document(id).getDocument()
        return try? document.data(as: Gym.self)
    }
    
    func createGym(_ gym: Gym) async throws {
        try await db.collection("gyms").addDocument(from: gym)
    }
    
    func updateGym(_ gym: Gym) async throws {
        guard let id = gym.id else { throw FirebaseError.invalidDocument }
        try await db.collection("gyms").document(id).setData(from: gym)
    }
    
    func deleteGym(id: String) async throws {
        try await db.collection("gyms").document(id).delete()
    }
    
    // MARK: - Report Operations
    
    func createReport(_ report: Report) async throws {
        try await db.collection("reports").addDocument(from: report)
    }
    
    func getReports(status: ReportStatus? = nil) async throws -> [Report] {
        let query: Query
        
        if let status = status {
            query = db.collection("reports").whereField("status", isEqualTo: status.rawValue)
        } else {
            query = db.collection("reports")
        }
        
        let snapshot = try await query
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try document.data(as: Report.self)
        }
    }
    
    func updateReportStatus(reportId: String, status: ReportStatus) async throws {
        try await db.collection("reports").document(reportId).updateData([
            "status": status.rawValue
        ])
    }
    
    // MARK: - Storage Operations (Mock Implementation)
    
    func uploadVideo(url: URL, fileName: String) async throws -> String {
        // Mock implementation - return a fake URL for now
        // In production, this would use Firebase Storage
        return "https://example.com/videos/\(fileName)"
    }
    
    func deleteVideo(fileName: String) async throws {
        // Mock implementation - no actual deletion for now
        print("Mock: Deleting video \(fileName)")
    }
}

// MARK: - Firebase Errors

enum FirebaseError: Error, LocalizedError {
    case invalidUserId
    case invalidWorkoutId
    case duplicateRating
    case decodingError
    case networkError
    case permissionDenied
    case invalidDocument
    
    var errorDescription: String? {
        switch self {
        case .invalidUserId:
            return "Invalid user ID"
        case .invalidWorkoutId:
            return "Invalid workout ID"
        case .duplicateRating:
            return "You have already rated this workout"
        case .decodingError:
            return "Failed to decode data"
        case .networkError:
            return "Network error occurred"
        case .permissionDenied:
            return "Permission denied"
        case .invalidDocument:
            return "Invalid document ID"
        }
    }
}
