import SwiftUI

struct ReportSheet: View {
    @Binding var isPresented: Bool
    let reportType: ReportType
    let targetId: String
    
    @State private var selectedReason: String = ""
    @State private var customReason: String = ""
    @State private var isSubmitting = false
    
    let reasons = [
        "Inappropriate content",
        "Spam or misleading",
        "Harassment or bullying",
        "Dangerous acts",
        "Other"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Why are you reporting this?")) {
                    ForEach(reasons, id: \.self) { reason in
                        Button {
                            selectedReason = reason
                        } label: {
                            HStack {
                                Text(reason)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedReason == reason {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                if selectedReason == "Other" {
                    Section(header: Text("Please specify")) {
                        TextField("Reason", text: $customReason)
                    }
                }
                
                Section {
                    Button {
                        submitReport()
                    } label: {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Submit Report")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.red)
                        }
                    }
                    .disabled(selectedReason.isEmpty || (selectedReason == "Other" && customReason.isEmpty) || isSubmitting)
                }
            }
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func submitReport() {
        isSubmitting = true
        
        let reason = selectedReason == "Other" ? customReason : selectedReason
        
        Task {
            do {
                try await ReportService.shared.submitReport(
                    type: reportType,
                    targetID: targetId,
                    reason: reason
                )
                await MainActor.run {
                    isPresented = false
                }
            } catch {
                print("Error submitting report: \(error)")
                await MainActor.run {
                    isSubmitting = false
                }
            }
        }
    }
}
