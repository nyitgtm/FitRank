//
//  NutritionModels.swift
//  FitRank
//

import Foundation

enum Gender: String, CaseIterable, Identifiable {
    case male = "Male"
    case female = "Female"
    case other = "Other"
    
    var id: String { self.rawValue }
}

enum ActivityLevel: String, CaseIterable, Identifiable {
    case sedentary = "Sedentary"
    case light = "Light Exercise"
    case moderate = "Moderate Exercise"
    case active = "Very Active"
    case athlete = "Extremely Active"
    
    var id: String { self.rawValue }
    
    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .light: return 1.375
        case .moderate: return 1.55
        case .active: return 1.725
        case .athlete: return 1.9
        }
    }
}

enum Goal: String, CaseIterable, Identifiable {
    case maintain = "Maintain Weight"
    case lose = "Lose Weight"
    case gain = "Gain Weight"
    
    var id: String { self.rawValue }
}

enum UnitSystem: String, CaseIterable, Identifiable {
    case metric = "Metric"
    case imperial = "Imperial"
    
    var id: String { self.rawValue }
}

struct CalorieCalculation {
    let bmr: Double // Basal Metabolic Rate
    let tdee: Double // Total Daily Energy Expenditure
    let maintenanceCalories: Int
    let cuttingCalories: Int
    let bulkingCalories: Int
    let proteinGrams: Int
    let fatGrams: Int
    let carbGrams: Int
}

struct UserProfile {
    var age: Int = 25
    var gender: Gender = .male
    var weight: Double = 70.0 // kg or lbs based on unit system
    var height: Double = 175.0 // cm or ft/in based on unit system
    var activityLevel: ActivityLevel = .moderate
    var goal: Goal = .maintain
    var unitSystem: UnitSystem = .metric
}

// Unit conversion utilities
struct UnitConverter {
    static func poundsToKilograms(_ pounds: Double) -> Double {
        return pounds * 0.453592
    }
    
    static func kilogramsToPounds(_ kg: Double) -> Double {
        return kg * 2.20462
    }
    
    static func feetToCentimeters(_ feet: Double, inches: Double = 0) -> Double {
        return (feet * 30.48) + (inches * 2.54)
    }
    
    static func centimetersToFeet(_ cm: Double) -> (feet: Int, inches: Int) {
        let totalInches = cm / 2.54
        let feet = Int(totalInches / 12)
        let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
        return (feet, inches)
    }
}
