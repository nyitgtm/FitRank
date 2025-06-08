//
//  AuthenticationView.swift
//  FitRank
//
//  Created by Navraj Singh on 6/7/25.
//

import SwiftUI

struct AuthenticationView: View {
    @Binding var showSignInView: Bool
    
    var body: some View {
        VStack {
            NavigationLink {
                SignUpEmailView(showSignInView: $showSignInView)
            } label: {
                Text("Sign Up")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(10)
            }
            NavigationLink {
                SignInEmailView(showSignInView: $showSignInView)
            } label: {
                Text("Sign In")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(10)
            }
        }
        .padding()
        .navigationTitle("Choose Options")
    }
}

#Preview {
    NavigationStack {
        AuthenticationView(showSignInView: .constant(false))
    }
}
