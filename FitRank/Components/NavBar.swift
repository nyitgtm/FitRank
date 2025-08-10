//
//  NavBar.swift
//  FitRank
//
//  Created by Navraj Singh on 6/19/25.
//

import SwiftUI

// Create an Enum for Routes
enum PageRoute: Identifiable, Equatable {
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
    @Binding var selectedRoute: PageRoute
    
    let icons: [(name: String, route: PageRoute)] = [
        ("house.fill", .home),
        ("map.fill", .heatmap),
        ("plus.circle.fill", .comingSoon),
        ("camera.fill", .comingSoon),
        ("person.fill", .comingSoon)
    ]

    var body: some View {
        HStack {
            ForEach(icons, id: \.name) { icon in
                Spacer()
                
                Image(systemName: icon.name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .foregroundColor(selectedRoute == icon.route ? .blue : .black)
                    .onTapGesture {
                        selectedRoute = icon.route
                    }
                
                Spacer()
            }
        }
        .padding(.vertical, 10)
        .background(Color.gray.opacity(0.1))
    }
}
