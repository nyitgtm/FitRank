//
//  HomePageContent.swift
//  FitRank
//
//  Created by Navraj Singh on 6/8/25.
//

import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    func logOut() throws {
        try AuthenticationManager.shared.signOut()
    }
}

struct HomePageContent: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Binding var showSignInView: Bool
    
    var body: some View {
        VStack {
            Text("HOMEPAGE")
                .font(.largeTitle)
                .padding()
            
            Image(systemName: "gear")
                .frame(width: 30, height: 30)
                .onTapGesture {
                    // TODO: Navigate to settings page
                }
            
            List {
                // This button is just for test env / we will make settings page soon
                Button("Log Out") {
                    Task {
                        do {
                            try viewModel.logOut()
                            showSignInView = true
                        } catch {
                            print(error)
                            // Handle error properly in the future
                        }
                    }
                }
            }
            
            Spacer()
        }
    }
}

#Preview {
    HomePageContent(showSignInView: .constant(false))
}
