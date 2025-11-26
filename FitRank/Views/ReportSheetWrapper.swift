import SwiftUI

// Wrapper to handle dismissal properly with item-based sheet
struct ReportSheetWrapper: View {
    let reportType: ReportType
    let targetId: String
    @Binding var reportingPost: CommunityPost?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ReportSheet(
            isPresented: Binding(
                get: { reportingPost != nil },
                set: { if !$0 { reportingPost = nil } }
            ),
            reportType: reportType,
            targetId: targetId,
            parentId: nil,
            workoutId: nil,
            parentCommentId: nil
        )
    }
}

// Wrapper for post comment reporting
struct CommentReportSheetWrapper: View {
    let commentId: String
    let postId: String
    @Binding var reportingComment: CommunityComment?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ReportSheet(
            isPresented: Binding(
                get: { reportingComment != nil },
                set: { if !$0 { reportingComment = nil } }
            ),
            reportType: .postComment,
            targetId: commentId,
            parentId: postId,
            workoutId: nil,
            parentCommentId: nil
        )
    }
}

// Wrapper for workout comment reporting
struct WorkoutCommentReportSheetWrapper: View {
    let commentId: String
    let workoutId: String
    @Binding var reportingComment: Comment?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ReportSheet(
            isPresented: Binding(
                get: { reportingComment != nil },
                set: { if !$0 { reportingComment = nil } }
            ),
            reportType: .workoutComment,
            targetId: commentId,
            parentId: nil,
            workoutId: workoutId,
            parentCommentId: nil
        )
    }
}

// Wrapper for workout comment reply reporting
struct WorkoutCommentReplyReportSheetWrapper: View {
    let replyId: String
    let workoutId: String
    let parentCommentId: String
    @Binding var reportingReply: Comment?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ReportSheet(
            isPresented: Binding(
                get: { reportingReply != nil },
                set: { if !$0 { reportingReply = nil } }
            ),
            reportType: .workoutCommentReply,
            targetId: replyId,
            parentId: nil,
            workoutId: workoutId,
            parentCommentId: parentCommentId
        )
    }
}
