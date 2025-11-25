//
//  UserRepository.swift
//  FitRank
//
//  Created by Navraj Singh on 10/8/25.
//


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
        // Use 'id' (which is the Firebase Auth UID)
        guard let uid = user.id else {
            throw URLError(.badServerResponse) // or any custom error
        }

        try await db.collection("users").document(uid).setData([
            "id": uid,                // store the UID
            "name": user.name,
            "team": user.team,        // team ID as String
            "isCoach": user.isCoach,
            "username": user.username,
            "tokens": user.tokens
        ])
    }


    
    // Get user by UID
    func getUser(uid: String) async throws -> User? {
        print("UserRepository: Fetching user document for UID: \(uid)")
        let document = try await db.collection("users").document(uid).getDocument()
        
        guard document.exists else {
            print("UserRepository: Document does not exist for UID: \(uid)")
            return nil
        }
        
        print("UserRepository: Document found, attempting to decode...")
        guard var data = document.data() else {
            print("UserRepository: No data in document")
            return nil
        }
        
        print("UserRepository: Document data: \(data)")
        
        // Fix for old documents: Convert FIRDocumentReference to String path
        if let teamRef = data["team"] as? DocumentReference {
            print("UserRepository: Converting DocumentReference to String path")
            data["team"] = teamRef.path
        }
        
        // Fix for old documents: Some may have 'uid' instead of 'id'
        if data["id"] == nil, let uidValue = data["uid"] as? String {
            print("UserRepository: Converting 'uid' field to 'id'")
            data["id"] = uidValue
            data.removeValue(forKey: "uid")
        }
        
        // Ensure id is set (Firestore's @DocumentID needs this)
        if data["id"] == nil {
            data["id"] = document.documentID
        }
        
        print("UserRepository: Modified data for decoding: \(data)")
        
        // Update the document with the corrected data and decode
        do {
            // Create a new document snapshot with the modified data
            // We'll manually construct the User object since @DocumentID needs special handling
            guard let id = data["id"] as? String,
                  let name = data["name"] as? String,
                  let team = data["team"] as? String,
                  let username = data["username"] as? String else {
                print("UserRepository: Missing required fields")
                throw NSError(domain: "UserRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing required fields"])
            }
            
            let isCoach = (data["isCoach"] as? Bool) ?? ((data["isCoach"] as? Int) == 1)
            let tokens = (data["tokens"] as? Int) ?? 0
            let blockedUsers = data["blockedUsers"] as? [String]
            
            var user = User(
                id: nil, // Will be set by @DocumentID
                name: name,
                team: team,
                isCoach: isCoach,
                username: username,
                tokens: tokens,
                blockedUsers: blockedUsers
            )
            
            // Manually set the id (simulating @DocumentID)
            user.id = id
            
            print("UserRepository: Successfully decoded user: \(user.username)")
            return user
        } catch {
            print("UserRepository: Decoding error - \(error)")
            throw error
        }
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
    
    // Block a user
    func blockUser(currentUserId: String, blockedUserId: String) async throws {
        try await db.collection("users").document(currentUserId).updateData([
            "blockedUsers": FieldValue.arrayUnion([blockedUserId])
        ])
    }
    
    // Unblock a user
    func unblockUser(currentUserId: String, blockedUserId: String) async throws {
        try await db.collection("users").document(currentUserId).updateData([
            "blockedUsers": FieldValue.arrayRemove([blockedUserId])
        ])
    }
    
    // Get multiple users by IDs
    func getUsers(ids: [String]) async throws -> [User] {
        guard !ids.isEmpty else { return [] }
        
        // Firestore 'in' query supports up to 10 items. For more, we need to batch or fetch individually.
        // For simplicity, we'll fetch individually for now as the blocked list is likely small.
        // A better approach for production would be chunking 'in' queries.
        
        var users: [User] = []
        
        for id in ids {
            if let user = try? await getUser(uid: id) {
                users.append(user)
            }
        }
        
        return users
    }
}
