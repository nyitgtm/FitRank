//
//  SignInEmailView.swift
//  FitRank
//
//  Created by Navraj Singh on 6/7/25.
//

import SwiftUI

@MainActor
final class SignUpEmailViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isSignedUp = false
    @Published var errorMessage: String?
    
    func signUp() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password." //In the future add 8char password etc etc etc
            //also add like password / emal requirements
            // make sure email is valid and so is password (8chars, special char, num, etc) whatever u think is appropriate
            return
            func createAuthUser() async {
                        // Validate email and password are not empty
                        guard !email.isEmpty, !password.isEmpty else {
                            errorMessage = "Please enter both email and password."
                            return
                        }
                        
                        // Validate email format
                        guard isValidEmail(email) else {
                            errorMessage = "Please enter a valid email address."
                            return
                        }
                        
                        // Validate password requirements
                        let passwordValidation = validatePassword(password)
                        guard passwordValidation.isValid else {
                            errorMessage = passwordValidation.errorMessage
                            return
                        }
                        
                        // ... rest of your existing code
                    }
                    
                    // MARK: - Password Validation Functions

                    func isValidEmail(_ email: String) -> Bool {
                        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
                        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
                        return emailPredicate.evaluate(with: email)
                    }

                    func validatePassword(_ password: String) -> (isValid: Bool, errorMessage: String?) {
                        // Check minimum length
                        guard password.count >= 8 else {
                            return (false, "Password must be at least 8 characters long.")
                        }
                        
                        // Check maximum length (Firebase limit)
                        guard password.count <= 4096 else {
                            return (false, "Password must be less than 4096 characters.")
                        }
                        
                        // Check for at least one uppercase letter
                        let uppercaseRegex = ".*[A-Z]+.*"
                        guard NSPredicate(format: "SELF MATCHES %@", uppercaseRegex).evaluate(with: password) else {
                            return (false, "Password must contain at least one uppercase letter.")
                        }
                        
                        // Check for at least one lowercase letter
                        let lowercaseRegex = ".*[a-z]+.*"
                        guard NSPredicate(format: "SELF MATCHES %@", lowercaseRegex).evaluate(with: password) else {
                            return (false, "Password must contain at least one lowercase letter.")
                        }
                        
                        // Check for at least one special character
                        let specialCharRegex = ".*[!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>\\/?]+.*"
                        guard NSPredicate(format: "SELF MATCHES %@", specialCharRegex).evaluate(with: password) else {
                            return (false, "Password must contain at least one special character.")
                        }
                        
                        return (true, nil)
                    }

        }
        
        Task{
            do {
                let returnedUserData = try await AuthenticationManager.shared.createUser(email: email, password: password)
                print(returnedUserData)
                isSignedUp = true // should we redirect them to the homepage or signin page????
                
            } catch {
                errorMessage = "Sign-Up failed." // hi frontend team please put appropriate signup fail error messages
                print("Sign-in error: \(error)")
            }
        }
        
    }
}

struct SignUpEmailView: View {
    @StateObject private var viewModel = SignUpEmailViewModel()
    @Binding var showSignInView: Bool
    
    var body: some View {
        VStack {
            TextField("Email", text: $viewModel.email)
                .padding()
                .background(Color.gray.opacity(0.5))
                .cornerRadius(8)
            
            SecureField("Password", text: $viewModel.password)
                .padding()
                .background(Color.gray.opacity(0.5))
                .cornerRadius(8)
            
            //make this look prettier
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            Button {
                viewModel.signUp()
            } label: {
                Text("Sign Up")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(10)
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Sign Up")
        .onChange(of: viewModel.isSignedUp) {
            if viewModel.isSignedUp {
                showSignInView = false
            }
        }
    }
}

#Preview {
    SignUpEmailView(showSignInView: .constant(false))
}

