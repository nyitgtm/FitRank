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
    
    func signIn() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password." //In the future add 8char password etc etc etc
            return
        }
        
        Task{
            do {
                let returnedUserData = try await AuthenticationManager.shared.signIn(email: email, password: password)
                print(returnedUserData)
                isSignedIn = true // can we have some nice message or something or like animation
            } catch {
                //these print stuff just for me in the console / can delete later going into prod!!
                print("error")
                print(error)
                // smh im helping front end team
                errorMessage = "Sign-in failed. Please check your credentials."
                print("Sign-in error: \(error)")
            }
        }
        
    }
}


struct SignInEmailView: View {
    @StateObject private var viewModel = SignInEmailViewModel()
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
                viewModel.signIn()
            } label: {
                Text("Sign In")
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
        .navigationTitle("Sign In")
        .onChange(of: viewModel.isSignedIn) {
            if viewModel.isSignedIn {
                showSignInView = false
            }
        }
    }
}

#Preview {
    SignInEmailView(showSignInView: .constant(false))
}
