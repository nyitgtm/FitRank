//
//  TabContainerView.swift
//  FitRank
//
//  Created by Navraj Singh on 8/9/25.
//

import SwiftUI

struct TabContainerView: View {
    @StateObject private var userViewModel = UserViewModel()
    @Binding var showSignInView: Bool 
    
    var body: some View {
        TabView {
            HomeView()//pass this in future showSignInView: $showSignInView)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            UploadView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Upload")
                }
            
            Heatmap()
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Heatmap")
                }
            
            LeaderboardView()
                .tabItem {
                    Image(systemName: "list.number")
                    Text("Leaderboard")
                }
            
            ProfileView(showSignInView: $showSignInView)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
        .accentColor(.blue)
    }
}

#Preview {
    TabContainerView(showSignInView: .constant(false))
}
