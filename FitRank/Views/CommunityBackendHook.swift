import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

// MARK: - Models (single source of truth)


struct CommunityComment: Identifiable, Hashable {
    let id: UUID = UUID()
    var backendId: String          // Firestore comment doc id
    var authorId: String           // who wrote it
    var authorName: String
    var text: String
    var createdAt: Date
}


struct CommunityPost: Identifiable, Hashable {
    let id: UUID = UUID()
    var backendId: String?          // Firestore doc id
    var authorId: String            // who wrote it
    var authorName: String
    var teamTag: String?
    var text: String
    var image: UIImage?             // local draft only
    var imageURLString: String?     // remote display
    var likeCount: Int
    var commentCount: Int
    var isLikedByMe: Bool
    var createdAt: Date
    var comments: [CommunityComment] = []
}



// MARK: - Minimal Firebase Community Service
@MainActor

final class CommunityService {
    static let shared = CommunityService()
    private let db = Firestore.firestore()
    private init() {}

   public var feedListener: ListenerRegistration?
    func deleteComment(postId: String, commentId: String) async throws {
        let postRef = db.collection("posts").document(postId)
        try await postRef.collection("comments").document(commentId).delete()
        try await postRef.updateData(["commentCount": FieldValue.increment(Int64(-1))])
    }
    // 1) Add this property near the top of CommunityService (with feedListener)
    private var commentsListener: ListenerRegistration?

    // 2) Add these methods anywhere inside CommunityService:

    // Live comments for a post
    func startComments(postId: String, onChange: @escaping ([CommunityComment]) -> Void) {
        commentsListener?.remove()
        commentsListener = db.collection("posts").document(postId)
            .collection("comments")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snap, _ in
                let items: [CommunityComment] = (snap?.documents ?? []).compactMap { doc in
                    let data = doc.data()
                    return CommunityComment(
                        backendId: doc.documentID,
                        authorId: data["authorId"] as? String ?? "",
                        authorName: data["authorName"] as? String ?? "User",
                        text: data["text"] as? String ?? "",
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                }
                onChange(items)
            }
    }

    // Stop comments listener
    func stopComments() {
        commentsListener?.remove()
        commentsListener = nil
    }

    // Delete a single comment and decrement counter
   

    func startFeed(onChange: @escaping ([CommunityFeedItem]) -> Void) {
        feedListener?.remove()
        feedListener = db.collection("posts")
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .addSnapshotListener { snap, _ in
                let items: [CommunityFeedItem] = (snap?.documents ?? []).compactMap { doc in
                    let data = doc.data()
                    return CommunityFeedItem(
                        id: doc.documentID,
                        authorId: data["authorId"] as? String ?? "",         // ✅
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
        feedListener?.remove()
        feedListener = nil
    }

    func publish(text: String, image: UIImage?) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { throw NSError(domain: "auth", code: 401) }

        // pull display name + team from users/{uid}
        let userDoc = try await db.collection("users").document(uid).getDocument()
        let authorName = (userDoc.data()?["name"] as? String)
                        ?? (userDoc.data()?["username"] as? String)
                        ?? "User"

        var teamName: String? = nil
        if let teamPathOrName = userDoc.data()?["team"] as? String, !teamPathOrName.isEmpty {
            if teamPathOrName.contains("/teams/") {
                // treat as document path
                let teamDoc = try await db.document(teamPathOrName).getDocument()
                teamName = teamDoc.data()?["name"] as? String ?? teamPathOrName
            } else {
                // treat as plain string
                teamName = teamPathOrName
            }
        }

        let ref = db.collection("posts").document()

        var imageURL: String? = nil
        if let image, let data = image.jpegData(compressionQuality: 0.85) {
            let storageRef = Storage.storage().reference(withPath: "posts/\(ref.documentID)/photo.jpg")
            _ = try await storageRef.putDataAsync(data, metadata: nil)
            imageURL = try await storageRef.downloadURL().absoluteString
        }

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

    func toggleLike(postId: String, currentlyLiked: Bool) async {
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
            print("toggleLike error:", error)
        }
    }

    func isLikedByMe(postId: String) async -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        let likeDoc = try? await db.collection("posts").document(postId)
            .collection("likes").document(uid).getDocument()
        return (likeDoc?.exists ?? false)
    }

    func addComment(postId: String, text: String) async {
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
            print("addComment error:", error)
        }
    }
}

// MARK: - Firebase-backed ViewModel
@MainActor
final class CommunityVM_Firebase: ObservableObject {
    @Published var posts: [CommunityPost] = []
    @Published var isLoading = false
    @Published var showComposer = false
    @Published var draftText = ""
    @Published var draftImage: UIImage?

    private let svc = CommunityService.shared

    init() { listen() }

    private func listen() {
        isLoading = true
        svc.startFeed { [weak self] items in
            Task { @MainActor in
                guard let self else { return }
                var mapped: [CommunityPost] = []
                for it in items {
                    let liked = await self.svc.isLikedByMe(postId: it.id)
                    mapped.append(
                        CommunityPost(
                            backendId: it.id,
                            authorId: it.authorId, // Fixed: was empty string
                            authorName: it.authorName,
                            teamTag: it.teamTag,
                            text: it.text,
                            image: nil,
                            imageURLString: it.imageURLString,
                            likeCount: it.likeCount,
                            commentCount: it.commentCount,
                            isLikedByMe: liked,
                            createdAt: it.createdAt,
                            comments: []
                        )
                    )
                }
                self.posts = mapped
                self.isLoading = false
            }
        }
    }

    deinit {
        Task { @MainActor in
            CommunityService.shared.stopFeed()
        }
    }


    func publishDraft() {
        let trimmed = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || draftImage != nil else { return }
        Task {
            do {
                try await svc.publish(text: trimmed, image: draftImage)
                await MainActor.run {
                    draftText = ""
                    draftImage = nil
                    showComposer = false
                }
            } catch {
                print("publish error:", error)
            }
        }
    }

    func toggleLike(_ post: CommunityPost) {
        guard let id = post.backendId else { return }
        Task { await svc.toggleLike(postId: id, currentlyLiked: post.isLikedByMe) }
        // optimistic UI
        if let i = posts.firstIndex(of: post) {
            posts[i].isLikedByMe.toggle()
            posts[i].likeCount += posts[i].isLikedByMe ? 1 : -1
        }
    }

    func addComment(_ text: String, to post: CommunityPost) {
        guard let id = post.backendId else { return }
        let msg = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !msg.isEmpty else { return }
        Task { await svc.addComment(postId: id, text: msg) }
    }
    
    func deletePost(_ post: CommunityPost) {
        guard let id = post.backendId else { return }
        
        // Optimistic UI - remove from list immediately
        if let index = posts.firstIndex(where: { $0.backendId == id }) {
            posts.remove(at: index)
        }
        
        // Delete from Firebase
        Task {
            do {
                try await svc.deletePost(postId: id)
            } catch {
                print("Failed to delete post: \(error)")
                // Could re-fetch or show error here
            }
        }
    }
    
    
}


import FirebaseFirestore
import FirebaseStorage

extension CommunityService {
    /// Delete post + its subcollections (comments/likes) + storage image
    func deletePost(postId: String) async throws {
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

        // delete image (best-effort)
        let storageRef = Storage.storage().reference(withPath: "posts/\(postId)/photo.jpg")
        try? await storageRef.delete()

        // delete post
        try await postRef.delete()
    }
}
