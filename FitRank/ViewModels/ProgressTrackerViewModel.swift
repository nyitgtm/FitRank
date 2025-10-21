//
//  ProgressTrackerViewModel.swift
//  FitRank
//

import Foundation

@MainActor
class ProgressTrackerViewModel: ObservableObject {
    @Published var progressData = ProgressData()
    @Published var currentWeekProgress: WeeklyProgressSummary?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let localStorage = ProgressTrackerLocalStorage()
    private let mealLogStorage = MealLogLocalStorage()
    
    init() {
        loadProgressData()
        syncWithMealLogger()
    }
    
    func loadProgressData() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            self.progressData = self.localStorage.loadProgressData()
            self.currentWeekProgress = self.progressData.getCurrentWeekProgress()
            self.isLoading = false
        }
    }
    
    func syncWithMealLogger() {
        // Get all meal log dates from the meal logger
        let mealLogDates = mealLogStorage.getAllMealLogDates()
        let calorieGoal = UserDefaults.standard.object(forKey: "calorieGoal") as? Int ?? 2000
        
        for date in mealLogDates {
            // Check if we already have progress for this date
            let dateString = formatDate(date)
            let hasProgress = progressData.dailyProgresses.contains { formatDate($0.date) == dateString }
            
            if !hasProgress {
                if let mealLog = mealLogStorage.loadMealLog(for: date) {
                    let totalCalories = Int(mealLog.totalCalories)
                    let caloriesSurplus = totalCalories - progressData.settings.maintenanceCalories
                    
                    let progress = DailyProgress(
                        date: date,
                        caloriesConsumed: totalCalories,
                        caloriesMaintenance: progressData.settings.maintenanceCalories,
                        caloriesSurplus: caloriesSurplus,
                        protein: mealLog.totalProtein,
                        carbs: mealLog.totalCarbs,
                        fat: mealLog.totalFat
                    )
                    
                    progressData.dailyProgresses.append(progress)
                }
            }
        }
        
        progressData.dailyProgresses.sort { $0.date < $1.date }
        currentWeekProgress = progressData.getCurrentWeekProgress()
        saveProgressData()
    }
    
    func updateSettings(maintenanceCalories: Int, targetWeightLossPerWeek: Double, currentWeight: Double) {
        progressData.settings.maintenanceCalories = maintenanceCalories
        progressData.settings.targetWeightLossPerWeek = targetWeightLossPerWeek
        progressData.settings.currentWeight = currentWeight
        progressData.settings.lastUpdated = Date()
        
        // Resync all progress with new maintenance calories
        progressData.dailyProgresses = progressData.dailyProgresses.map { progress in
            let newSurplus = progress.caloriesConsumed - maintenanceCalories
            return DailyProgress(
                date: progress.date,
                caloriesConsumed: progress.caloriesConsumed,
                caloriesMaintenance: maintenanceCalories,
                caloriesSurplus: newSurplus,
                protein: progress.protein,
                carbs: progress.carbs,
                fat: progress.fat
            )
        }
        
        currentWeekProgress = progressData.getCurrentWeekProgress()
        saveProgressData()
    }
    
    func saveProgressData() {
        do {
            try localStorage.saveProgressData(progressData)
        } catch {
            errorMessage = "Error saving progress data: \(error.localizedDescription)"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    var allWeeklyProgress: [WeeklyProgressSummary] {
        progressData.getAllWeeklyProgress()
    }
}

// MARK: - Local Storage Manager
class ProgressTrackerLocalStorage {
    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
    
    private let progressDataKey = "progressTracker_data"
    
    func saveProgressData(_ data: ProgressData) throws {
        let encodedData = try encoder.encode(data)
        userDefaults.set(encodedData, forKey: progressDataKey)
        userDefaults.synchronize()
    }
    
    func loadProgressData() -> ProgressData {
        guard let data = userDefaults.data(forKey: progressDataKey) else {
            return ProgressData()
        }
        return (try? decoder.decode(ProgressData.self, from: data)) ?? ProgressData()
    }
}
