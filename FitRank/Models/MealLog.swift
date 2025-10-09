//
//  MealLog.swift
//  FitRank
//

import Foundation
import FirebaseFirestore

enum MealType: String, CaseIterable, Codable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snacks = "Snacks"
    
    var icon: String {
        switch self {
        case .breakfast: return "sun.rise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snacks: return "cup.and.saucer.fill"
        }
    }
}

struct FoodEntry: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    let foodId: Int // FDC ID from API
    let name: String
    let brandName: String?
    var servingSize: Double // in grams or specified unit
    let servingUnit: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let timestamp: Date
    
    var scaledCalories: Double {
        calories * (servingSize / 100.0)
    }
    
    var scaledProtein: Double {
        protein * (servingSize / 100.0)
    }
    
    var scaledCarbs: Double {
        carbs * (servingSize / 100.0)
    }
    
    var scaledFat: Double {
        fat * (servingSize / 100.0)
    }
}

struct DailyMealLog: Identifiable, Codable {
    var id: String = UUID().uuidString
    let userId: String
    let date: Date
    var breakfast: [FoodEntry] = []
    var lunch: [FoodEntry] = []
    var dinner: [FoodEntry] = []
    var snacks: [FoodEntry] = []
    
    var totalCalories: Double {
        allEntries.reduce(0) { $0 + $1.scaledCalories }
    }
    
    var totalProtein: Double {
        allEntries.reduce(0) { $0 + $1.scaledProtein }
    }
    
    var totalCarbs: Double {
        allEntries.reduce(0) { $0 + $1.scaledCarbs }
    }
    
    var totalFat: Double {
        allEntries.reduce(0) { $0 + $1.scaledFat }
    }
    
    var allEntries: [FoodEntry] {
        breakfast + lunch + dinner + snacks
    }
    
    mutating func addEntry(_ entry: FoodEntry, to mealType: MealType) {
        switch mealType {
        case .breakfast:
            breakfast.append(entry)
        case .lunch:
            lunch.append(entry)
        case .dinner:
            dinner.append(entry)
        case .snacks:
            snacks.append(entry)
        }
    }
    
    mutating func removeEntry(_ entry: FoodEntry, from mealType: MealType) {
        switch mealType {
        case .breakfast:
            breakfast.removeAll { $0.id == entry.id }
        case .lunch:
            lunch.removeAll { $0.id == entry.id }
        case .dinner:
            dinner.removeAll { $0.id == entry.id }
        case .snacks:
            snacks.removeAll { $0.id == entry.id }
        }
    }
    
    func entries(for mealType: MealType) -> [FoodEntry] {
        switch mealType {
        case .breakfast: return breakfast
        case .lunch: return lunch
        case .dinner: return dinner
        case .snacks: return snacks
        }
    }
}
