import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Contact Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Need Help?")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("If you're experiencing issues or have questions, please contact our support team.")
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.blue)
                            Text("fitrank.control@gmail.com")
                                .fontWeight(.medium)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    Divider()
                    
                    // FAQ Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Frequently Asked Questions")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        FAQItem(
                            question: "How do I reset my password?",
                            answer: "You can reset your password from the Sign In screen by tapping 'Forgot Password?'."
                        )
                        
                        FAQItem(
                            question: "How do I delete my account?",
                            answer: "Go to your Profile, scroll down to Settings, and tap 'Delete Account'. Note that this action is irreversible after a grace period."
                        )
                        
                        FAQItem(
                            question: "Why can't I sign in?",
                            answer: "If you deleted your account, it may be suspended. Contact support if you believe this is an error."
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(question)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .foregroundColor(.secondary)
                }
            }
            
            if isExpanded {
                Text(answer)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    HelpView()
}
