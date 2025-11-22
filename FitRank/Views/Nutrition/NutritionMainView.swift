//
//  NutritionMainView.swift
//  FitRank
//

import SwiftUI

struct NutritionMainView: View {
    @AppStorage("hasSeenNutritionDisclaimer") private var hasSeenDisclaimer = false
    @State private var showDisclaimer = false
    
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
            .sheet(isPresented: $showDisclaimer) {
                NutritionDisclaimerView {
                    hasSeenDisclaimer = true
                    showDisclaimer = false
                }
            }
            .onAppear {
                if !hasSeenDisclaimer {
                    showDisclaimer = true
                }
            }
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

// MARK: - Nutrition Disclaimer View
struct NutritionDisclaimerView: View {
    let onAccept: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Icon
                    HStack {
                        Spacer()
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        Spacer()
                    }
                    .padding(.top, 20)
                    
                    // Title
                    Text("Health & Safety Disclaimer")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    
                    // Disclaimer content
                    VStack(alignment: .leading, spacing: 16) {
                        DisclaimerSection(
                            title: "Medical Advice",
                            content: "FitRank is NOT a substitute for professional medical advice, diagnosis, or treatment. Always consult with a qualified healthcare provider before starting any new diet, exercise program, or making changes to your nutrition."
                        )
                        
                        DisclaimerSection(
                            title: "Nutrition Information",
                            content: "The calorie calculations, meal tracking, and nutritional information provided in this app are estimates based on general formulas and databases. Individual needs vary significantly based on metabolism, medical conditions, and other factors."
                        )
                        
                        DisclaimerSection(
                            title: "Exercise & Physical Activity",
                            content: "The workout tracking and lifting features are for informational purposes only. Improper form or excessive weight can lead to serious injury. Never attempt weights beyond your capability and always use proper form and safety equipment."
                        )
                        
                        DisclaimerSection(
                            title: "Personal Responsibility",
                            content: "You are solely responsible for your health and safety. Stop any activity immediately if you experience pain, dizziness, or discomfort. Seek immediate medical attention if needed."
                        )
                        
                        DisclaimerSection(
                            title: "No Liability",
                            content: "FitRank and its developers are not liable for any injuries, health issues, or damages resulting from use of this app. Use at your own risk."
                        )
                    }
                    
                    // Accept button
                    Button(action: onAccept) {
                        Text("I Understand and Accept")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.top, 20)
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled()
    }
}

struct DisclaimerSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Text(content)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
