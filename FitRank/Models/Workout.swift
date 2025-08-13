import Foundation
import FirebaseFirestore

struct Workout: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String // Reference to User.id
    var createdAt: Date
    var teamId: String // Reference to team ID
    var videoUrl: String // Link to video in Firebase Storage
    var weight: Int // Weight in whole lbs
    var liftType: LiftType
    var gymId: String? // Reference to gym ID, optional
    var status: WorkoutStatus
    var views: Int
    var upvotes: Int
    var downvotes: Int
    var location: Location? // GPS coordinates
    
    init(id: String? = nil, userId: String, teamId: String, videoUrl: String, weight: Int, liftType: LiftType, gymId: String? = nil, location: Location? = nil) {
        self.id = id
        self.userId = userId
        self.createdAt = Date()
        self.teamId = teamId
        self.videoUrl = videoUrl
        self.weight = weight
        self.liftType = liftType
        self.gymId = gymId
        self.status = .pending
        self.views = 0
        self.upvotes = 0
        self.downvotes = 0
        self.location = location
    }
    
    // Computed property for form rating
    var formRating: Double {
        let totalVotes = upvotes + downvotes
        guard totalVotes > 0 else { return 0.0 }
        return Double(upvotes - downvotes) / Double(totalVotes)
    }
    
    // Computed property for total votes
    var totalVotes: Int {
        return upvotes + downvotes
    }
}

// Lift types enum
enum LiftType: String, CaseIterable, Identifiable, Codable {
    case bench = "bench"
    case squat = "squat"
    case deadlift = "deadlift"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .bench: return "Bench Press"
        case .squat: return "Squat"
        case .deadlift: return "Deadlift"
        }
    }
    
    var icon: String {
        switch self {
        case .bench: return "figure.strengthtraining.traditional"
        case .squat: return "figure.walk"
        case .deadlift: return "figure.strengthtraining.functional"
        }
    }
}

// Workout status enum
enum WorkoutStatus: String, CaseIterable, Identifiable, Codable {
    case published = "published"
    case pending = "pending"
    case removed = "removed"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .published: return "Published"
        case .pending: return "Pending Review"
        case .removed: return "Removed"
        }
    }
    
    var color: String {
        switch self {
        case .published: return "green"
        case .pending: return "orange"
        case .removed: return "red"
        }
    }
}
