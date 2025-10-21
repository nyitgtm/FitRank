//
//  NutritionMainView.swift
//  FitRank
//

import SwiftUI

struct NutritionMainView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Nutrition Hub")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Track your nutrition and optimize your fitness journey")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Main Features Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        // Calorie Calculator Card
                        NavigationLink {
                            CalorieCalculatorView()
                        } label: {
                            FeatureCard(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Calorie Calculator",
                                subtitle: "Calculate your daily needs",
                                color: .blue
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Meal Logger Card
                        NavigationLink {
                            MealLoggerView()
                        } label: {
                            FeatureCard(
                                icon: "list.clipboard",
                                title: "Meal Logger",
                                subtitle: "Track your daily meals",
                                color: .orange
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        NavigationLink {
                                FoodDataMainView()
                            } label: {
                                FeatureCard(
                                    icon: "magnifyingglass",
                                    title: "Food Database",
                                    subtitle: "Search foods & nutrients",
                                    color: .blue
                                )
                            }
                            .buttonStyle(PlainButtonStyle())

                        
                        NavigationLink {
                            ProgressTrackerView()
                        } label: {
                            FeatureCard(
                                icon: "chart.bar.fill",
                                title: "Progress Tracker",
                                subtitle: "Track your weight loss",
                                color: .purple
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                    
                    // Quick Tips Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Nutrition Tips")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            TipRow(icon: "drop.fill", text: "Stay hydrated - drink 8-10 glasses of water daily", color: .blue)
                            TipRow(icon: "leaf.fill", text: "Include protein in every meal for muscle recovery", color: .green)
                            TipRow(icon: "timer", text: "Eat every 3-4 hours to maintain energy levels", color: .orange)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(color)
                .cornerRadius(12)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(color)
                .cornerRadius(6)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

#Preview {
    NutritionMainView()
}
