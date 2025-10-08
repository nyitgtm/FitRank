//
//  SignInEmailView.swift
//  FitRank
//
//  Created by Navraj Singh on 6/8/25.
//

import SwiftUI

@MainActor
final class SignInEmailViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isSignedIn = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    func signIn() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let returnedUserData = try await AuthenticationManager.shared.signIn(email: email, password: password)
                print(returnedUserData)
                isSignedIn = true
            } catch {
                print("Sign-in error: \(error)")
                errorMessage = "Sign-in failed. Please check your credentials."
            }
            
            isLoading = false
        }
    }
}


struct SignInEmailView: View {
    @StateObject private var viewModel = SignInEmailViewModel()
    @Binding var showSignInView: Bool
    @State private var showSignUp = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Welcome Back")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Sign in to continue your fitness journey")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Form
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Enter your email", text: $viewModel.email)
                            .textFieldStyle(ModernTextFieldStyle())
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        SecureField("Enter your password", text: $viewModel.password)
                            .textFieldStyle(ModernTextFieldStyle())
                            .textContentType(.password)
                    }
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button(action: {
                        viewModel.signIn()
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Sign In")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isLoading)
                }
                
                Spacer()
                
                // Footer
                VStack(spacing: 16) {
                    Text("Don't have an account?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Create Account") {
                        showSignUp = true
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showSignUp) {
            NavigationStack {
                SignUpEmailView(showSignInView: $showSignInView)
            }
        }
        .onChange(of: viewModel.isSignedIn) { _, isSignedIn in
            if isSignedIn {
                showSignInView = false
            }
        }
    }
}



#Preview {
    SignInEmailView(showSignInView: .constant(false))
}
