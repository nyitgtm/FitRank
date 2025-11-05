//
//  TabContainerView.swift
//  FitRank
//
//  Created by Navraj Singh on 8/9/25.
//

import SwiftUI

struct TabContainerView: View {
    @StateObject private var userViewModel = UserViewModel()
    @StateObject private var themeManager = ThemeManager.shared
    @Binding var showSignInView: Bool 
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            CommunityView()
                .tabItem {
                    Image(systemName: "person.3.fill")
                    Text("Community")
                }
            
            UploadView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Upload")
                }
            
            NutritionMainView()
                .tabItem {
                    Image(systemName: "fork.knife")
                    Text("Nutrition")
                }
            
            ProfileView(showSignInView: $showSignInView)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
        .accentColor(.blue)
        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
        .onAppear {
            
        }
    }
}

#Preview {
    TabContainerView(showSignInView: .constant(false))
}
