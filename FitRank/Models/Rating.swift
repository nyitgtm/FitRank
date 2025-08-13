import Foundation
import FirebaseFirestore

struct Rating: Identifiable, Codable {
    @DocumentID var id: String?
    var userID: String // Who gave the rating
    var workoutId: String // Which workout is rated
    var value: RatingValue // +1 or -1
    var timestamp: Date
    
    init(id: String? = nil, userID: String, workoutId: String, value: RatingValue) {
        self.id = id
        self.userID = userID
        self.workoutId = workoutId
        self.value = value
        self.timestamp = Date()
    }
}

// Rating value enum to ensure only +1 or -1
enum RatingValue: Int, CaseIterable, Identifiable, Codable {
    case downvote = -1
    case upvote = 1
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .downvote: return "Downvote"
        case .upvote: return "Upvote"
        }
    }
    
    var icon: String {
        switch self {
        case .downvote: return "hand.thumbsdown.fill"
        case .upvote: return "hand.thumbsup.fill"
        }
    }
    
    var color: String {
        switch self {
        case .downvote: return "red"
        case .upvote: return "green"
        }
    }
}
