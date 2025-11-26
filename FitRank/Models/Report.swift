import Foundation
import FirebaseFirestore

struct Report: Identifiable, Codable {
    @DocumentID var id: String?
    var type: ReportType // "lift", "comment", "post", etc.
    var targetID: String // ID of lift, comment, or post being reported
    var parentID: String? // For comments: the parent post ID
    var workoutID: String? // For workout comments: the parent workout ID
    var parentCommentID: String? // For comment replies: the parent comment ID
    var reason: String
    var reporterID: String
    var status: ReportStatus // "pending", "reviewed", "dismissed"
    var timestamp: Date
    
    init(id: String? = nil, type: ReportType, targetID: String, parentID: String? = nil, workoutID: String? = nil, parentCommentID: String? = nil, reason: String, reporterID: String) {
        self.id = id
        self.type = type
        self.targetID = targetID
        self.parentID = parentID
        self.workoutID = workoutID
        self.parentCommentID = parentCommentID
        self.reason = reason
        self.reporterID = reporterID
        self.status = .pending
        self.timestamp = Date()
    }
}

// Report type enum
enum ReportType: String, CaseIterable, Identifiable, Codable {
    case lift = "lift"
    case comment = "comment"
    case post = "post"
    case postComment = "post-comment"
    case workoutComment = "workout-comment"
    case workoutCommentReply = "workout-comment-reply"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .lift: return "Lift"
        case .comment: return "Comment"
        case .post: return "Post"
        case .postComment: return "Post Comment"
        case .workoutComment: return "Workout Comment"
        case .workoutCommentReply: return "Workout Comment Reply"
        }
    }
}

// Report status enum
enum ReportStatus: String, CaseIterable, Identifiable, Codable {
    case pending = "pending"
    case reviewed = "reviewed"
    case dismissed = "dismissed"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .pending: return "Pending Review"
        case .reviewed: return "Reviewed"
        case .dismissed: return "Dismissed"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "orange"
        case .reviewed: return "blue"
        case .dismissed: return "gray"
        }
    }
}

