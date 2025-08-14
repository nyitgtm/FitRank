import Foundation
import FirebaseAuth
import Combine

@MainActor
class CommentViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isPosting = false
    
    private let firebaseService = FirebaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Comment Management
    
    func fetchComments(for workoutId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedComments = try await firebaseService.getComments(workoutId: workoutId)
            comments = fetchedComments
        } catch {
            errorMessage = "Failed to fetch comments: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func postComment(content: String, for workoutId: String) async {
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = "User not authenticated"
            return
        }
        
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Comment cannot be empty"
            return
        }
        
        guard content.count <= 500 else {
            errorMessage = "Comment cannot exceed 500 characters"
            return
        }
        
        isPosting = true
        errorMessage = nil
        
        do {
            let comment = Comment(
                userID: currentUser.uid,
                workoutID: workoutId,
                content: content.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            try await firebaseService.createComment(comment)
            
            // Refresh comments
            await fetchComments(for: workoutId)
            
        } catch {
            errorMessage = "Failed to post comment: \(error.localizedDescription)"
        }
        
        isPosting = false
    }
    
    func deleteComment(_ comment: Comment) async {
        guard let commentId = comment.id else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await firebaseService.deleteComment(commentId: commentId)
            
            // Remove from local array
            comments.removeAll { $0.id == commentId }
            
        } catch {
            errorMessage = "Failed to delete comment: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func updateComment(_ comment: Comment, newContent: String) async {
        guard let commentId = comment.id else { return }
        
        guard !newContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Comment cannot be empty"
            return
        }
        
        guard newContent.count <= 500 else {
            errorMessage = "Comment cannot exceed 500 characters"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            var updatedComment = comment
            updatedComment.content = newContent.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Update in Firestore (this would need to be added to FirebaseService)
            // For now, we'll just update locally
            if let index = comments.firstIndex(where: { $0.id == commentId }) {
                comments[index] = updatedComment
            }
            
        } catch {
            errorMessage = "Failed to update comment: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Comment Interactions
    
    func likeComment(_ comment: Comment) async {
        // This would need to be implemented in FirebaseService
        // For now, we'll just update locally
        if let index = comments.firstIndex(where: { $0.id == comment.id }) {
            var updatedComment = comment
            updatedComment.likes += 1
            comments[index] = updatedComment
        }
    }
    
    func dislikeComment(_ comment: Comment) async {
        // This would need to be implemented in FirebaseService
        // For now, we'll just update locally
        if let index = comments.firstIndex(where: { $0.id == comment.id }) {
            var updatedComment = comment
            updatedComment.dislikes += 1
            comments[index] = updatedComment
        }
    }
    
    // MARK: - Comment Validation
    
    func validateComment(_ content: String) -> (isValid: Bool, errorMessage: String?) {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedContent.isEmpty {
            return (false, "Comment cannot be empty")
        }
        
        if trimmedContent.count > 500 {
            return (false, "Comment cannot exceed 500 characters")
        }
        
        return (true, nil)
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
}

