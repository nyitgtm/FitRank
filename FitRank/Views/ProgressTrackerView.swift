//
//  ProgressTrackerView.swift
//  FitRank
//

import SwiftUI

struct ProgressTrackerView: View {
    @StateObject private var viewModel = ProgressTrackerViewModel()
    @State private var showingSettingsSheet = false
    @State private var selectedWeekOffset: Int = 0 // 0 = current week, -1 = last week, etc.
    
    var selectedWeekDate: Date {
        Calendar.current.date(byAdding: .day, value: selectedWeekOffset * 7, to: Date()) ?? Date()
    }
    
    var selectedWeekProgress: WeeklyProgressSummary? {
        viewModel.progressData.getWeeklyProgress(for: selectedWeekDate)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Top Bar with Settings
                HStack {
                    Text("Progress Tracker")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: { showingSettingsSheet = true }) {
                        Image(systemName: "gear")
                            .font(.system(size: 18))
                            .foregroundColor(.purple)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .border(Color(.systemGray5), width: 1)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Settings Summary
                        SettingsSummaryCard(settings: viewModel.progressData.settings)
                            .padding(.horizontal)
                            .padding(.top)
                        
                        // Week Navigation
                        WeekNavigationHeader(
                            weekProgress: selectedWeekProgress,
                            onPrevious: { selectedWeekOffset -= 1 },
                            onNext: { selectedWeekOffset += 1 },
                            isNextDisabled: selectedWeekOffset >= 0
                        )
                        .padding(.horizontal)
                        
                        // Calendar View
                        if let weekProgress = selectedWeekProgress {
                            CalendarWeekView(
                                weekProgress: weekProgress,
                                maintenanceCalories: viewModel.progressData.settings.maintenanceCalories
                            )
                            .padding(.horizontal)
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("No data for this week")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(40)
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSettingsSheet) {
                SettingsSheet(viewModel: viewModel)
            }
            .onAppear {
                viewModel.syncWithMealLogger()
            }
        }
    }
}

// MARK: - Week Navigation Header
struct WeekNavigationHeader: View {
    let weekProgress: WeeklyProgressSummary?
    let onPrevious: () -> Void
    let onNext: () -> Void
    let isNextDisabled: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: onPrevious) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.purple)
                        .frame(width: 40, height: 40)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 4) {
                    if let weekProgress = weekProgress {
                        Text(weekProgress.formattedDateRange)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Week \(weekProgress.weekNumber)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("No Data")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: onNext) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.purple)
                        .frame(width: 40, height: 40)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .disabled(isNextDisabled)
                .opacity(isNextDisabled ? 0.5 : 1)
            }
        }
    }
}

// MARK: - Calendar Week View
struct CalendarWeekView: View {
    let weekProgress: WeeklyProgressSummary
    let maintenanceCalories: Int
    
    var body: some View {
        VStack(spacing: 16) {
            // Week Summary Stats
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Deficit")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(weekProgress.totalCalorieDeficit)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                            Text("cal")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Projected Weight Loss")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                            Text(String(format: "%.2f", weekProgress.projectedWeightLoss))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text("lbs")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            
            // Daily Calendar Grid
            VStack(spacing: 12) {
                // Days of week header
                HStack(spacing: 0) {
                    ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                        Text(day)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                // Calendar Grid
                VStack(spacing: 8) {
                    ForEach(0..<weekProgress.dailyProgresses.count, id: \.self) { index in
                        let day = weekProgress.dailyProgresses[index]
                        
                        CalendarDayCell(day: day, maintenanceCalories: maintenanceCalories)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
}

// MARK: - Calendar Day Cell
struct CalendarDayCell: View {
    let day: DailyProgress
    let maintenanceCalories: Int
    
    var weightLostPerDay: Double {
        // Negative surplus = deficit
        let deficit = -day.caloriesSurplus
        return Double(deficit) / 3500.0 // Convert calories to pounds
    }
    
    var deficitStatus: (emoji: String, color: Color, status: String) {
        let deficit = -day.caloriesSurplus
        
        if deficit < 0 {
            return ("⚠️", .red, "Over")
        } else if deficit < 200 {
            return ("📉", .orange, "Low")
        } else if deficit < 500 {
            return ("✅", .yellow, "Good")
        } else {
            return ("🔥", .green, "Great")
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                // Day of week
                VStack(alignment: .leading, spacing: 2) {
                    Text(day.shortDate)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    Text(day.formattedDate)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                // Weight lost
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "scalemass.fill")
                            .font(.caption2)
                        Text(String(format: "%.2f", weightLostPerDay))
                            .font(.subheadline)
                            .fontWeight(.bold)
                        Text("lbs")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.purple)
                    
                    Text("\(day.caloriesConsumed) cal")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Calorie bar
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Deficit:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(String(format: "%+d", -day.caloriesSurplus))
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(deficitStatus.color)
                    }
                    
                    ProgressView(value: Double(day.caloriesConsumed), total: Double(maintenanceCalories))
                        .tint(day.caloriesSurplus < 0 ? .green : .orange)
                        .frame(height: 6)
                }
                
                Text(deficitStatus.emoji)
                    .font(.title3)
            }
            
            // Macro breakdown
            HStack(spacing: 12) {
                MacroMini(label: "P", value: Int(day.protein), color: .red)
                MacroMini(label: "C", value: Int(day.carbs), color: .orange)
                MacroMini(label: "F", value: Int(day.fat), color: .purple)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct MacroMini: View {
    let label: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)g")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color(.systemBackground))
        .cornerRadius(6)
    }
}

// MARK: - Settings Summary Card
struct SettingsSummaryCard: View {
    let settings: ProgressTrackerSettings
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Maintenance")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(settings.maintenanceCalories)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Target Weight Loss")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(String(format: "%.1f", settings.targetWeightLossPerWeek))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("lbs/week")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Deficit Needed")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(settings.dailyCalorieDeficitNeeded)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Target Daily Calories")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(settings.targetDailyCalories)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Settings Sheet
struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProgressTrackerViewModel
    
    @State private var maintenanceCalories: String = ""
    @State private var targetWeightLossPerWeek: String = ""
    @State private var currentWeight: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Daily Maintenance")) {
                    HStack {
                        TextField("Calories", text: $maintenanceCalories)
                            .keyboardType(.numberPad)
                        Text("cal/day")
                            .foregroundColor(.secondary)
                    }
                    Text("Your daily calorie maintenance (TDEE)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Weight Loss Goal")) {
                    HStack {
                        TextField("Weight Loss", text: $targetWeightLossPerWeek)
                            .keyboardType(.decimalPad)
                        Text("lbs/week")
                            .foregroundColor(.secondary)
                    }
                    Text("Target weight loss per week (1-2 lbs is healthy)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Current Weight")) {
                    HStack {
                        TextField("Weight", text: $currentWeight)
                            .keyboardType(.decimalPad)
                        Text("lbs")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(action: saveSettings) {
                        HStack {
                            Spacer()
                            Text("Save Settings")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .foregroundColor(.white)
                    }
                    .listRowBackground(Color.purple)
                }
            }
            .navigationTitle("Adjust Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                maintenanceCalories = "\(viewModel.progressData.settings.maintenanceCalories)"
                targetWeightLossPerWeek = String(format: "%.1f", viewModel.progressData.settings.targetWeightLossPerWeek)
                currentWeight = String(format: "%.1f", viewModel.progressData.settings.currentWeight)
            }
        }
    }
    
    private func saveSettings() {
        guard let maintenance = Int(maintenanceCalories),
              let lossPerWeek = Double(targetWeightLossPerWeek),
              let weight = Double(currentWeight),
              maintenance > 0,
              lossPerWeek > 0,
              weight > 0 else {
            return
        }
        
        viewModel.updateSettings(
            maintenanceCalories: maintenance,
            targetWeightLossPerWeek: lossPerWeek,
            currentWeight: weight
        )
        
        dismiss()
    }
}

#Preview {
    ProgressTrackerView()
}
