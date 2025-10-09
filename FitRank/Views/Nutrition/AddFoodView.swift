//
//  AddFoodView.swift
//  FitRank
//

import SwiftUI

struct AddFoodView: View {
    @Environment(\.dismiss) private var dismiss
    let mealType: MealType
    let onAdd: (FoodEntry) -> Void
    
    @State private var searchQuery = ""
    @State private var foods: [Food] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedFood: Food?
    @State private var showingServingInput = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search for food...", text: $searchQuery, onCommit: searchFoods)
                        .textFieldStyle(.plain)
                    
                    if !searchQuery.isEmpty {
                        Button(action: { searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()
                
                // Content
                if isLoading {
                    Spacer()
                    ProgressView("Searching...")
                    Spacer()
                } else if let errorMessage = errorMessage {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else if foods.isEmpty && !searchQuery.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("No foods found for \"\(searchQuery)\"")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else if searchQuery.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "fork.knife")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("Search for foods to add to \(mealType.rawValue)")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else {
                    List(foods, id: \.fdcId) { food in
                        Button(action: {
                            selectedFood = food
                            showingServingInput = true
                        }) {
                            FoodSearchResultRow(food: food)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Add to \(mealType.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingServingInput) {
                if let food = selectedFood {
                    ServingSizeInputView(food: food) { entry in
                        onAdd(entry)
                        dismiss()
                    }
                }
            }
        }
    }
    
    func searchFoods() {
        guard !searchQuery.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        foods = []
        
        let apiKey = "9bAFyouNpO8YFM0tCHXHwd7xZNs14J7gfF6XZBm6"
        let urlString = "https://api.nal.usda.gov/fdc/v1/foods/search?api_key=\(apiKey)&query=\(searchQuery)&dataType=Foundation,Branded&pageSize=25"
        
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
            errorMessage = "Invalid search query."
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    errorMessage = "No data received."
                    return
                }
                
                do {
                    let decoded = try JSONDecoder().decode(MealResponse.self, from: data)
                    self.foods = decoded.foods
                } catch {
                    errorMessage = "Could not parse results. Please try again."
                }
            }
        }.resume()
    }
}

// MARK: - Food Search Result Row
struct FoodSearchResultRow: View {
    let food: Food
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(food.description)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            if let brand = food.brandOwner {
                Text(brand)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 16) {
                NutrientBadge(value: Int(food.calories), label: "cal", color: .blue)
                NutrientBadge(value: Int(food.protein), label: "P", color: .red)
                NutrientBadge(value: Int(food.carbs), label: "C", color: .orange)
                NutrientBadge(value: Int(food.fat), label: "F", color: .purple)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 8)
    }
}

struct NutrientBadge: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text("\(value)")
                .fontWeight(.semibold)
            Text(label)
        }
        .font(.caption)
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }
}

// MARK: - Serving Size Input View
struct ServingSizeInputView: View {
    @Environment(\.dismiss) private var dismiss
    let food: Food
    let onAdd: (FoodEntry) -> Void
    
    @State private var servingSize: String = "100"
    @State private var servingUnit: String = "g"
    @FocusState private var isInputFocused: Bool
    
    var servingSizeDouble: Double {
        Double(servingSize) ?? 100.0
    }
    
    var scaledCalories: Double {
        food.calories * (servingSizeDouble / 100.0)
    }
    
    var scaledProtein: Double {
        food.protein * (servingSizeDouble / 100.0)
    }
    
    var scaledCarbs: Double {
        food.carbs * (servingSizeDouble / 100.0)
    }
    
    var scaledFat: Double {
        food.fat * (servingSizeDouble / 100.0)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Food Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(food.description)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        if let brand = food.brandOwner {
                            Text(brand)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Serving Size Input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Serving Size")
                            .font(.headline)
                        
                        HStack {
                            TextField("Amount", text: $servingSize)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                                .focused($isInputFocused)
                            
                            Picker("Unit", selection: $servingUnit) {
                                Text("g").tag("g")
                                Text("oz").tag("oz")
                                Text("serving").tag("serving")
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        // Quick Amounts
                        HStack(spacing: 12) {
                            ForEach([50, 100, 150, 200], id: \.self) { amount in
                                Button("\(amount)g") {
                                    servingSize = "\(amount)"
                                    servingUnit = "g"
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    // Nutrition Preview
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Nutrition for \(servingSize) \(servingUnit)")
                            .font(.headline)
                        
                        VStack(spacing: 12) {
                            NutritionRow(label: "Calories", value: "\(Int(scaledCalories))", unit: "kcal", color: .blue)
                            NutritionRow(label: "Protein", value: String(format: "%.1f", scaledProtein), unit: "g", color: .red)
                            NutritionRow(label: "Carbohydrates", value: String(format: "%.1f", scaledCarbs), unit: "g", color: .orange)
                            NutritionRow(label: "Fat", value: String(format: "%.1f", scaledFat), unit: "g", color: .purple)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    // Add Button
                    Button(action: addFood) {
                        Text("Add to Meal")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .disabled(servingSize.isEmpty || Double(servingSize) == nil)
                }
                .padding()
            }
            .navigationTitle("Serving Size")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    func addFood() {
        let entry = FoodEntry(
            foodId: food.fdcId,
            name: food.description,
            brandName: food.brandOwner,
            servingSize: servingSizeDouble,
            servingUnit: servingUnit,
            calories: food.calories,
            protein: food.protein,
            carbs: food.carbs,
            fat: food.fat,
            timestamp: Date()
        )
        onAdd(entry)
    }
}

struct NutritionRow: View {
    let label: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                
                Text(label)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(value)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                Text(unit)
                    .foregroundColor(.secondary)
            }
        }
        .font(.subheadline)
    }
}

#Preview {
    AddFoodView(mealType: .breakfast) { _ in }
}
