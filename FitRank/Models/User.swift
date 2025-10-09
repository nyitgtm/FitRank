import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var name: String
    var team: String // Reference to team document (e.g., "/teams/0")
    var isCoach: Bool
    var username: String
    var tokens: Int
    var isDarkMode: Bool? // Dark mode preference
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case team
        case isCoach
        case username
        case tokens
        case isDarkMode
    }
    
    // Manual initializer
    init(id: String?, name: String, team: String, isCoach: Bool, username: String, tokens: Int, isDarkMode: Bool? = nil) {
        self.id = id
        self.name = name
        self.team = team
        self.isCoach = isCoach
        self.username = username
        self.tokens = tokens
        self.isDarkMode = isDarkMode
    }
}

// Team reference - now using the Team model from Firestore
// The team field stores a reference to a team document
