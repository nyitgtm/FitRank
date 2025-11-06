//
//  ProgressTracker.swift
//  FitRank
//

import Foundation

struct DailyProgress: Identifiable, Codable {
    var id: String = UUID().uuidString
    let date: Date
    let caloriesConsumed: Int
    let caloriesMaintenance: Int
    let caloriesSurplus: Int // positive = surplus, negative = deficit
    let protein: Double
    let carbs: Double
    let fat: Double
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

struct WeeklyProgressSummary: Identifiable, Codable {
    let id: String = UUID().uuidString
    let startDate: Date
    let endDate: Date
    let dailyProgresses: [DailyProgress]
    let averageCalories: Int
    let totalCalorieChange: Int // positive for surplus, negative for deficit
    let projectedWeightChange: Double // in pounds (positive for gain, negative for loss)
    let maintenanceCalories: Int
    let targetWeightChangePerWeek: Double // in pounds
    let fitnessGoal: FitnessGoal
    
    var weekNumber: Int {
        Calendar.current.component(.weekOfYear, from: startDate)
    }
    
    var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    var isOnTrack: Bool {
        switch fitnessGoal {
        case .cutting:
            return projectedWeightChange <= -targetWeightChangePerWeek * 0.8 // Within 80% of goal
        case .bulking:
            return projectedWeightChange >= targetWeightChangePerWeek * 0.8 // Within 80% of goal
        }
    }
}

enum FitnessGoal: String, Codable, CaseIterable {
    case cutting = "Cutting (Weight Loss)"
    case bulking = "Bulking (Weight Gain)"
    
    var icon: String {
        switch self {
        case .cutting: return "arrow.down.circle.fill"
        case .bulking: return "arrow.up.circle.fill"
        }
    }
    
    var displayName: String {
        return self.rawValue
    }
}

struct ProgressTrackerSettings: Identifiable, Codable {
    var id: String = UUID().uuidString
    var maintenanceCalories: Int = 2000
    var targetWeightChangePerWeek: Double = 1.0 // pounds (positive for both gain and loss)
    var currentWeight: Double = 180.0 // pounds
    var fitnessGoal: FitnessGoal = .cutting
    var lastUpdated: Date = Date()
    
    // Calculate daily calorie surplus/deficit needed
    var dailyCalorieChangeNeeded: Int {
        // 1 pound = 3500 calories
        let weeklyCalorieChange = Int(targetWeightChangePerWeek * 3500)
        return weeklyCalorieChange / 7
    }
    
    var targetDailyCalories: Int {
        switch fitnessGoal {
        case .cutting:
            return maintenanceCalories - dailyCalorieChangeNeeded
        case .bulking:
            return maintenanceCalories + dailyCalorieChangeNeeded
        }
    }
    
    var goalLabel: String {
        switch fitnessGoal {
        case .cutting: return "Target Weight Loss"
        case .bulking: return "Target Weight Gain"
        }
    }
    
    var calorieChangeLabel: String {
        switch fitnessGoal {
        case .cutting: return "Daily Deficit Needed"
        case .bulking: return "Daily Surplus Needed"
        }
    }
}

struct ProgressData: Codable {
    var dailyProgresses: [DailyProgress] = []
    var settings: ProgressTrackerSettings = ProgressTrackerSettings()
    
    func getWeeklyProgress(for date: Date) -> WeeklyProgressSummary? {
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
        
        let weekProgresses = dailyProgresses.filter { progress in
            progress.date >= weekStart && progress.date <= weekEnd
        }
        
        guard !weekProgresses.isEmpty else { return nil }
        
        let avgCalories = Int(weekProgresses.map { Double($0.caloriesConsumed) }.reduce(0, +) / Double(weekProgresses.count))
        let totalCalorieChange = weekProgresses.map { $0.caloriesSurplus }.reduce(0, +)
        // Positive surplus = weight gain, negative surplus (deficit) = weight loss
        let projectedWeightChange = Double(totalCalorieChange) / 3500.0 // 3500 calories = 1 pound
        
        return WeeklyProgressSummary(
            startDate: weekStart,
            endDate: weekEnd,
            dailyProgresses: weekProgresses.sorted { $0.date < $1.date },
            averageCalories: avgCalories,
            totalCalorieChange: totalCalorieChange,
            projectedWeightChange: projectedWeightChange,
            maintenanceCalories: settings.maintenanceCalories,
            targetWeightChangePerWeek: settings.targetWeightChangePerWeek,
            fitnessGoal: settings.fitnessGoal
        )
    }
    
    func getCurrentWeekProgress() -> WeeklyProgressSummary? {
        return getWeeklyProgress(for: Date())
    }
    
    func getAllWeeklyProgress() -> [WeeklyProgressSummary] {
        guard !dailyProgresses.isEmpty else { return [] }
        
        var weeklyProgresses: [WeeklyProgressSummary] = []
        let calendar = Calendar.current
        
        var currentDate = dailyProgresses.min(by: { $0.date < $1.date })?.date ?? Date()
        let endDate = dailyProgresses.max(by: { $0.date < $1.date })?.date ?? Date()
        
        while currentDate <= endDate {
            if let weekProgress = getWeeklyProgress(for: currentDate) {
                if !weeklyProgresses.contains(where: { $0.startDate == weekProgress.startDate }) {
                    weeklyProgresses.append(weekProgress)
                }
                currentDate = calendar.date(byAdding: .day, value: 7, to: currentDate) ?? currentDate.addingTimeInterval(86400 * 7)
            } else {
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate.addingTimeInterval(86400)
            }
        }
        
        return weeklyProgresses.sorted { $0.startDate > $1.startDate }
    }
}
