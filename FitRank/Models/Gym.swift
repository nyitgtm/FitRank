import Foundation
import FirebaseFirestore

struct LiftRecord: Codable, Equatable {
    var weight: Double
    var userId: String
    var teamId: String
    var workoutId: String
}

struct Location: Codable, Equatable {
    let address: String?
    let lat: Double
    let lon: Double
}

struct Gym: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var name: String
    var location: Location
    var bestSquat: LiftRecord?
    var bestBench: LiftRecord?
    var bestDeadlift: LiftRecord?
    var ownerTeamId: String? // Will be extracted from DocumentReference
    
    // Custom coding keys to handle DocumentReference
    enum CodingKeys: String, CodingKey {
        case id, name, location, bestSquat, bestBench, bestDeadlift, ownerTeamId
    }
    
    // Custom decoder to handle DocumentReference
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try container.decode(String.self, forKey: .name)
        location = try container.decode(Location.self, forKey: .location)
        bestSquat = try container.decodeIfPresent(LiftRecord.self, forKey: .bestSquat)
        bestBench = try container.decodeIfPresent(LiftRecord.self, forKey: .bestBench)
        bestDeadlift = try container.decodeIfPresent(LiftRecord.self, forKey: .bestDeadlift)
        
        // Handle ownerTeamId as either String or DocumentReference
        if let teamRef = try? container.decode(DocumentReference.self, forKey: .ownerTeamId) {
            ownerTeamId = teamRef.documentID
        } else if let teamString = try? container.decodeIfPresent(String.self, forKey: .ownerTeamId) {
            ownerTeamId = teamString
        } else {
            ownerTeamId = nil
        }
    }
    
    // Custom encoder (in case you need to write back to Firestore)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(location, forKey: .location)
        try container.encodeIfPresent(bestSquat, forKey: .bestSquat)
        try container.encodeIfPresent(bestBench, forKey: .bestBench)
        try container.encodeIfPresent(bestDeadlift, forKey: .bestDeadlift)
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
}
