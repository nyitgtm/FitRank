//
//  FoodDataMainView.swift
//  FitRank
//
//  Created by Armaan Binning on 10/8/25.
//

import SwiftUI

struct FoodDataMainView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                // Title
                Text("Food Database")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // Search Food Button
                NavigationLink {
                    FoodDatabaseView()
                } label: {
                    FeatureCard(
                        icon: "magnifyingglass",
                        title: "Search Food",
                        subtitle: "Find nutrients and calories",
                        color: .blue
                    )
                }
                
                // Search Recipes Button
                NavigationLink {
                    RecipeSearchView()
                } label: {
                    FeatureCard(
                        icon: "book.fill",
                        title: "Search Recipes",
                        subtitle: "Discover healthy recipes",
                        color: .orange
                    )
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Food Database")
        }
    }
}

#Preview {
    FoodDataMainView()
}

