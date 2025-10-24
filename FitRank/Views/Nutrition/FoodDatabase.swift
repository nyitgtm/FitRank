import SwiftUI

struct FoodDatabaseView: View {
    @State private var query = ""
    @State private var foods: [Food] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchTask: DispatchWorkItem?

    var body: some View {
        VStack {
            // Search Bar
            HStack {
                TextField("Search food...", text: $query)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .onChange(of: query) { newValue in
                        // Cancel previous search task
                        searchTask?.cancel()
                        
                        if newValue.isEmpty {
                            foods = []
                            errorMessage = nil
                            isLoading = false
                        } else if newValue.count >= 3 {
                            // Create new search task with 0.5 second delay
                            let task = DispatchWorkItem {
                                fetchFoods()
                            }
                            searchTask = task
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: task)
                        }
                    }
                
                if !query.isEmpty {
                    Button(action: { query = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .padding(8)
                    }
                    .padding(.trailing)
                }
            }
            .padding(.top)
            
            // What the statuis is
            if isLoading {
                ProgressView("Searching...")
                    .padding()
            } else if let errorMessage = errorMessage {
                Text("⚠️ \(errorMessage)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            } else if foods.isEmpty && !query.isEmpty {
                Text("No foods found for \"\(query)\"")
                    .foregroundColor(.secondary)
                    .padding()
            }
            
            // List of food
            List(foods, id: \.fdcId) { food in
                NavigationLink(destination: FoodDetailView(food: food)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(food.description)
                            .font(.headline)
                        if let brand = food.brandOwner {
                            Text(brand)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            Text("Calories: \(Int(food.calories)) kcal")
                            Text("Protein: \(food.protein, specifier: "%.1f") g")
                            Text("Carbs: \(food.carbs, specifier: "%.1f") g")
                            Text("Fat: \(food.fat, specifier: "%.1f") g")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(PlainListStyle())
        }
        .navigationTitle("Food Database")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Fetch Foods
    func fetchFoods() {
        guard !query.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        foods = []
        
        let apiKey = "9bAFyouNpO8YFM0tCHXHwd7xZNs14J7gfF6XZBm6"
        let urlString = "https://api.nal.usda.gov/fdc/v1/foods/search?api_key=\(apiKey)&query=\(query)&dataType=Foundation,Branded&pageSize=20"
        
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
            errorMessage = "Invalid URL."
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
                    print(String(data: data, encoding: .utf8) ?? "No readable data")
                    errorMessage = "Could not get API response."
                }
            }
        }.resume()
    }
}

// MARK: - Food Detail View
struct FoodDetailView: View {
    let food: Food
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(food.description)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let brand = food.brandOwner {
                    Text("Brand: \(brand)")
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nutrients")
                        .font(.headline)
                    
                    ForEach(food.foodNutrients, id: \.nutrientName) { nutrient in
                        HStack {
                            Text(nutrient.nutrientName)
                            Spacer()
                            Text("\(nutrient.value, specifier: "%.1f") \(nutrient.unitName)")
                        }
                        .font(.subheadline)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Food Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Data Models
struct MealResponse: Codable {
    let foods: [Food]
}

struct Food: Codable, Hashable {
    let fdcId: Int
    let description: String
    let brandOwner: String?
    let foodNutrients: [Nutrient]
    
    var calories: Double {
        foodNutrients.first { $0.nutrientName.lowercased() == "energy" }?.value ?? 0
    }
    
    var protein: Double {
        foodNutrients.first { $0.nutrientName.lowercased() == "protein" }?.value ?? 0
    }
    
    var carbs: Double {
        foodNutrients.first { $0.nutrientName.lowercased().contains("carbohydrate") }?.value ?? 0
    }
    
    var fat: Double {
        foodNutrients.first { $0.nutrientName.lowercased().contains("fat") }?.value ?? 0
    }
}

struct Nutrient: Codable, Hashable {
    let nutrientName: String
    let value: Double
    let unitName: String
}

#Preview {
    FoodDatabaseView()
}

