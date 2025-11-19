import Foundation
import FirebaseFirestore
import FirebaseAuth

class CommentService: ObservableObject {
    static let shared = CommentService()
    private let db = Firestore.firestore()
    
    @Published var comments: [String: [Comment]] = [:] // workoutID: [comments]
    @Published var replies: [String: [Comment]] = [:] // commentID: [replies]
    @Published var commentLikes: [String: Bool] = [:] // scopedKey (workoutID:commentID): hasLiked
    @Published var commentCounts: [String: Int] = [:] // workoutID: count
    
    private init() {}
    
    // MARK: - Clear cached data
    
    func clearCommentsForWorkout(_ workoutID: String) {
        comments.removeValue(forKey: workoutID)
        commentCounts.removeValue(forKey: workoutID)
        // Clear replies and likes scoped to this workout to avoid stale data
        let prefix = "\(workoutID):"
        // remove replies entries for this workout
        for key in replies.keys where key.hasPrefix(prefix) {
            replies.removeValue(forKey: key)
        }
        // remove commentLikes entries for this workout
        for key in commentLikes.keys where key.hasPrefix(prefix) {
            commentLikes.removeValue(forKey: key)
        }
        // Note: This is a simple clear to prevent persistence across sheets
        print("🧹 Cleared comments cache for workout: \(workoutID)")
    }
    
    // MARK: - Fetch Comments
    
    func fetchComments(workoutID: String) async {
        // First, clear any existing cached data for this workout
        await MainActor.run {
            self.comments[workoutID] = []
            self.commentCounts[workoutID] = 0
        }
        
        do {
            print("📥 Fetching comments for workout: \(workoutID)")
            
            let snapshot = try await db.collection("workouts")
                .document(workoutID)
                .collection("comments")
                .order(by: "timestamp", descending: true)
                .getDocuments()
            
            print("📄 Found \(snapshot.documents.count) comments")
            
            // If no documents, explicitly set empty array
            if snapshot.documents.isEmpty {
                await MainActor.run {
                    self.comments[workoutID] = []
                    self.commentCounts[workoutID] = 0
                }
                print("✅ No comments for workout \(workoutID)")
                return
            }
            
            let fetchedComments = snapshot.documents.compactMap { doc -> Comment? in
                do {
                    var comment = try doc.data(as: Comment.self)
                    // Ensure the comment has its ID
                    if comment.id == nil {
                        comment.id = doc.documentID
                    }
                    // Defensive check: ensure comment.workoutID matches the workout we're loading
                    if comment.workoutID != workoutID {
                        print("⚠️ Skipping comment \(comment.id ?? "nil") because its workoutID (\(comment.workoutID)) doesn't match expected \(workoutID)")
                        return nil
                    }
                    print("📝 Comment: \(comment.content), ID: \(comment.id ?? "nil")")
                    return comment
                } catch {
                    print("❌ Error decoding comment \(doc.documentID): \(error)")
                    return nil
                }
            }
            
            await MainActor.run {
                self.comments[workoutID] = fetchedComments
                self.commentCounts[workoutID] = fetchedComments.count
            }
            
            print("✅ Fetched \(fetchedComments.count) comments for workout \(workoutID)")
        } catch {
            print("❌ Error fetching comments: \(error)")
            // On error, make sure we set empty array
            await MainActor.run {
                self.comments[workoutID] = []
                self.commentCounts[workoutID] = 0
            }
        }
    }
    
    func fetchReplies(workoutID: String, commentID: String) async {
        do {
            print("📥 Fetching replies for comment: \(commentID)")
            
            let snapshot = try await db.collection("workouts")
                .document(workoutID)
                .collection("comments")
                .document(commentID)
                .collection("replies")
                .order(by: "timestamp", descending: false)
                .getDocuments()
            
            print("📄 Found \(snapshot.documents.count) replies")
            
            let fetchedReplies = snapshot.documents.compactMap { doc -> Comment? in
                do {
                    var reply = try doc.data(as: Comment.self)
                    if reply.id == nil {
                        reply.id = doc.documentID
                    }
                    return reply
                } catch {
                    print("❌ Error decoding reply: \(error)")
                    return nil
                }
            }
            
            let scopedKey = "\(workoutID):\(commentID)"
            await MainActor.run {
                self.replies[scopedKey] = fetchedReplies
            }
            
            print("✅ Fetched \(fetchedReplies.count) replies for comment \(commentID)")
        } catch {
            print("❌ Error fetching replies: \(error)")
        }
    }
    
    // MARK: - Add Comment/Reply
    
    func addComment(workoutID: String, userID: String, content: String, parentCommentID: String? = nil) async throws {
        if let parentID = parentCommentID {
            // This is a reply - add to replies subcollection
            let reply = Comment(
                userID: userID,
                workoutID: workoutID,
                content: content,
                parentCommentID: parentID
            )
            
            let replyRef = try db.collection("workouts")
                .document(workoutID)
                .collection("comments")
                .document(parentID)
                .collection("replies")
                .addDocument(from: reply)
            
            // Increment parent's reply count
            try await db.collection("workouts")
                .document(workoutID)
                .collection("comments")
                .document(parentID)
                .updateData(["replyCount": FieldValue.increment(Int64(1))])
            
            // Refresh replies
            await fetchReplies(workoutID: workoutID, commentID: parentID)
            
            print("✅ Added reply: \(replyRef.documentID)")
        } else {
            // This is a top-level comment
            let comment = Comment(
                userID: userID,
                workoutID: workoutID,
                content: content
            )
            
            let commentRef = try db.collection("workouts")
                .document(workoutID)
                .collection("comments")
                .addDocument(from: comment)
            
            // Refresh comments
            await fetchComments(workoutID: workoutID)
            
            print("✅ Added comment: \(commentRef.documentID)")
        }
    }
    
    // MARK: - Like/Unlike Comment
    
    func toggleLike(workoutID: String, commentID: String, userID: String, isReply: Bool = false, parentCommentID: String? = nil) async throws {
        let commentRef: DocumentReference
        let likeRef: DocumentReference
        
        if isReply, let parentID = parentCommentID {
            // Like on a reply
            commentRef = db.collection("workouts")
                .document(workoutID)
                .collection("comments")
                .document(parentID)
                .collection("replies")
                .document(commentID)
            
            likeRef = commentRef.collection("likes").document(userID)
        } else {
            // Like on a top-level comment
            commentRef = db.collection("workouts")
                .document(workoutID)
                .collection("comments")
                .document(commentID)
            
            likeRef = commentRef.collection("likes").document(userID)
        }
        
        let likeDoc = try await likeRef.getDocument()
        
        if likeDoc.exists {
            // Unlike
            try await likeRef.delete()
            try await commentRef.updateData(["likes": FieldValue.increment(Int64(-1))])
            
            let scopedKey = "\(workoutID):\(commentID)"
            await MainActor.run {
                self.commentLikes[scopedKey] = false
            }
            
            print("👎 Unliked comment \(commentID)")
        } else {
            // Like
            let like = CommentLike(userID: userID, commentID: commentID)
            try likeRef.setData(from: like)
            try await commentRef.updateData(["likes": FieldValue.increment(Int64(1))])
            
            let scopedKey = "\(workoutID):\(commentID)"
            await MainActor.run {
                self.commentLikes[scopedKey] = true
            }
            
            print("👍 Liked comment \(commentID)")
        }
    }
    
    // MARK: - Check if User Liked Comment
    
    func checkIfLiked(workoutID: String, commentID: String, userID: String, isReply: Bool = false, parentCommentID: String? = nil) async {
        do {
            let likeDoc: DocumentSnapshot
            
            if isReply, let parentID = parentCommentID {
                likeDoc = try await db.collection("workouts")
                    .document(workoutID)
                    .collection("comments")
                    .document(parentID)
                    .collection("replies")
                    .document(commentID)
                    .collection("likes")
                    .document(userID)
                    .getDocument()
            } else {
                likeDoc = try await db.collection("workouts")
                    .document(workoutID)
                    .collection("comments")
                    .document(commentID)
                    .collection("likes")
                    .document(userID)
                    .getDocument()
            }
            
            let scopedKey = "\(workoutID):\(commentID)"
            await MainActor.run {
                self.commentLikes[scopedKey] = likeDoc.exists
            }
        } catch {
            print("❌ Error checking like status: \(error)")
        }
    }
    
    // MARK: - Delete Comment
    
    func deleteComment(workoutID: String, commentID: String, isReply: Bool = false, parentCommentID: String?) async throws {
        if isReply, let parentID = parentCommentID {
            // Delete reply
            try await db.collection("workouts")
                .document(workoutID)
                .collection("comments")
                .document(parentID)
                .collection("replies")
                .document(commentID)
                .delete()
            
            // Decrement parent's reply count
            try await db.collection("workouts")
                .document(workoutID)
                .collection("comments")
                .document(parentID)
                .updateData(["replyCount": FieldValue.increment(Int64(-1))])
            
            // Refresh replies
            await fetchReplies(workoutID: workoutID, commentID: parentID)
        } else {
            // Delete top-level comment (and all its replies)
            try await db.collection("workouts")
                .document(workoutID)
                .collection("comments")
                .document(commentID)
                .delete()
            
            // Refresh comments
            await fetchComments(workoutID: workoutID)
        }
        
        print("🗑️ Deleted comment \(commentID)")
    }
}
