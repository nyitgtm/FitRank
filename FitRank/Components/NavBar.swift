//
//  NavBar.swift
//  FitRank
//
//  Created by Navraj Singh on 6/19/25.
//

import SwiftUI

// Create an Enum for Routes
enum PageRoute: Identifiable {
    case home
    case heatmap
    case comingSoon

    var id: String {
        switch self {
        case .home: return "home"
        case .heatmap: return "heatmap"
        case .comingSoon: return "comingSoon"
        }
    }
}

struct NavBar: View {
    @State private var selectedRoute: PageRoute? = nil
//    Can we pass some variables or not hardcode this as much so we can control the bacground color and opacity
    // bc we will have this in different areas. @frontend team

    let icons: [(name: String, route: PageRoute)] = [
        ("house.fill", .home),
        ("map.fill", .heatmap),
        ("plus.circle.fill", .comingSoon),
        ("camera.fill", .comingSoon),
        ("person.fill", .comingSoon)
    ]

    var body: some View {
        NavigationStack {
            VStack {
                Text("Main View")
                    .font(.largeTitle)
                    .padding()

                Spacer()

                // Navigation Bar
                HStack {
                    ForEach(icons, id: \.name) { icon in
                        Spacer()

                        Image(systemName: icon.name)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                            .foregroundColor(.black)
                            .onTapGesture {
                                selectedRoute = icon.route
                            }

                        Spacer()
                    }
                }
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.1))
            }
            // Full screen "redirect"
            .fullScreenCover(item: $selectedRoute, onDismiss: {
                selectedRoute = nil
            }) { route in
                destinationView(for: route)
            }
        }
    }

    // Route Selector
    @ViewBuilder
    func destinationView(for route: PageRoute) -> some View {
        switch route {
        case .home:
            HomePage(showSignInView: .constant(false))
        case .heatmap:
            Heatmap()
        case .comingSoon:
            Text("COMING SOON")
        }
    }
}



//#Preview {
//    NavBar()
//}
