//
//  ContentView.swift
//  FitRank
//
//  Created by Navraj Singh on 6/7/25.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showSignInView = true
    @AppStorage("hasSeenAppDisclaimer") private var hasSeenAppDisclaimer = false
    @State private var showAppDisclaimer = false

    var body: some View {
        Group {
            if showSignInView {
                AuthenticationView(showSignInView: $showSignInView)
            } else {
                TabContainerView(showSignInView: $showSignInView)
            }
        }
        .themedBackground()
        .tint(themeManager.selectedTheme.accentColor)
        .onAppear {
            showSignInView = (Auth.auth().currentUser == nil)
            if !showSignInView && !hasSeenAppDisclaimer {
                showAppDisclaimer = true
            }
        }
        .sheet(isPresented: $showAppDisclaimer) {
            GeneralAppDisclaimerView {
                hasSeenAppDisclaimer = true
                showAppDisclaimer = false
            }
        }
    }
}

#Preview {
    ContentView().environmentObject(ThemeManager.shared)
}

// MARK: - General App Disclaimer
struct GeneralAppDisclaimerView: View {
    let onAccept: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Icon
                    HStack {
                        Spacer()
                        Image(systemName: "exclamationmark.shield.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        Spacer()
                    }
                    .padding(.top, 20)
                    
                    // Title
                    Text("Important Safety Information")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    
                    Text("Please read carefully before using FitRank")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    
                    // Disclaimer content
                    VStack(alignment: .leading, spacing: 16) {
                        GeneralDisclaimerSection(
                            icon: "figure.strengthtraining.traditional",
                            title: "Fitness & Exercise",
                            content: "FitRank is a fitness tracking app, not a substitute for professional training or medical advice. Weight lifting and exercise carry inherent risks. Always use proper form, appropriate weights, and safety equipment. Consult a healthcare provider before starting any fitness program.",
                            color: .red
                        )
                        
                        GeneralDisclaimerSection(
                            icon: "fork.knife",
                            title: "Nutrition Information",
                            content: "All calorie calculations and nutrition data are estimates. Individual needs vary greatly. The app is not a replacement for professional nutritional or medical advice. Consult with a registered dietitian or healthcare provider for personalized guidance.",
                            color: .green
                        )
                        
                        GeneralDisclaimerSection(
                            icon: "person.3.fill",
                            title: "User-Generated Content",
                            content: "Community posts and content are created by users and do not reflect FitRank's views. Users are responsible for their own content. Report inappropriate content through the app.",
                            color: .blue
                        )
                        
                        GeneralDisclaimerSection(
                            icon: "hand.raised.fill",
                            title: "Assumption of Risk",
                            content: "By using FitRank, you acknowledge and accept all risks associated with fitness activities, nutrition tracking, and app use. You agree to use the app at your own risk.",
                            color: .orange
                        )
                        
                        GeneralDisclaimerSection(
                            icon: "doc.text.fill",
                            title: "No Liability",
                            content: "FitRank and its developers are not liable for injuries, health issues, or damages resulting from app use. This includes but is not limited to workout injuries, nutritional issues, or reliance on app information.",
                            color: .gray
                        )
                    }
                    
                    // Key reminders
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Key Safety Reminders:")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        SafetyReminder(text: "Form over ego - lift safely")
                        SafetyReminder(text: "Listen to your body")
                        SafetyReminder(text: "Consult professionals for guidance")
                        SafetyReminder(text: "Stop if you experience pain")
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Accept button
                    Button(action: onAccept) {
                        Text("I Understand and Accept")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.top, 20)
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled()
    }
}

struct GeneralDisclaimerSection: View {
    let icon: String
    let title: String
    let content: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Text(content)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SafetyReminder: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.orange)
                .font(.caption)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}
