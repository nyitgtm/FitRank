import Foundation
import FirebaseFirestore
import FirebaseAuth

class CommentService: ObservableObject {
    static let shared = CommentService()
    private let db = Firestore.firestore()
    
    @Published var comments: [String: [Comment]] = [:] // workoutID: [comments]
    @Published var replies: [String: [Comment]] = [:] // commentID: [replies]
    @Published var commentLikes: [String: Bool] = [:] // commentID: hasLiked
    @Published var commentCounts: [String: Int] = [:] // workoutID: count
    
    private init() {}
    
    // MARK: - Fetch Comments
    
    func fetchComments(workoutID: String) async {
        do {
            print("📥 Fetching comments for workout: \(workoutID)")
            
            let snapshot = try await db.collection("workouts")
                .document(workoutID)
                .collection("comments")
                .order(by: "timestamp", descending: true)
                .getDocuments()
            
            print("📄 Found \(snapshot.documents.count) total documents")
            
            let allComments = snapshot.documents.compactMap { doc -> Comment? in
                do {
                    let comment = try doc.data(as: Comment.self)
                    print("📝 Comment: \(comment.content), parentID: \(comment.parentCommentID ?? "nil")")
                    return comment
                } catch {
                    print("❌ Error decoding comment \(doc.documentID): \(error)")
                    return nil
                }
            }
            
            let fetchedComments = allComments.filter { $0.parentCommentID == nil } // Filter for top-level comments
            
            await MainActor.run {
                self.comments[workoutID] = fetchedComments
                self.commentCounts[workoutID] = fetchedComments.count
            }
            
            print("✅ Fetched \(fetchedComments.count) top-level comments for workout \(workoutID)")
        } catch {
            print("❌ Error fetching comments: \(error)")
        }
    }
    
    func fetchReplies(workoutID: String, commentID: String) async {
        do {
            let snapshot = try await db.collection("workouts")
                .document(workoutID)
                .collection("comments")
                .whereField("parentCommentID", isEqualTo: commentID)
                .order(by: "timestamp", descending: false)
                .getDocuments()
            
            let fetchedReplies = snapshot.documents.compactMap { doc -> Comment? in
                try? doc.data(as: Comment.self)
            }
            
            await MainActor.run {
                self.replies[commentID] = fetchedReplies
            }
            
            print("✅ Fetched \(fetchedReplies.count) replies for comment \(commentID)")
        } catch {
            print("❌ Error fetching replies: \(error)")
        }
    }
    
    // MARK: - Add Comment/Reply
    
    func addComment(workoutID: String, userID: String, content: String, parentCommentID: String? = nil) async throws {
        let comment = Comment(
            userID: userID,
            workoutID: workoutID,
            content: content,
            parentCommentID: parentCommentID
        )
        
        let commentRef = try db.collection("workouts")
            .document(workoutID)
            .collection("comments")
            .addDocument(from: comment)
        
        // If it's a reply, increment parent's reply count
        if let parentID = parentCommentID {
            try await db.collection("workouts")
                .document(workoutID)
                .collection("comments")
                .document(parentID)
                .updateData(["replyCount": FieldValue.increment(Int64(1))])
        }
        
        // Refresh comments or replies
        if parentCommentID == nil {
            await fetchComments(workoutID: workoutID)
        } else {
            await fetchReplies(workoutID: workoutID, commentID: parentCommentID!)
        }
        
        print("✅ Added comment/reply: \(commentRef.documentID)")
    }
    
    // MARK: - Like/Unlike Comment
    
    func toggleLike(workoutID: String, commentID: String, userID: String) async throws {
        let likeRef = db.collection("workouts")
            .document(workoutID)
            .collection("comments")
            .document(commentID)
            .collection("likes")
            .document(userID)
        
        let likeDoc = try await likeRef.getDocument()
        
        if likeDoc.exists {
            // Unlike
            try await likeRef.delete()
            try await db.collection("workouts")
                .document(workoutID)
                .collection("comments")
                .document(commentID)
                .updateData(["likes": FieldValue.increment(Int64(-1))])
            
            await MainActor.run {
                self.commentLikes[commentID] = false
            }
            
            print("👎 Unliked comment \(commentID)")
        } else {
            // Like
            let like = CommentLike(userID: userID, commentID: commentID)
            try likeRef.setData(from: like)
            try await db.collection("workouts")
                .document(workoutID)
                .collection("comments")
                .document(commentID)
                .updateData(["likes": FieldValue.increment(Int64(1))])
            
            await MainActor.run {
                self.commentLikes[commentID] = true
            }
            
            print("👍 Liked comment \(commentID)")
        }
    }
    
    // MARK: - Check if User Liked Comment
    
    func checkIfLiked(workoutID: String, commentID: String, userID: String) async {
        do {
            let likeDoc = try await db.collection("workouts")
                .document(workoutID)
                .collection("comments")
                .document(commentID)
                .collection("likes")
                .document(userID)
                .getDocument()
            
            await MainActor.run {
                self.commentLikes[commentID] = likeDoc.exists
            }
        } catch {
            print("❌ Error checking like status: \(error)")
        }
    }
    
    // MARK: - Delete Comment
    
    func deleteComment(workoutID: String, commentID: String, parentCommentID: String?) async throws {
        try await db.collection("workouts")
            .document(workoutID)
            .collection("comments")
            .document(commentID)
            .delete()
        
        // If it's a reply, decrement parent's reply count
        if let parentID = parentCommentID {
            try await db.collection("workouts")
                .document(workoutID)
                .collection("comments")
                .document(parentID)
                .updateData(["replyCount": FieldValue.increment(Int64(-1))])
        }
        
        // Refresh
        if parentCommentID == nil {
            await fetchComments(workoutID: workoutID)
        } else {
            await fetchReplies(workoutID: workoutID, commentID: parentCommentID!)
        }
        
        print("🗑️ Deleted comment \(commentID)")
    }
}
