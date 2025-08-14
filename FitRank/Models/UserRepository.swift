import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
final class UserRepository: ObservableObject {
    private let db = Firestore.firestore()
    
    // Check if username already exists
    func isUsernameAvailable(_ username: String) async throws -> Bool {
        let snapshot = try await db.collection("users")
            .whereField("username", isEqualTo: username)
            .getDocuments()
        
        return snapshot.documents.isEmpty
    }
    
    // Create user document in Firestore
    func createUser(_ user: User) async throws {
        try await db.collection("users").document(user.uid).setData([
            "uid": user.uid,
            "isCoach": user.isCoach,
            "name": user.name,
            "team": user.team,
            "tokens": user.tokens,
            "username": user.username
        ])
    }
    
    // Get user by UID
    func getUser(uid: String) async throws -> User? {
        let document = try await db.collection("users").document(uid).getDocument()
        
        guard document.exists else { return nil }
        
        return try document.data(as: User.self)
    }
    
    // Get all teams for selection
    func getTeams() async throws -> [Team] {
        let snapshot = try await db.collection("teams").getDocuments()
        return try snapshot.documents.compactMap { document in
            try document.data(as: Team.self)
        }
    }
    
    // Get team reference by team ID
    func getTeamReference(teamId: String) -> DocumentReference {
        return db.collection("teams").document(teamId)
    }
}
