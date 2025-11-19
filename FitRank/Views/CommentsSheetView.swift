import SwiftUI
import FirebaseAuth

struct CommentsSheetView: View {
    let workoutID: String
    @ObservedObject var commentService = CommentService.shared
    @StateObject private var userRepository = UserRepository()
    @Environment(\.dismiss) var dismiss
    
    @State private var newCommentText = ""
    @State private var replyingTo: Comment?
    @State private var commentUsers: [String: User] = [:] // Cache user data
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Comments List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if let comments = commentService.comments[workoutID], !comments.isEmpty {
                            ForEach(comments) { comment in
                                CommentRowView(
                                    workoutID: workoutID,
                                    comment: comment,
                                    user: commentUsers[comment.userID],
                                    onReply: { replyingTo = $0 }
                                )
                            }
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "text.bubble")
                                    .font(.system(size: 50))
                                    .foregroundColor(.secondary)
                                Text("No comments yet")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text("Be the first to comment!")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 100)
                        }
                    }
                    .padding()
                }
                
                Divider()
                
                // Reply indicator
                if let replyingTo = replyingTo {
                    HStack {
                        Text("Replying to @\(commentUsers[replyingTo.userID]?.username ?? "user")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button {
                            self.replyingTo = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                }
                
                // Input Area
                HStack(spacing: 12) {
                    TextField(replyingTo == nil ? "Add a comment..." : "Add a reply...", text: $newCommentText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                        .focused($isInputFocused)
                        .lineLimit(1...5)
                    
                    Button {
                        postComment()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                    }
                    .disabled(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await loadComments()
        }
    }
    
    private func loadComments() async {
        print("🎬 Loading comments for workout: \(workoutID)")
        
        // Clear ALL cached data first - not just for this workout
        await MainActor.run {
            commentUsers = [:]
        }
        
        // Fetch fresh comments
        await commentService.fetchComments(workoutID: workoutID)
        
        // Load user data for all comments
        if let comments = commentService.comments[workoutID] {
            print("👥 Loading user data for \(comments.count) comments")
            for comment in comments {
                if commentUsers[comment.userID] == nil {
                    do {
                        if let user = try await userRepository.getUser(uid: comment.userID) {
                            await MainActor.run {
                                commentUsers[comment.userID] = user
                            }
                        }
                    } catch {
                        print("Error loading user: \(error)")
                    }
                }
            }
        } else {
            print("⚠️ No comments found in cache for workout: \(workoutID)")
        }
    }
    
    private func postComment() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let content = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        
        Task {
            do {
                try await commentService.addComment(
                    workoutID: workoutID,
                    userID: userID,
                    content: content,
                    parentCommentID: replyingTo?.id
                )
                
                await MainActor.run {
                    newCommentText = ""
                    replyingTo = nil
                    isInputFocused = false
                }
                
                // Reload to get new comment with user data
                await loadComments()
            } catch {
                print("Error posting comment: \(error)")
            }
        }
    }
}

struct CommentRowView: View {
    let workoutID: String
    let comment: Comment
    let user: User?
    let onReply: (Comment) -> Void
    
    @StateObject private var commentService = CommentService.shared
    @State private var showReplies = false
    @State private var replyUsers: [String: User] = [:]
    @StateObject private var userRepository = UserRepository()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                // Profile Picture
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            .font(.caption)
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    // Username and time
                    HStack {
                        Text(user?.username ?? "user")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text(timeAgoString(from: comment.timestamp))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Comment content
                    Text(comment.content)
                        .font(.body)
                    
                    // Actions
                    HStack(spacing: 20) {
                        // Like button
                        Button {
                            Task {
                                guard let userID = Auth.auth().currentUser?.uid else { return }
                                try? await commentService.toggleLike(
                                    workoutID: workoutID,
                                    commentID: comment.id ?? "",
                                    userID: userID,
                                    isReply: false
                                )
                                await loadLikeStatus()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: commentService.commentLikes[comment.id ?? ""] == true ? "heart.fill" : "heart")
                                    .foregroundColor(commentService.commentLikes[comment.id ?? ""] == true ? .red : .secondary)
                                if comment.likes > 0 {
                                    Text("\(comment.likes)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        // Reply button
                        Button {
                            onReply(comment)
                        } label: {
                            Text("Reply")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Show replies if any
                        if comment.replyCount > 0 {
                            Button {
                                showReplies.toggle()
                                if showReplies {
                                    Task {
                                        await loadReplies()
                                    }
                                }
                            } label: {
                                Text(showReplies ? "Hide replies" : "View \(comment.replyCount) \(comment.replyCount == 1 ? "reply" : "replies")")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                
                Spacer()
            }
            
            // Replies
            if showReplies, let replies = commentService.replies[comment.id ?? ""] {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(replies) { reply in
                        ReplyRowView(
                            workoutID: workoutID,
                            reply: reply,
                            user: replyUsers[reply.userID]
                        )
                    }
                }
                .padding(.leading, 44)
            }
        }
        .task {
            await loadLikeStatus()
        }
    }
    
    private func loadLikeStatus() async {
        guard let userID = Auth.auth().currentUser?.uid,
              let commentID = comment.id else { return }
        await commentService.checkIfLiked(workoutID: workoutID, commentID: commentID, userID: userID)
    }
    
    private func loadReplies() async {
        guard let commentID = comment.id else { return }
        await commentService.fetchReplies(workoutID: workoutID, commentID: commentID)
        
        // Load user data for replies
        if let replies = commentService.replies[commentID] {
            for reply in replies {
                if replyUsers[reply.userID] == nil {
                    do {
                        if let user = try await userRepository.getUser(uid: reply.userID) {
                            await MainActor.run {
                                replyUsers[reply.userID] = user
                            }
                        }
                    } catch {
                        print("Error loading reply user: \(error)")
                    }
                }
            }
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        if seconds < 60 {
            return "now"
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            return "\(minutes)m"
        } else if seconds < 86400 {
            let hours = Int(seconds / 3600)
            return "\(hours)h"
        } else if seconds < 604800 {
            let days = Int(seconds / 86400)
            return "\(days)d"
        } else {
            let weeks = Int(seconds / 604800)
            return "\(weeks)w"
        }
    }
}

struct ReplyRowView: View {
    let workoutID: String
    let reply: Comment
    let user: User?
    
    @StateObject private var commentService = CommentService.shared
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 28, height: 28)
                .overlay {
                    Image(systemName: "person.fill")
                        .foregroundColor(.white)
                        .font(.caption2)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(user?.username ?? "user")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text(timeAgoString(from: reply.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text(reply.content)
                    .font(.subheadline)
                
                Button {
                    Task {
                        guard let userID = Auth.auth().currentUser?.uid else { return }
                        try? await commentService.toggleLike(
                            workoutID: workoutID,
                            commentID: reply.id ?? "",
                            userID: userID,
                            isReply: true,
                            parentCommentID: reply.parentCommentID
                        )
                        await loadLikeStatus()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: commentService.commentLikes[reply.id ?? ""] == true ? "heart.fill" : "heart")
                            .foregroundColor(commentService.commentLikes[reply.id ?? ""] == true ? .red : .secondary)
                            .font(.caption)
                        if reply.likes > 0 {
                            Text("\(reply.likes)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 2)
            }
            
            Spacer()
        }
        .task {
            await loadLikeStatus()
        }
    }
    
    private func loadLikeStatus() async {
        guard let userID = Auth.auth().currentUser?.uid,
              let replyID = reply.id else { return }
        await commentService.checkIfLiked(
            workoutID: workoutID,
            commentID: replyID,
            userID: userID,
            isReply: true,
            parentCommentID: reply.parentCommentID
        )
    }
    
    private func timeAgoString(from date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        if seconds < 60 {
            return "now"
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            return "\(minutes)m"
        } else if seconds < 86400 {
            let hours = Int(seconds / 3600)
            return "\(hours)h"
        } else if seconds < 604800 {
            let days = Int(seconds / 86400)
            return "\(days)d"
        } else {
            let weeks = Int(seconds / 604800)
            return "\(weeks)w"
        }
    }
}
