import SwiftUI

struct RecipeDetailView: View {
    let recipeId: Int
    let apiKey: String
    
    @State private var recipe: RecipeDetail?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("Loading recipe...")
                    .padding()
            } else if let errorMessage = errorMessage {
                Text("⚠️ \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            } else if let recipe = recipe {
                VStack(alignment: .leading, spacing: 16) {
                    if let imageUrl = recipe.image, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 250)
                                .cornerRadius(12)
                        } placeholder: {
                            ProgressView()
                        }
                    }
                    
                    Text(recipe.title)
                        .font(.title)
                        .bold()
                    
                    if let ready = recipe.readyInMinutes {
                        Text("Ready in \(ready) minutes")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let servings = recipe.servings {
                        Text("Servings: \(servings)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    Text("Ingredients")
                        .font(.headline)
                    
                    ForEach(recipe.extendedIngredients, id: \.id) { ingredient in
                        Text("• \(ingredient.original)")
                    }
                    
                    Divider()
                    
                    Text("Instructions")
                        .font(.headline)
                    
                    if let instructions = recipe.instructions, !instructions.isEmpty {
                        Text(instructions)
                    } else {
                        Text("Instructions not available.")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            } else {
                Text("Recipe not found.")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Recipe Details")
        .onAppear {
            fetchRecipeDetails()
        }
    }
    
    func fetchRecipeDetails() {
        isLoading = true
        errorMessage = nil
        
        let urlString = "https://api.spoonacular.com/recipes/\(recipeId)/information?apiKey=\(apiKey)&includeNutrition=false"
        
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL."
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
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
                    let decoded = try JSONDecoder().decode(RecipeDetail.self, from: data)
                    self.recipe = decoded
                } catch {
                    errorMessage = "Failed to decode recipe details."
                    print(error)
                }
            }
        }.resume()
    }
}

// MARK: - Recipe Detail Models
struct RecipeDetail: Codable {
    let id: Int
    let title: String
    let image: String?
    let readyInMinutes: Int?
    let servings: Int?
    let instructions: String?
    let extendedIngredients: [Ingredient]
}

struct Ingredient: Codable, Identifiable {
    let id: Int
    let original: String
}

