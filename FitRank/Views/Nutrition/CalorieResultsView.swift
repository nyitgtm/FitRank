//
//  CalorieResultsView.swift
//  FitRank
//

import SwiftUI

struct CalorieResultsView: View {
    let calculation: CalorieCalculation
    let onDone: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedGoalType: GoalType = .cutting
    @State private var showingSaveConfirmation = false
    
    enum GoalType: String, CaseIterable {
        case cutting = "Cutting"
        case maintenance = "Maintenance"
        case bulking = "Bulking"
        
        func calories(from calculation: CalorieCalculation) -> Int {
            switch self {
            case .cutting: return calculation.cuttingCalories
            case .maintenance: return calculation.maintenanceCalories
            case .bulking: return calculation.bulkingCalories
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Calorie Goals
                        calorieGoalsSection
                        
                        // Macronutrients
                        macronutrientsSection
                        
                        // Explanation
                        explanationSection
                        
                        // Action Buttons
                        actionButtonsSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Your Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDone()
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Your Calorie Plan")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Personalized nutrition plan based on your inputs")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    private var calorieGoalsSection: some View {
        VStack(spacing: 16) {
            Text("Daily Calorie Goals")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                CalorieCard(
                    title: "Cutting",
                    calories: calculation.cuttingCalories,
                    subtitle: "Weight Loss",
                    color: .blue,
                    icon: "arrow.down.circle.fill"
                )
                
                CalorieCard(
                    title: "Maintenance",
                    calories: calculation.maintenanceCalories,
                    subtitle: "Maintain Weight",
                    color: .green,
                    icon: "scale.3d.fill"
                )
                
                CalorieCard(
                    title: "Bulking",
                    calories: calculation.bulkingCalories,
                    subtitle: "Muscle Gain",
                    color: .orange,
                    icon: "arrow.up.circle.fill"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var macronutrientsSection: some View {
        VStack(spacing: 16) {
            Text("Recommended Macros")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Based on cutting calories for optimal results")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                MacroCard(
                    title: "Protein",
                    grams: calculation.proteinGrams,
                    color: .red,
                    icon: "fish.fill"
                )
                
                MacroCard(
                    title: "Carbs",
                    grams: calculation.carbGrams,
                    color: .blue,
                    icon: "leaf.fill"
                )
                
                MacroCard(
                    title: "Fats",
                    grams: calculation.fatGrams,
                    color: .orange,
                    icon: "drop.fill"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var explanationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How to Use This Plan")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                ExplanationRow(
                    icon: "scissors",
                    text: "Cutting: Eat \(calculation.cuttingCalories) calories daily for weight loss",
                    color: .blue
                )
                
                ExplanationRow(
                    icon: "scale.3d",
                    text: "Maintenance: Eat \(calculation.maintenanceCalories) calories to maintain weight",
                    color: .green
                )
                
                ExplanationRow(
                    icon: "dumbbell.fill",
                    text: "Bulking: Eat \(calculation.bulkingCalories) calories for muscle gain",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Goal Type Selector
            VStack(alignment: .leading, spacing: 12) {
                Text("Select Goal to Save")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Picker("Goal Type", selection: $selectedGoalType) {
                    ForEach(GoalType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                HStack {
                    Text("Daily Goal:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(selectedGoalType.calories(from: calculation)) calories")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            Button(action: saveToProfile) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Save to Meal Logger")
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            Button(action: {
                onDone()
                dismiss()
            }) {
                Text("Back to Nutrition")
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
        }
        .alert("Saved Successfully!", isPresented: $showingSaveConfirmation) {
            Button("OK") {
                onDone()
                dismiss()
            }
        } message: {
            Text("Your daily calorie goal of \(selectedGoalType.calories(from: calculation)) calories has been saved to your Meal Logger.")
        }
    }
    
    private func saveToProfile() {
        let calorieGoal = selectedGoalType.calories(from: calculation)
        UserDefaults.standard.set(calorieGoal, forKey: "calorieGoal")
        UserDefaults.standard.synchronize()
        showingSaveConfirmation = true
    }
}

// MARK: - Supporting Views

struct CalorieCard: View {
    let title: String
    let calories: Int
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("\(calories)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text("calories")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct MacroCard: View {
    let title: String
    let grams: Int
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("\(grams)g")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text("per day")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ExplanationRow: View {
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
    CalorieResultsView(
        calculation: CalorieCalculation(
            bmr: 1650,
            tdee: 2200,
            maintenanceCalories: 2200,
            cuttingCalories: 1760,
            bulkingCalories: 2640,
            proteinGrams: 176,
            fatGrams: 59,
            carbGrams: 132
        ),
        onDone: {}
    )
}
