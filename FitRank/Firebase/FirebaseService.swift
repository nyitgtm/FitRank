//
//  FirebaseService.swift
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

#if canImport(UIKit)
import UIKit
#endif

#if canImport(FirebaseStorage)
import FirebaseStorage
#endif

// MARK: - Service

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()

    // Live listeners
    private var communityFeedListener: ListenerRegistration?
    private var communityCommentsListener: ListenerRegistration?

    private init() {}

    // MARK: - User Operations

    func createUser(_ user: User) async throws {
        guard let userId = user.id else { throw FirebaseError.invalidUserId }
        try await db.collection("users").document(userId).setData(from: user)
    }

    func getUser(userId: String) async throws -> User {
        let document = try await db.collection("users").document(userId).getDocument()
        guard let user = try? document.data(as: User.self) else { throw FirebaseError.decodingError }
        return user
    }

    func updateUser(_ user: User) async throws {
        guard let userId = user.id else { throw FirebaseError.invalidUserId }
        try await db.collection("users").document(userId).setData(from: user)
    }

    func checkUsernameAvailability(_ username: String) async throws -> Bool {
        let snapshot = try await db.collection("users")
            .whereField("username", isEqualTo: username)
            .getDocuments()
        return snapshot.documents.isEmpty
    }

    // MARK: - Workout Operations

    func createWorkout(_ workout: Workout) async throws -> String {
        let documentRef = try await db.collection("workouts").addDocument(from: workout)
        return documentRef.documentID
    }

    func getWorkouts(limit: Int = 50) async throws -> [Workout] {
        let snapshot = try await db.collection("workouts")
            .whereField("status", isEqualTo: "published")
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: Workout.self) }
    }

    func getWorkoutsByTeam(teamId: String, limit: Int = 50) async throws -> [Workout] {
        let snapshot = try await db.collection("workouts")
            .whereField("teamId", isEqualTo: teamId)
            .whereField("status", isEqualTo: "published")
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: Workout.self) }
    }

    func getWorkoutsByUser(userId: String, limit: Int? = nil) async throws -> [Workout] {
        var query = db.collection("workouts")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
        
        if let limit = limit {
            query = query.limit(to: limit)
        }
        
        let snapshot = try await query.getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: Workout.self) }
    }

    func getWorkout(workoutId: String) async throws -> Workout {
        let document = try await db.collection("workouts").document(workoutId).getDocument()
        guard let workout = try? document.data(as: Workout.self) else { throw FirebaseError.decodingError }
        return workout
    }

    func updateWorkout(_ workout: Workout) async throws {
        guard let workoutId = workout.id else { throw FirebaseError.invalidWorkoutId }
        try await db.collection("workouts").document(workoutId).setData(from: workout)
    }

    func deleteWorkout(workoutId: String) async throws {
        try await db.collection("workouts").document(workoutId).delete()
    }

    // MARK: - Rating Operations

    func createRating(_ rating: Rating) async throws {
        let existingRating = try await getUserRating(userId: rating.userID, workoutId: rating.workoutId)
        if existingRating != nil { throw FirebaseError.duplicateRating }
        try await db.collection("ratings").addDocument(from: rating)
        try await updateWorkoutVotes(workoutId: rating.workoutId, ratingValue: rating.value)
    }

    func getUserRating(userId: String, workoutId: String) async throws -> Rating? {
        let snapshot = try await db.collection("ratings")
            .whereField("userID", isEqualTo: userId)
            .whereField("workoutId", isEqualTo: workoutId)
            .getDocuments()
        return try snapshot.documents.first?.data(as: Rating.self)
    }

    private func updateWorkoutVotes(workoutId: String, ratingValue: RatingValue) async throws {
        let workoutRef = db.collection("workouts").document(workoutId)
        let workoutDoc = try await workoutRef.getDocument()
        guard var workout = try? workoutDoc.data(as: Workout.self) else { throw FirebaseError.decodingError }
        if ratingValue == .upvote { workout.upvotes += 1 } else { workout.downvotes += 1 }
        try await workoutRef.setData(from: workout)
    }

    // MARK: - Global Comment Operations (non-community)

    func createComment(_ comment: Comment) async throws {
        try await db.collection("comments").addDocument(from: comment)
    }

    func getComments(workoutId: String) async throws -> [Comment] {
        let snapshot = try await db.collection("comments")
            .whereField("workoutID", isEqualTo: workoutId)
            .order(by: "timestamp", descending: false)
            .getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: Comment.self) }
    }

    func deleteComment(commentId: String) async throws {
        try await db.collection("comments").document(commentId).delete()
    }

    // MARK: - Gym Operations

    func fetchGyms() async throws -> [Gym] {
        let snapshot = try await db.collection("gyms").getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: Gym.self) }
    }

    func getGym(id: String) async throws -> Gym? {
        let document = try await db.collection("gyms").document(id).getDocument()
        return try? document.data(as: Gym.self)
    }

    func createGym(_ gym: Gym) async throws {
        try await db.collection("gyms").addDocument(from: gym)
    }

    func updateGym(_ gym: Gym) async throws {
        guard let id = gym.id else { throw FirebaseError.invalidDocument }
        try await db.collection("gyms").document(id).setData(from: gym)
    }

    func deleteGym(id: String) async throws {
        try await db.collection("gyms").document(id).delete()
    }

    // MARK: - Report Operations

    func createReport(_ report: Report) async throws {
        try await db.collection("reports").addDocument(from: report)
    }

    func getReports(status: ReportStatus? = nil) async throws -> [Report] {
        let query: Query = {
            if let status = status {
                return db.collection("reports").whereField("status", isEqualTo: status.rawValue)
            } else {
                return db.collection("reports")
            }
        }()
        let snapshot = try await query.order(by: "timestamp", descending: true).getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: Report.self) }
    }

    func updateReportStatus(reportId: String, status: ReportStatus) async throws {
        try await db.collection("reports").document(reportId).updateData(["status": status.rawValue])
    }

    // MARK: - Storage (Mock)

    func uploadVideo(url: URL, fileName: String) async throws -> String {
        return "https://example.com/videos/\(fileName)"
    }

    func deleteVideo(fileName: String) async throws {
        print("Mock: Deleting video \(fileName)")
    }
}

// MARK: - Community Feature

// Feed item fetched from Firestore
struct CommunityFeedItem {
    let id: String
    let authorId: String
    let authorName: String
    let teamTag: String?
    let text: String
    let imageURLString: String?
    let likeCount: Int
    let commentCount: Int
    let createdAt: Date
}

// Slim comment item for live stream
struct CommunityCommentItem {
    let id: String
    let authorName: String
    let text: String
    let createdAt: Date
}

extension FirebaseService {

    // MARK: Live Feed

    func startFeed(onChange: @escaping ([CommunityFeedItem]) -> Void) {
        communityFeedListener?.remove()
        communityFeedListener = db.collection("posts")
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .addSnapshotListener { snap, _ in
                let items: [CommunityFeedItem] = (snap?.documents ?? []).compactMap { doc in
                    let data = doc.data()
                    return CommunityFeedItem(
                        id: doc.documentID,
                        authorId: data["authorId"] as? String ?? "",
                        authorName: data["authorName"] as? String ?? "User",
                        teamTag: data["teamTag"] as? String,
                        text: data["text"] as? String ?? "",
                        imageURLString: data["imageURL"] as? String,
                        likeCount: data["likeCount"] as? Int ?? 0,
                        commentCount: data["commentCount"] as? Int ?? 0,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                }
                onChange(items)
            }
    }

    func stopFeed() {
        communityFeedListener?.remove()
        communityFeedListener = nil
    }

    // MARK: Create Post

    func createCommunityPost(text: String, image: UIImage?) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { throw FirebaseError.permissionDenied }

        let userDoc = try await db.collection("users").document(uid).getDocument()
        let authorName = (userDoc.data()?["name"] as? String)
                        ?? (userDoc.data()?["username"] as? String)
                        ?? "User"

        var teamName: String? = nil
        if let teamPath = userDoc.data()?["team"] as? String, !teamPath.isEmpty {
            if teamPath.contains("/teams/") {
                let teamDoc = try await db.document(teamPath).getDocument()
                teamName = teamDoc.data()?["name"] as? String
            } else {
                teamName = teamPath
            }
        }

        let ref = db.collection("posts").document()

        var imageURL: String? = nil
        #if canImport(FirebaseStorage)
        if let image, let data = image.jpegData(compressionQuality: 0.85) {
            let storageRef = Storage.storage().reference(withPath: "posts/\(ref.documentID)/photo.jpg")
            _ = try await storageRef.putDataAsync(data, metadata: nil)
            imageURL = try await storageRef.downloadURL().absoluteString
        }
        #endif

        try await ref.setData([
            "authorId": uid,
            "authorName": authorName,
            "teamTag": teamName as Any,
            "text": text,
            "imageURL": imageURL as Any,
            "likeCount": 0,
            "commentCount": 0,
            "createdAt": FieldValue.serverTimestamp()
        ])
    }

    // MARK: Likes

    func toggleCommunityLike(postId: String, currentlyLiked: Bool) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let postRef = db.collection("posts").document(postId)
        let likeRef = postRef.collection("likes").document(uid)
        do {
            if currentlyLiked {
                try await likeRef.delete()
                try await postRef.updateData(["likeCount": FieldValue.increment(Int64(-1))])
            } else {
                try await likeRef.setData(["createdAt": FieldValue.serverTimestamp()])
                try await postRef.updateData(["likeCount": FieldValue.increment(Int64(1))])
            }
        } catch {
            print("toggleCommunityLike error:", error)
        }
    }

    // MARK: Comments (live under a post)

    func startCommunityComments(postId: String, onChange: @escaping ([CommunityCommentItem]) -> Void) {
        communityCommentsListener?.remove()
        communityCommentsListener = db.collection("posts").document(postId)
            .collection("comments")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snap, _ in
                let items: [CommunityCommentItem] = (snap?.documents ?? []).compactMap { doc in
                    let data = doc.data()
                    return CommunityCommentItem(
                        id: doc.documentID,
                        authorName: data["authorName"] as? String ?? "User",
                        text: data["text"] as? String ?? "",
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                }
                onChange(items)
            }
    }

    func stopCommunityComments() {
        communityCommentsListener?.remove()
        communityCommentsListener = nil
    }

    func addCommunityComment(postId: String, text: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            let userDoc = try await db.collection("users").document(uid).getDocument()
            let name = (userDoc.data()?["name"] as? String)
                     ?? (userDoc.data()?["username"] as? String) ?? "User"

            let ref = db.collection("posts").document(postId).collection("comments").document()
            try await ref.setData([
                "authorId": uid,
                "authorName": name,
                "text": text,
                "createdAt": FieldValue.serverTimestamp()
            ])
            try await db.collection("posts").document(postId)
                .updateData(["commentCount": FieldValue.increment(Int64(1))])
        } catch {
            print("addCommunityComment error:", error)
        }
    }

    // MARK: Delete comment (community)

    func deleteCommunityComment(postId: String, commentId: String) async throws {
        let postRef = db.collection("posts").document(postId)
        try await postRef.collection("comments").document(commentId).delete()
        try await postRef.updateData(["commentCount": FieldValue.increment(Int64(-1))])
    }
}

// MARK: - Post deletion (extension)

extension FirebaseService {
    /// Delete a community post + subcollections + image
    func deleteCommunityPost(postId: String) async throws {
        let postRef = db.collection("posts").document(postId)

        // delete comments
        let commentsSnap = try await postRef.collection("comments").getDocuments()
        for doc in commentsSnap.documents {
            try await doc.reference.delete()
        }

        // delete likes
        let likesSnap = try await postRef.collection("likes").getDocuments()
        for doc in likesSnap.documents {
            try await doc.reference.delete()
        }

        // delete image (best effort)
        #if canImport(FirebaseStorage)
        let storageRef = Storage.storage().reference(withPath: "posts/\(postId)/photo.jpg")
        try? await storageRef.delete()
        #endif

        // delete post
        try await postRef.delete()
    }
}

// MARK: - Errors

enum FirebaseError: Error, LocalizedError {
    case invalidUserId
    case invalidWorkoutId
    case duplicateRating
    case decodingError
    case networkError
    case permissionDenied
    case invalidDocument

    var errorDescription: String? {
        switch self {
        case .invalidUserId:    return "Invalid user ID"
        case .invalidWorkoutId: return "Invalid workout ID"
        case .duplicateRating:  return "You have already rated this workout"
        case .decodingError:    return "Failed to decode data"
        case .networkError:     return "Network error occurred"
        case .permissionDenied: return "Permission denied"
        case .invalidDocument:  return "Invalid document ID"
        }
    }
}

