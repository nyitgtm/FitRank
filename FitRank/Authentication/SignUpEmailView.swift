//
//  SignUpEmailView.swift
//  FitRank
//
//  Created by Navraj Singh on 6/7/25.
//

import SwiftUI
import FirebaseFirestore
import Foundation
import FirebaseAuth

@MainActor
final class SignUpEmailViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var name = ""
    @Published var username = ""
    @Published var selectedTeam: Team?
    
    @Published var currentStep: SignUpStep = .credentials
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSignUpComplete = false
    
    let userRepository = UserRepository()
    let authManager = AuthenticationManager.shared
    
    enum SignUpStep {
        case credentials
        case userInfo
        case teamSelection
        case complete
    }
    
    // Validation functions
    private func validateEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func validatePassword(_ password: String) -> Bool {
        return password.count >= 8 && hasNumber(password) && hasUppercase(password) && hasSpecialCharacter(password)
    }
    
    func hasMinLength(_ password: String) -> Bool {
        return password.count >= 8
    }
    
    func hasNumber(_ password: String) -> Bool {
        return password.range(of: "[0-9]", options: .regularExpression) != nil
    }
    
    func hasUppercase(_ password: String) -> Bool {
        return password.range(of: "[A-Z]", options: .regularExpression) != nil
    }
    
    func hasSpecialCharacter(_ password: String) -> Bool {
        return password.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil
    }
    
    private func validateUsername(_ username: String) -> Bool {
        return username.count >= 4
    }
    
    // Step 1: Create Firebase Auth user
    func createAuthUser() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password."
            return
        }
        
        guard validateEmail(email) else {
            errorMessage = "Please enter a valid email address."
            return
        }
        
        guard validatePassword(password) else {
            errorMessage = "Password must meet all requirements."
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await authManager.createUser(email: email, password: password)
            currentStep = .userInfo
        } catch {
            errorMessage = "Failed to create account. Please try again."
            print("Auth error: \(error)")
        }
        
        isLoading = false
    }
    
    // Step 2: Validate user info and check username
    func validateUserInfo() async {
        guard !name.isEmpty, !username.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        
        guard validateUsername(username) else {
            errorMessage = "Username must be at least 4 characters long."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let isAvailable = try await userRepository.isUsernameAvailable(username)
            if isAvailable {
                currentStep = .teamSelection
            } else {
                errorMessage = "Username already exists. Please choose a different one."
            }
        } catch {
            errorMessage = "Failed to check username availability. Please try again."
            print("Username check error: \(error)")
        }
        
        isLoading = false
    }
    
    // Step 3: Complete signup with team selection
    func completeSignUp() async {
        guard let selectedTeam = selectedTeam else {
            errorMessage = "Please select a team."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            guard let uid = Auth.auth().currentUser?.uid else {
                errorMessage = "User not logged in."
                isLoading = false
                return
            }

            let teamRef = userRepository.getTeamReference(teamId: selectedTeam.id ?? "")
            
            let user = User(
                id: uid,
                name: name,
                team: "/teams/\(selectedTeam.id ?? "")",  // store as path reference
                isCoach: false,
                username: username,
                tokens: 0
            )
            
            try await userRepository.createUser(user)
            currentStep = .complete
            isSignUpComplete = true
        } catch {
            errorMessage = "Failed to complete signup. Please try again."
            print("User creation error: \(error)")
        }
        
        isLoading = false
    }
    
    func resetSignUp() {
        currentStep = .credentials
        isSignUpComplete = false
        errorMessage = nil
        isLoading = false
    }
}

struct SignUpEmailView: View {
    @StateObject private var viewModel = SignUpEmailViewModel()
    @Binding var showSignInView: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Join FitRank and start your fitness journey")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Progress indicator
                ProgressView(value: progressValue)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .padding(.horizontal)
                
                // Content based on current step
                Group {
                    switch viewModel.currentStep {
                    case .credentials:
                        CredentialsStepView(viewModel: viewModel)
                    case .userInfo:
                        UserInfoStepView(viewModel: viewModel)
                    case .teamSelection:
                        TeamSelectionStepView(viewModel: viewModel)
                    case .complete:
                        SignUpCompleteView(viewModel: viewModel, showSignInView: $showSignInView)
                    }
                }
                .animation(.easeInOut, value: viewModel.currentStep)
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
        .onChange(of: viewModel.isSignUpComplete) { _, completed in
            if completed {
                showSignInView = false
            }
        }
    }
    
    private var progressValue: Double {
        switch viewModel.currentStep {
        case .credentials: return 0.25
        case .userInfo: return 0.5
        case .teamSelection: return 0.75
        case .complete: return 1.0
        }
    }
}

// MARK: - Step Views

struct CredentialsStepView: View {
    @ObservedObject var viewModel: SignUpEmailViewModel
    
    var body: some View {
        VStack(spacing: 16) {
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
                
                SecureField("Create a password", text: $viewModel.password)
                    .textFieldStyle(ModernTextFieldStyle())
                    .textContentType(.newPassword)
                
                // Password requirements checklist
                if !viewModel.password.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        PasswordRequirementRow(
                            text: "At least 8 characters",
                            isMet: viewModel.hasMinLength(viewModel.password)
                        )
                        PasswordRequirementRow(
                            text: "Contains a number",
                            isMet: viewModel.hasNumber(viewModel.password)
                        )
                        PasswordRequirementRow(
                            text: "Contains an uppercase letter",
                            isMet: viewModel.hasUppercase(viewModel.password)
                        )
                        PasswordRequirementRow(
                            text: "Contains a special character",
                            isMet: viewModel.hasSpecialCharacter(viewModel.password)
                        )
                    }
                    .padding(.top, 4)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Confirm Password")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                SecureField("Re-enter your password", text: $viewModel.confirmPassword)
                    .textFieldStyle(ModernTextFieldStyle())
                    .textContentType(.newPassword)
                
                if !viewModel.confirmPassword.isEmpty && viewModel.password != viewModel.confirmPassword {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                        Text("Passwords do not match")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    .padding(.top, 4)
                }
            }
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
            
            Button(action: {
                Task {
                    await viewModel.createAuthUser()
                }
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Continue")
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
    }
}

struct UserInfoStepView: View {
    @ObservedObject var viewModel: SignUpEmailViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Full Name")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextField("Enter your full name", text: $viewModel.name)
                    .textFieldStyle(ModernTextFieldStyle())
                    .textContentType(.name)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Username")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextField("Choose a username", text: $viewModel.username)
                    .textFieldStyle(ModernTextFieldStyle())
                    .textContentType(.username)
                    .autocapitalization(.none)
            }
            

            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
            
            Button(action: {
                Task {
                    await viewModel.validateUserInfo()
                }
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Continue")
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
            
            Button("Back") {
                viewModel.currentStep = .credentials
            }
            .foregroundColor(.blue)
        }
    }
}

struct TeamSelectionStepView: View {
    @ObservedObject var viewModel: SignUpEmailViewModel
    @State private var teams: [Team] = []
    @State private var isLoadingTeams = true
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Choose Your Team")
                .font(.headline)
                .foregroundColor(.primary)
            
            if isLoadingTeams {
                ProgressView("Loading teams...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(teams) { team in
                        TeamSelectionCard(
                            team: team,
                            isSelected: viewModel.selectedTeam?.id == team.id,
                            onTap: {
                                viewModel.selectedTeam = team
                            }
                        )
                    }
                }
            }
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
            
            Button(action: {
                Task {
                    await viewModel.completeSignUp()
                }
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Complete Sign Up")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(viewModel.isLoading || viewModel.selectedTeam == nil)
            
            Button("Back") {
                viewModel.currentStep = .userInfo
            }
            .foregroundColor(.blue)
        }
        .task {
            await loadTeams()
        }
    }
    
    private func loadTeams() async {
        do {
            teams = try await viewModel.userRepository.getTeams()
            isLoadingTeams = false
        } catch {
            viewModel.errorMessage = "Failed to load teams. Please try again."
            isLoadingTeams = false
        }
    }
}

struct TeamSelectionCard: View {
    let team: Team
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                if let icon = team.icon {
                    Image(systemName: icon)
                        .font(.system(size: 32))
                        .foregroundColor(Color(team.color))
                } else {
                    Circle()
                        .fill(Color(team.color))
                        .frame(width: 40, height: 40)
                }
                
                Text(team.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SignUpCompleteView: View {
    @ObservedObject var viewModel: SignUpEmailViewModel
    @Binding var showSignInView: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Welcome to FitRank!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Your account has been created successfully. You can now sign in and start your fitness journey!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Sign In") {
                showSignInView = true
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .fontWeight(.semibold)
        }
        .padding()
    }
}

// MARK: - Custom Styles

struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
    }
}

struct PasswordRequirementRow: View {
    let text: String
    let isMet: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isMet ? .green : .gray)
                .font(.caption)
            Text(text)
                .font(.caption)
                .foregroundColor(isMet ? .green : .gray)
        }
    }
}

#Preview {
    SignUpEmailView(showSignInView: .constant(false))
}
