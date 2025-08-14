//
//  TabContainerView.swift
//  FitRank
//
//  Created by Navraj Singh on 8/9/25.
//

import SwiftUI

struct TabContainerView: View {
    @Binding var showSignInView: Bool
    @State private var selectedRoute: PageRoute = .home

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch selectedRoute {
                case .home:
                    HomePageContent(showSignInView: $showSignInView)
                case .heatmap:
                    Heatmap()
                case .comingSoon:
                    Text("COMING SOON")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            NavBar(selectedRoute: $selectedRoute)
                .padding(.bottom, 20)
                .background(Color.white)
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}

#Preview {
    TabContainerView(showSignInView: .constant(false))
}
