import Foundation
import FirebaseFirestore

struct Team: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var name: String
    var color: String // hex color or color name
    var slug: String // one string representation ex. killa_gorillaz
    var icon: String? // SF Symbol name or icon reference
}
