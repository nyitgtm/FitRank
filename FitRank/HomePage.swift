//
//  HomePage.swift
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

struct HomePage: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Binding var showSignInView: Bool
    var body: some View {
        Text("HOMEPAGE")
        .padding()
        
        Image(systemName: "gear")
            .frame(width: 30, height: 30)
            .onTapGesture {
                //send to settings page
            }
        
        List {
            //This button is just for test env / we will make settings page soon
            Button("Log Out") {
                Task {
                    do {
                        try viewModel.logOut()
                        showSignInView = true
                    } catch {
                        print(error)
                        //Handle this in the future thanks nav
                    }
                }
            }
        }
        
        Spacer()
        
        NavBar() // located in FitRank/Components/NavBar
                // wanted to keep things nice and reusable/modular
    }
}

#Preview {
    HomePage(showSignInView: .constant(false))
}
