import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var name: String
    var team: String // Reference to team document (e.g., "/teams/0")
    var isCoach: Bool
    var username: String
    var tokens: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case team
        case isCoach
        case username
        case tokens
    }
}

// Team reference - now using the Team model from Firestore
// The team field stores a reference to a team document
