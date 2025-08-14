import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let uid: String // Firebase Auth UID
    let isCoach: Bool
    let name: String
    let team: DocumentReference
    let tokens: Int
    let username: String
    
    init(uid: String, isCoach: Bool, name: String, team: DocumentReference, tokens: Int, username: String) {
        self.uid = uid
        self.isCoach = isCoach
        self.name = name
        self.team = team
        self.tokens = tokens
        self.username = username
    }
    
    // Custom coding keys to handle DocumentReference
    enum CodingKeys: String, CodingKey {
        case uid, isCoach, name, team, tokens, username
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uid = try container.decode(String.self, forKey: .uid)
        isCoach = try container.decode(Bool.self, forKey: .isCoach)
        name = try container.decode(String.self, forKey: .name)
        team = try container.decode(DocumentReference.self, forKey: .team)
        tokens = try container.decode(Int.self, forKey: .tokens)
        username = try container.decode(String.self, forKey: .username)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uid, forKey: .uid)
        try container.encode(isCoach, forKey: .isCoach)
        try container.encode(name, forKey: .name)
        try container.encode(team, forKey: .team)
        try container.encode(tokens, forKey: .tokens)
        try container.encode(username, forKey: .username)
    }
}
