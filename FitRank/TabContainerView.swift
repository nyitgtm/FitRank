//
//  TabContainerView.swift
//  FitRank
//
//  Created by Navraj Singh on 8/9/25.
//

import SwiftUI

struct TabContainerView: View {
    @StateObject private var userViewModel = UserViewModel()
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            UploadView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Upload")
                }
            
            HeatmapView()
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Heatmap")
                }
            
            LeaderboardView()
                .tabItem {
                    Image(systemName: "list.number")
                    Text("Leaderboard")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
        .accentColor(.blue)
    }
}

#Preview {
    TabContainerView()
}
