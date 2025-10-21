//
//  MealLogViewModel.swift
//  FitRank
//

import Foundation

@MainActor
class MealLogViewModel: ObservableObject {
    @Published var currentDayLog: DailyMealLog?
    @Published var selectedDate: Date = Date()
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var calorieGoal: Int = 2000 // Default, can be customized
    
    private let localStorage = MealLogLocalStorage()
    
    init() {
        loadTodayLog()
    }
    
    func loadTodayLog() {
        loadLog(for: selectedDate)
    }
    
    func loadLog(for date: Date) {
        isLoading = true
        
        // Simulate slight delay for smooth UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let log = self.localStorage.loadMealLog(for: date) {
                self.currentDayLog = log
            } else {
                // Create a new log for this day
                self.currentDayLog = DailyMealLog(
                    userId: "local_user", // Using local identifier
                    date: date
                )
            }
        }
    }
    
    func addFoodEntry(_ entry: FoodEntry, to mealType: MealType) {
        if currentDayLog == nil {
            currentDayLog = DailyMealLog(userId: "local_user", date: selectedDate)
        }
        
        currentDayLog?.addEntry(entry, to: mealType)
        saveMealLog()
    }
    
    func removeFoodEntry(_ entry: FoodEntry, from mealType: MealType) {
        currentDayLog?.removeEntry(entry, from: mealType)
        saveMealLog()
    }
    
    func updateFoodEntry(_ oldEntry: FoodEntry, with newEntry: FoodEntry, in mealType: MealType) {
        currentDayLog?.removeEntry(oldEntry, from: mealType)
        currentDayLog?.addEntry(newEntry, to: mealType)
        saveMealLog()
    }
    
    func saveMealLog() {
        guard let log = currentDayLog else { return }
        
        do {
            try localStorage.saveMealLog(log)
        } catch {
            errorMessage = "Error saving meal log: \(error.localizedDescription)"
        }
    }
    
    func changeDate(_ newDate: Date) {
        selectedDate = newDate
        loadLog(for: newDate)
    }
    
    var remainingCalories: Int {
        return calorieGoal - Int(currentDayLog?.totalCalories ?? 0)
    }
    
    var calorieProgress: Double {
        guard calorieGoal > 0 else { return 0 }
        return min((currentDayLog?.totalCalories ?? 0) / Double(calorieGoal), 1.0)
    }
}

// MARK: - Local Storage Manager
class MealLogLocalStorage {
    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
    
    private func storageKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "mealLog_\(formatter.string(from: date))"
    }
    
    func saveMealLog(_ log: DailyMealLog) throws {
        let key = storageKey(for: log.date)
        let data = try encoder.encode(log)
        userDefaults.set(data, forKey: key)
        userDefaults.synchronize() // Force immediate save
    }
    
    func loadMealLog(for date: Date) -> DailyMealLog? {
        let key = storageKey(for: date)
        
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        
        return try? decoder.decode(DailyMealLog.self, from: data)
    }
    
    func deleteMealLog(for date: Date) {
        let key = storageKey(for: date)
        userDefaults.removeObject(forKey: key)
        userDefaults.synchronize()
    }
    
    // Get all stored meal log dates
    func getAllMealLogDates() -> [Date] {
        let allKeys = userDefaults.dictionaryRepresentation().keys
        let mealLogKeys = allKeys.filter { $0.hasPrefix("mealLog_") }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        return mealLogKeys.compactMap { key -> Date? in
            let dateString = key.replacingOccurrences(of: "mealLog_", with: "")
            return formatter.date(from: dateString)
        }.sorted()
    }
    
    // Clear all meal logs (useful for debugging or settings)
    func clearAllMealLogs() {
        let allKeys = userDefaults.dictionaryRepresentation().keys
        let mealLogKeys = allKeys.filter { $0.hasPrefix("mealLog_") }
        
        for key in mealLogKeys {
            userDefaults.removeObject(forKey: key)
        }
        userDefaults.synchronize()
    }
}
