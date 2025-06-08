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
    
    func signUp() {
        guard !email.isEmpty, !password.isEmpty else {
            print("No email/pass") //In the future add 8char password etc etc etc
            return
        }
        
        Task{
            do {
                let returnedUserData = try await AuthenticationManager.shared.createUser(email: email, password: password)
                print(returnedUserData)
            } catch {
                print("error")
                print(error)
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
            
            Button {
                viewModel.signUp()
                showSignInView = false
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
    }
}

#Preview {
    SignUpEmailView(showSignInView: .constant(false))
}
