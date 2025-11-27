//
//  CalorieCalculatorViewModel.swift
//  FitRank
//

import Foundation
import SwiftUI

@MainActor
final class CalorieCalculatorViewModel: ObservableObject {
    @Published var userProfile = UserProfile()
    @Published var calculation: CalorieCalculation?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Imperial unit inputs
    @Published var weightPounds: Double = 154.0 // 70kg in lbs
    @Published var heightFeet: Int = 5
    @Published var heightInches: Int = 9 // 175cm in ft/in
    
    // Form validation
    var isFormValid: Bool {
        userProfile.age > 0 && userProfile.age >= 15 && userProfile.age <= 100 &&
        (userProfile.unitSystem == .metric ?
         (userProfile.weight > 0 && userProfile.weight >= 30 && userProfile.weight <= 300) :
         (weightPounds > 0 && weightPounds >= 66 && weightPounds <= 660)) && // 30-300kg in lbs
        (userProfile.unitSystem == .metric ?
         (userProfile.height > 0 && userProfile.height >= 100 && userProfile.height <= 250) :
         (heightFeet > 0 && heightFeet >= 3 && heightFeet <= 8)) // 100-250cm in ft
    }
    
    func updateUnits() {
        if userProfile.unitSystem == .imperial {
            // Convert metric defaults to imperial for display
            weightPounds = UnitConverter.kilogramsToPounds(userProfile.weight)
            let (feet, inches) = UnitConverter.centimetersToFeet(userProfile.height)
            heightFeet = feet
            heightInches = inches
        }
    }
    
    func calculateCalories() {
        guard isFormValid else {
            errorMessage = "Please check your inputs. Age: 15-100, Weight: 30-300kg (66-660lbs), Height: 100-250cm (3'3\"-8'2\")"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Convert to metric for calculation (standard for BMR formulas)
        let weightKg: Double
        let heightCm: Double
        
        if userProfile.unitSystem == .metric {
            weightKg = userProfile.weight
            heightCm = userProfile.height
        } else {
            weightKg = UnitConverter.poundsToKilograms(weightPounds)
            heightCm = UnitConverter.feetToCentimeters(Double(heightFeet), inches: Double(heightInches))
        }
        
        // Simulate API call or complex calculation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.performCalculation(weightKg: weightKg, heightCm: heightCm)
            self.isLoading = false
        }
    }
    
    private func performCalculation(weightKg: Double, heightCm: Double) {
        // Calculate BMR using Mifflin-St Jeor Equation
        // Females: (10*weight [kg]) + (6.25*height [cm]) – (5*age [years]) – 161
        // Males: (10*weight [kg]) + (6.25*height [cm]) – (5*age [years]) + 5
        let bmr: Double
        switch userProfile.gender {
        case .male:
            bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(userProfile.age)) + 5
        case .female:
            bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(userProfile.age)) - 161
        case .other:
            // Use average of male and female formula
            let maleBMR = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(userProfile.age)) + 5
            let femaleBMR = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(userProfile.age)) - 161
            bmr = (maleBMR + femaleBMR) / 2
        }
        
        // Calculate TDEE (Total Daily Energy Expenditure)
        let tdee = bmr * userProfile.activityLevel.multiplier
        
        // Calculate goal-based calories
        let maintenanceCalories = Int(tdee)
        let cuttingCalories = Int(tdee * 0.8) // 20% deficit
        let bulkingCalories = Int(tdee * 1.2) // 20% surplus
        
        // Calculate macronutrients
        let proteinCalories = Double(cuttingCalories) * 0.4
        let fatCalories = Double(cuttingCalories) * 0.3
        let carbCalories = Double(cuttingCalories) * 0.3
        
        let proteinGrams = Int(proteinCalories / 4)
        let fatGrams = Int(fatCalories / 9)
        let carbGrams = Int(carbCalories / 4)
        
        calculation = CalorieCalculation(
            bmr: bmr,
            tdee: tdee,
            maintenanceCalories: maintenanceCalories,
            cuttingCalories: cuttingCalories,
            bulkingCalories: bulkingCalories,
            proteinGrams: proteinGrams,
            fatGrams: fatGrams,
            carbGrams: carbGrams
        )
    }
}
