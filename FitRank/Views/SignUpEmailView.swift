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
