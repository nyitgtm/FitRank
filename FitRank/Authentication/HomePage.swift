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
        List {
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
    }
}

#Preview {
    HomePage(showSignInView: .constant(false))
}
