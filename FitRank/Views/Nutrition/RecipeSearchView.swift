import SwiftUI

struct RecipeSearchView: View {
    @State private var query: String = ""
    @State private var recipes: [RecipeSummary] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    @State private var selectedRecipeId: Int? = nil // For navigation
    let apiKey = "e1cbcf2940b84bbaac6c7d0c40b48214" // Spoonacular API key
    
    var body: some View {
        VStack {
            // Search bar
            HStack {
                TextField("Search recipes...", text: $query)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button(action: fetchRecipes) {
                    Image(systemName: "magnifyingglass")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(query.isEmpty)
                .padding(.trailing)
            }
            .padding(.top)
            
            // Loading / Error / Results
            if isLoading {
                ProgressView("Fetching recipes...")
                    .padding()
            } else if let errorMessage = errorMessage {
                Text("⚠️ \(errorMessage)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            } else if recipes.isEmpty {
                Text("No recipes yet. Try searching above!")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(recipes) { recipe in
                            NavigationLink(destination: RecipeDetailView(recipeId: recipe.id, apiKey: apiKey)) {
                                VStack(alignment: .leading, spacing: 8) {
                                    if let imageUrl = recipe.image, let url = URL(string: imageUrl) {
                                        AsyncImage(url: url) { image in
                                            image.resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(height: 180)
                                                .cornerRadius(10)
                                        } placeholder: {
                                            ProgressView()
                                        }
                                    }
                                    
                                    Text(recipe.title)
                                        .font(.headline)
                                    
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
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .shadow(radius: 2)
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.top)
                }
            }
            
            Spacer()
        }
        .navigationTitle("Recipe Search")
        .navigationBarTitleDisplayMode(.large)
    }
    
    func fetchRecipes() {
        isLoading = true
        errorMessage = nil
        recipes = []
        
        let queryEncoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://api.spoonacular.com/recipes/complexSearch?query=\(queryEncoded)&addRecipeInformation=true&number=20&apiKey=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
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
                    let decoded = try JSONDecoder().decode(RecipeResponse.self, from: data)
                    self.recipes = decoded.results
                } catch {
                    errorMessage = "Failed to decode API response."
                    print(error)
                }
            }
        }.resume()
    }
}

// MARK: - Models for Search
struct RecipeResponse: Codable {
    let results: [RecipeSummary]
}

struct RecipeSummary: Codable, Identifiable {
    let id: Int
    let title: String
    let image: String?
    let readyInMinutes: Int?
    let servings: Int?
}




