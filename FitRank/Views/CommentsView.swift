import SwiftUI

struct CommentsView: View {
    let workout: Workout
    let commentViewModel: CommentViewModel
    
    @State private var newComment = ""
    @State private var editingComment: Comment?
    @State private var editText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Comments List
                if commentViewModel.isLoading {
                    ProgressView("Loading comments...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if commentViewModel.comments.isEmpty {
                    EmptyCommentsView()
                } else {
                    List {
                        ForEach(commentViewModel.comments) { comment in
                            CommentRowView(
                                comment: comment,
                                onEdit: {
                                    editingComment = comment
                                    editText = comment.content
                                },
                                onDelete: {
                                    Task {
                                        await commentViewModel.deleteComment(comment)
                                    }
                                },
                                onLike: {
                                    Task {
                                        await commentViewModel.likeComment(comment)
                                    }
                                },
                                onDislike: {
                                    Task {
                                        await commentViewModel.dislikeComment(comment)
                                    }
                                }
                            )
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                
                // Comment Input
                CommentInputView(
                    text: $newComment,
                    isPosting: commentViewModel.isPosting,
                    onSubmit: {
                        Task {
                            await commentViewModel.postComment(
                                content: newComment,
                                for: workout.id ?? ""
                            )
                            newComment = ""
                        }
                    }
                )
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Dismiss view
                    }
                }
            }
        }
        .onAppear {
            Task {
                await commentViewModel.fetchComments(for: workout.id ?? "")
            }
        }
        .alert("Edit Comment", isPresented: Binding(
            get: { editingComment != nil },
            set: { if !$0 { editingComment = nil } }
        )) {
            TextField("Comment", text: $editText, axis: .vertical)
                .lineLimit(3...6)
            
            Button("Save") {
                if let comment = editingComment {
                    Task {
                        await commentViewModel.updateComment(comment, newContent: editText)
                        editingComment = nil
                        editText = ""
                    }
                }
            }
            
            Button("Cancel", role: .cancel) {
                editingComment = nil
                editText = ""
            }
        } message: {
            Text("Update your comment")
        }
        .alert("Error", isPresented: Binding(
            get: { commentViewModel.errorMessage != nil },
            set: { if !$0 { commentViewModel.clearError() } }
        )) {
            Button("OK") {
                commentViewModel.clearError()
            }
        } message: {
            if let errorMessage = commentViewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

// MARK: - Comment Row View

struct CommentRowView: View {
    let comment: Comment
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onLike: () -> Void
    let onDislike: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Comment header
            HStack {
                Text("User") // Would need to fetch actual user name
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(comment.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Edit/Delete menu for comment owner
                Menu {
                    Button("Edit", action: onEdit)
                    Button("Delete", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Comment content
            Text(comment.content)
                .font(.body)
                .multilineTextAlignment(.leading)
            
            // Interaction buttons
            HStack(spacing: 16) {
                Button(action: onLike) {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.thumbsup")
                            .font(.caption)
                        Text("\(comment.likes)")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                
                Button(action: onDislike) {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.thumbsdown")
                            .font(.caption)
                        Text("\(comment.dislikes)")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Comment Input View

struct CommentInputView: View {
    @Binding var text: String
    let isPosting: Bool
    let onSubmit: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                TextField("Add a comment...", text: $text, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(1...3)
                
                Button(action: onSubmit) {
                    if isPosting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isPosting)
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Empty Comments View

struct EmptyCommentsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Comments Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Be the first to comment on this workout!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    CommentsView(
        workout: Workout(
            userId: "user123",
            teamId: "teams/1",
            videoUrl: "https://example.com/video.mp4",
            weight: 225,
            liftType: .bench
        ),
        commentViewModel: CommentViewModel()
    )
}
