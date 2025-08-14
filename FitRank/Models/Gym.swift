import Foundation
import FirebaseFirestore

struct Gym: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var name: String
    var location: Location
    var bestSquatId: String? // Reference to workout document
    var bestBenchId: String? // Reference to workout document
    var bestDeadliftId: String? // Reference to workout document
    var ownerTeamId: String? // Will be extracted from DocumentReference
    
    // Custom coding keys to handle DocumentReference
    enum CodingKeys: String, CodingKey {
        case id, name, location, bestSquatId, bestBenchId, bestDeadliftId, ownerTeamId
    }
    
    // Custom decoder to handle DocumentReference
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try container.decode(String.self, forKey: .name)
        location = try container.decode(Location.self, forKey: .location)
        bestSquatId = try container.decodeIfPresent(String.self, forKey: .bestSquatId)
        bestBenchId = try container.decodeIfPresent(String.self, forKey: .bestBenchId)
        bestDeadliftId = try container.decodeIfPresent(String.self, forKey: .bestDeadliftId)
        
        // Handle ownerTeamId - try different approaches
        if let teamRef = try? container.decode(DocumentReference.self, forKey: .ownerTeamId) {
            // If it's a DocumentReference, extract the document ID
            ownerTeamId = teamRef.documentID
        } else if let teamString = try? container.decodeIfPresent(String.self, forKey: .ownerTeamId) {
            // If it's a string, use it directly
            ownerTeamId = teamString
        } else {
            // If neither works, set to nil
            ownerTeamId = nil
        }
    }
    
    // Custom encoder (in case you need to write back to Firestore)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(location, forKey: .location)
        try container.encodeIfPresent(bestSquatId, forKey: .bestSquatId)
        try container.encodeIfPresent(bestBenchId, forKey: .bestBenchId)
        try container.encodeIfPresent(bestDeadliftId, forKey: .bestDeadliftId)
        try container.encodeIfPresent(ownerTeamId, forKey: .ownerTeamId)
    }
    
    // Custom Equatable implementation
    static func == (lhs: Gym, rhs: Gym) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.location.lat == rhs.location.lat &&
               lhs.location.lon == rhs.location.lon &&
               lhs.ownerTeamId == rhs.ownerTeamId
    }
    
    // Custom initializer for creating Gym instances manually
    init(id: String? = nil, name: String, location: Location, bestSquatId: String? = nil, bestBenchId: String? = nil, bestDeadliftId: String? = nil, ownerTeamId: String? = nil) {
        self.id = id
        self.name = name
        self.location = location
        self.bestSquatId = bestSquatId
        self.bestBenchId = bestBenchId
        self.bestDeadliftId = bestDeadliftId
        self.ownerTeamId = ownerTeamId
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
