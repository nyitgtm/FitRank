//
//  ContentView.swift
//  FitRank
//
//  Created by Navraj Singh on 6/7/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var userViewModel = UserViewModel()
    @State private var showSignInView = false
    
    var body: some View {
        Group {
            if showSignInView {
                AuthenticationView(showSignInView: $showSignInView)
            } else {
                TabContainerView(showSignInView: $showSignInView)
            }
        }
        .onAppear {
            userViewModel.checkAuthenticationStatus()
            showSignInView = !userViewModel.isAuthenticated
        }
    }
}


#Preview {
    ContentView()
}
