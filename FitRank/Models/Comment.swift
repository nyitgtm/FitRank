import Foundation
import FirebaseFirestore

struct Comment: Identifiable, Codable {
    @DocumentID var id: String?
    var userID: String // Who wrote the comment
    var workoutID: String // Which workout the comment is on
    var content: String // Comment text
    var likes: Int // Number of likes
    var dislikes: Int // Number of dislikes
    var timestamp: Date
    
    init(id: String? = nil, userID: String, workoutID: String, content: String) {
        self.id = id
        self.userID = userID
        self.workoutID = workoutID
        self.content = content
        self.likes = 0
        self.dislikes = 0
        self.timestamp = Date()
    }
    
    // Computed property for total engagement
    var totalEngagement: Int {
        return likes + dislikes
    }
    
    // Computed property for sentiment score
    var sentimentScore: Double {
        let total = totalEngagement
        guard total > 0 else { return 0.0 }
        return Double(likes - dislikes) / Double(total)
    }
}

