import Foundation
import FirebaseFirestore

struct Report: Identifiable, Codable {
    @DocumentID var id: String?
    var type: ReportType // "lift" or "comment"
    var targetID: String // ID of lift or comment being reported
    var reason: String
    var reporterID: String
    var status: ReportStatus // "pending", "reviewed", "dismissed"
    var timestamp: Date
    
    init(id: String? = nil, type: ReportType, targetID: String, reason: String, reporterID: String) {
        self.id = id
        self.type = type
        self.targetID = targetID
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
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .lift: return "Lift"
        case .comment: return "Comment"
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

