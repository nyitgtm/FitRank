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
    let totalCalorieDeficit: Int
    let projectedWeightLoss: Double // in pounds
    let maintenanceCalories: Int
    let targetWeightLossPerWeek: Double // in pounds
    
    var weekNumber: Int {
        Calendar.current.component(.weekOfYear, from: startDate)
    }
    
    var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
}

struct ProgressTrackerSettings: Identifiable, Codable {
    var id: String = UUID().uuidString
    var maintenanceCalories: Int = 2000
    var targetWeightLossPerWeek: Double = 1.0 // pounds
    var currentWeight: Double = 180.0 // pounds
    var lastUpdated: Date = Date()
    
    // Calculate daily calorie deficit needed
    var dailyCalorieDeficitNeeded: Int {
        // 1 pound = 3500 calories
        let weeklyCalorieDeficit = Int(targetWeightLossPerWeek * 3500)
        return weeklyCalorieDeficit / 7
    }
    
    var targetDailyCalories: Int {
        return maintenanceCalories - dailyCalorieDeficitNeeded
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
        let totalDeficit = weekProgresses.map { -$0.caloriesSurplus }.reduce(0, +) // negative surplus = deficit
        let projectedWeightLoss = Double(totalDeficit) / 3500.0 // 3500 calories = 1 pound
        
        return WeeklyProgressSummary(
            startDate: weekStart,
            endDate: weekEnd,
            dailyProgresses: weekProgresses.sorted { $0.date < $1.date },
            averageCalories: avgCalories,
            totalCalorieDeficit: totalDeficit,
            projectedWeightLoss: projectedWeightLoss,
            maintenanceCalories: settings.maintenanceCalories,
            targetWeightLossPerWeek: settings.targetWeightLossPerWeek
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
