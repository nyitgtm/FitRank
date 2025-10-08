import Foundation
import FirebaseFirestore

struct Team: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var name: String
    var color: String // Hex color code
    var slug: String
    var icon: String? // sf symbol nammeee
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case color
        case slug
        case icon
    }
}
