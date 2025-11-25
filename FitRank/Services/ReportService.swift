import Foundation
import FirebaseFirestore
import FirebaseAuth

class ReportService: ObservableObject {
    static let shared = ReportService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    func submitReport(type: ReportType, targetID: String, reason: String) async throws {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "ReportService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        let report = Report(
            type: type,
            targetID: targetID,
            reason: reason,
            reporterID: currentUserID
        )
        
        do {
            try db.collection("reports").addDocument(from: report)
            print("✅ Report submitted successfully")
        } catch {
            print("❌ Error submitting report: \(error)")
            throw error
        }
    }
}
