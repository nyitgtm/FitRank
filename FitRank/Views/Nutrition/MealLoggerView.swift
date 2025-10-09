//
//  MealLoggerView.swift
//  FitRank
//

import SwiftUI

struct MealLoggerView: View {
    @StateObject private var viewModel = MealLogViewModel()
    @State private var showingAddFood = false
    @State private var selectedMealType: MealType = .breakfast
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Date Picker
                    DateNavigationView(selectedDate: $viewModel.selectedDate) {
                        viewModel.changeDate($0)
                    }
                    
                    // Calorie Summary Card
                    CalorieSummaryCard(
                        consumed: Int(viewModel.currentDayLog?.totalCalories ?? 0),
                        goal: viewModel.calorieGoal,
                        remaining: viewModel.remainingCalories,
                        protein: viewModel.currentDayLog?.totalProtein ?? 0,
                        carbs: viewModel.currentDayLog?.totalCarbs ?? 0,
                        fat: viewModel.currentDayLog?.totalFat ?? 0
                    )
                    .padding(.horizontal)
                    
                    // Meal Sections
                    ForEach(MealType.allCases, id: \.self) { mealType in
                        MealSection(
                            mealType: mealType,
                            entries: viewModel.currentDayLog?.entries(for: mealType) ?? [],
                            onAddFood: {
                                selectedMealType = mealType
                                showingAddFood = true
                            },
                            onDelete: { entry in
                                viewModel.removeFoodEntry(entry, from: mealType)
                            }
                        )
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.top)
            }
            .navigationTitle("Meal Logger")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .sheet(isPresented: $showingAddFood) {
                AddFoodView(mealType: selectedMealType) { entry in
                    viewModel.addFoodEntry(entry, to: selectedMealType)
                }
            }
            .sheet(isPresented: $showingSettings) {
                MealLogSettingsView(viewModel: viewModel)
            }
            .onAppear {
                // Load calorie goal from UserDefaults
                if let savedGoal = UserDefaults.standard.object(forKey: "calorieGoal") as? Int {
                    viewModel.calorieGoal = savedGoal
                }
            }
        }
    }
}

// MARK: - Date Navigation View
struct DateNavigationView: View {
    @Binding var selectedDate: Date
    let onChange: (Date) -> Void
    
    var body: some View {
        HStack {
            Button(action: { changeDate(by: -1) }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.blue)
                    .padding(8)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text(dateTitle)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(dateSubtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: { changeDate(by: 1) }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(isToday ? .gray : .blue)
                    .padding(8)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
            }
            .disabled(isToday)
        }
        .padding(.horizontal)
    }
    
    private func changeDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            selectedDate = newDate
            onChange(newDate)
        }
    }
    
    private var dateTitle: String {
        if Calendar.current.isDateInToday(selectedDate) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else if Calendar.current.isDateInTomorrow(selectedDate) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: selectedDate)
        }
    }
    
    private var dateSubtitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: selectedDate)
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
}

// MARK: - Calorie Summary Card
struct CalorieSummaryCard: View {
    let consumed: Int
    let goal: Int
    let remaining: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    
    var body: some View {
        VStack(spacing: 16) {
            // Calorie Circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 140, height: 140)
                
                Circle()
                    .trim(from: 0, to: min(Double(consumed) / Double(goal), 1.0))
                    .stroke(calorieColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: consumed)
                
                VStack(spacing: 4) {
                    Text("\(remaining)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(calorieColor)
                    
                    Text("Remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Stats Row
            HStack(spacing: 0) {
                StatItem(value: consumed, label: "Eaten", color: .blue)
                
                Divider()
                    .frame(height: 40)
                
                StatItem(value: goal, label: "Goal", color: .gray)
            }
            
            Divider()
            
            // Macros Row
            HStack(spacing: 20) {
                MacroItem(value: protein, label: "Protein", unit: "g", color: .red)
                MacroItem(value: carbs, label: "Carbs", unit: "g", color: .orange)
                MacroItem(value: fat, label: "Fat", unit: "g", color: .purple)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var calorieColor: Color {
        if remaining < 0 {
            return .red
        } else if remaining < 200 {
            return .orange
        } else {
            return .green
        }
    }
}

struct StatItem: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MacroItem: View {
    let value: Double
    let label: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(Int(value))")
                    .font(.headline)
                    .foregroundColor(color)
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Meal Section
struct MealSection: View {
    let mealType: MealType
    let entries: [FoodEntry]
    let onAddFood: () -> Void
    let onDelete: (FoodEntry) -> Void
    
    var totalCalories: Int {
        Int(entries.reduce(0) { $0 + $1.scaledCalories })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: mealType.icon)
                    .foregroundColor(.blue)
                
                Text(mealType.rawValue)
                    .font(.headline)
                
                Spacer()
                
                Text("\(totalCalories) cal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(action: onAddFood) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            
            // Food Entries
            if entries.isEmpty {
                Text("No foods logged")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(entries) { entry in
                    FoodEntryRow(entry: entry, onDelete: {
                        onDelete(entry)
                    })
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Food Entry Row
struct FoodEntryRow: View {
    let entry: FoodEntry
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let brand = entry.brandName {
                    Text(brand)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("\(Int(entry.servingSize)) \(entry.servingUnit)")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(entry.scaledCalories)) cal")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("P: \(Int(entry.scaledProtein))g • C: \(Int(entry.scaledCarbs))g • F: \(Int(entry.scaledFat))g")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .font(.caption)
            }
            .padding(.leading, 8)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    MealLoggerView()
}
