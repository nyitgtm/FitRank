//
//  MealLogSettingsView.swift
//  FitRank
//

import SwiftUI

struct MealLogSettingsView: View {
    @ObservedObject var viewModel: MealLogViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var calorieGoalInput: String
    @State private var showingClearAlert = false
    
    init(viewModel: MealLogViewModel) {
        self.viewModel = viewModel
        _calorieGoalInput = State(initialValue: "\(viewModel.calorieGoal)")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Daily Goals")) {
                    HStack {
                        Text("Calorie Goal")
                        Spacer()
                        TextField("2000", text: $calorieGoalInput)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("cal")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Save Goal") {
                        saveCalorieGoal()
                    }
                    .disabled(calorieGoalInput.isEmpty || Int(calorieGoalInput) == nil)
                }
                
                Section(header: Text("Data Management")) {
                    Button(role: .destructive, action: {
                        showingClearAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear All Meal Logs")
                        }
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Storage")
                        Spacer()
                        Text("Local Device")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Data Source")
                        Spacer()
                        Text("USDA FoodData Central")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Meal Logger Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Clear All Data?", isPresented: $showingClearAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("This will permanently delete all your meal logs. This action cannot be undone.")
            }
        }
    }
    
    private func saveCalorieGoal() {
        if let goal = Int(calorieGoalInput), goal > 0 {
            viewModel.calorieGoal = goal
            UserDefaults.standard.set(goal, forKey: "calorieGoal")
            
            // Show success feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
    private func clearAllData() {
        let localStorage = MealLogLocalStorage()
        localStorage.clearAllMealLogs()
        viewModel.loadTodayLog()
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

#Preview {
    MealLogSettingsView(viewModel: MealLogViewModel())
}
