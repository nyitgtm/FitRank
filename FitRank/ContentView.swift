//
//  ContentView.swift
//  FitRank
//
//  Created by Navraj Singh on 6/7/25.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showSignInView = true

    var body: some View {
        Group {
            if showSignInView {
                AuthenticationView(showSignInView: $showSignInView)
            } else {
                TabContainerView(showSignInView: $showSignInView)
            }
        }
        .themedBackground()
        .tint(themeManager.selectedTheme.accentColor)
        .onAppear {
            showSignInView = (Auth.auth().currentUser == nil)
        }
    }
}

#Preview {
    ContentView().environmentObject(ThemeManager.shared)
}
