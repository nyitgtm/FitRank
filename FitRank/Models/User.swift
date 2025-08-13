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

// Team enum for the three fixed teams
enum Team: String, CaseIterable, Codable, Identifiable {
    case killa = "0"
    case dark = "1" 
    case regal = "2"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .killa: return "Killa Gorillaz"
        case .dark: return "Dark Sharks"
        case .regal: return "Regal Eagles"
        }
    }
    
    var color: String {
        switch self {
        case .killa: return "#ff7700" // Orange
        case .dark: return "#007bff"  // Blue
        case .regal: return "#6f42c1" // Purple
        }
    }
    
    var slug: String {
        switch self {
        case .killa: return "killa_gorillaz"
        case .dark: return "dark_sharks"
        case .regal: return "regal_eagles"
        }
    }
}
