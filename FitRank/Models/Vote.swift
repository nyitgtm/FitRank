import Foundation
import FirebaseFirestore

struct Vote: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var voteType: String // "upvote" or "downvote"
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case voteType
        case createdAt
    }
    
    init(id: String? = nil, userId: String, voteType: VoteType) {
        self.id = id
        self.userId = userId
        self.voteType = voteType.rawValue
        self.createdAt = Date()
    }
    
    var voteTypeEnum: VoteType {
        return VoteType(rawValue: voteType) ?? .upvote
    }
}

enum VoteType: String, Codable {
    case upvote = "upvote"
    case downvote = "downvote"
}
