//
//  ContentView.swift
//  FitRank
//
//  Created by Navraj Singh on 6/7/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var userViewModel = UserViewModel()
    
    var body: some View {
        Group {
            if userViewModel.isAuthenticated {
                TabContainerView()
            } else {
                // For now, just show the main app since we're using mock data
                TabContainerView()
            }
        }
        .onAppear {
            userViewModel.checkAuthenticationStatus()
        }
    }
}

#Preview {
    ContentView()
}
