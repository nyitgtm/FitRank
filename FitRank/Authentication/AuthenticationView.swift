//
//  AuthenticationView.swift
//  FitRank
//
//  Created by Navraj Singh on 6/7/25.
//

import SwiftUI

struct AuthenticationView: View {
    @Binding var showSignInView: Bool
    @State private var showAboutInfo = false
    @State private var showSignUp = false
    @State private var showSignIn = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.8),
                    Color.purple.opacity(0.6),
                    Color.blue.opacity(0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo and main tagline
                VStack(spacing: 16) {
                    Image(systemName: "figure.run.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Text("FitRank")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                    
                    VStack(spacing: 8) {
                        Text("Track")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("Compete")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("Repeat")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                
                Spacer()
                
                // Action buttons section
                VStack(spacing: 16) {
                    // Sign Up button
                    Button {
                        showSignUp = true
                    } label: {
                        HStack {
                            Image(systemName: "person.badge.plus")
                                .font(.title2)
                            Text("Create Account")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(height: 56)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    
                    // Sign In button
                    Button {
                        showSignIn = true
                    } label: {
                        HStack {
                            Image(systemName: "person.circle")
                                .font(.title2)
                            Text("Sign In")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.blue)
                        .frame(height: 56)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.white)
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        )
                    }
                    
                    // About button
                    Button(action: {
                        showAboutInfo = true
                    }) {
                        HStack {
                            Image(systemName: "info.circle")
                                .font(.title3)
                            Text("About FitRank")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.15))
                        )
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
        .sheet(isPresented: $showAboutInfo) {
            AboutFitRankView()
        }
        .sheet(isPresented: $showSignUp) {
            NavigationStack {
                SignUpEmailView(showSignInView: $showSignInView)
            }
        }
        .sheet(isPresented: $showSignIn) {
            NavigationStack {
                SignInEmailView(showSignInView: $showSignInView)
            }
        }
    }
}

struct AboutFitRankView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "figure.run.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("About FitRank")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Track, Compete, Repeat")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What is FitRank?")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("FitRank is a comprehensive fitness tracking and competition platform that allows users to monitor their workouts, compete with others, and track their progress over time. Whether you're a fitness enthusiast or a competitive athlete, FitRank provides the tools you need to achieve your fitness goals.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 20)
                    
                    // Team section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Development Team")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            TeamMemberRow(name: "Armaan Binning", role: "Leader / Product Owner")
                            TeamMemberRow(name: "Navraj Singh", role: "Co-Leader / Scrum Master")
                            TeamMemberRow(name: "Mahdi Tahiri", role: "Lead Backend")
                            TeamMemberRow(name: "Bikram Singh", role: "Lead Frontend")
                            TeamMemberRow(name: "Benoy Thomas", role: "Program Tester")
                            TeamMemberRow(name: "Anmolak Singh", role: "Program Tester")
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

struct TeamMemberRow: View {
    let name: String
    let role: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(role)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    NavigationStack {
        AuthenticationView(showSignInView: .constant(false))
    }
}
