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
            targetId: targetId
        )
    }
}
