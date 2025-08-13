import Foundation
import FirebaseFirestore

struct Gym: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var name: String
    var location: Location
    var bestSquatId: String? // Reference to workout document
    var bestBenchId: String? // Reference to workout document
    var bestDeadliftId: String? // Reference to workout document
    var ownerTeamId: String? // Reference to team document (e.g., "/teams/0")
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case location
        case bestSquatId
        case bestBenchId
        case bestDeadliftId
        case ownerTeamId
    }
}

struct Location: Codable, Equatable {
    let address: String?
    let lat: Double
    let lon: Double
}

struct LiftRecord: Codable, Equatable {
    let workoutId: String
    let weight: Int
    let userId: String
    let timestamp: Date
}
