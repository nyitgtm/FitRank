import Foundation
import FirebaseFirestore

struct Workout: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String // Reference to User.id
    var createdAt: Date
    var teamId: String // Reference to team ID
    var videoUrl: String // Link to video in Firebase Storage
    var weight: Int // Weight in whole lbs
    var liftType: String // Stored as string in Firestore: "bench", "squat", "deadlift"
    var gymId: String? // Reference to gym ID, optional
    var status: String // Stored as string: "pending", "published", "removed"
    var views: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case createdAt
        case teamId
        case videoUrl
        case weight
        case liftType
        case gymId
        case status
        case views
    }
    
    init(id: String? = nil, userId: String, teamId: String, videoUrl: String, weight: Int, liftType: String, gymId: String? = nil, status: String = "pending") {
        self.id = id
        self.userId = userId
        self.createdAt = Date()
        self.teamId = teamId
        self.videoUrl = videoUrl
        self.weight = weight
        self.liftType = liftType
        self.gymId = gymId
        self.status = status
        self.views = 0
    }
    
    // Computed property for lift type enum
    var liftTypeEnum: LiftType {
        return LiftType(rawValue: liftType) ?? .bench
    }
    
    // Computed property for status enum
    var statusEnum: WorkoutStatus {
        return WorkoutStatus(rawValue: status) ?? .pending
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
