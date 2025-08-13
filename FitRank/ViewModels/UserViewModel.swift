import Foundation
import FirebaseAuth
import Combine

@MainActor
class UserViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firebaseService = FirebaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupAuthStateListener()
    }
    
    // MARK: - Authentication State Management
    
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    await self?.fetchUserProfile(userId: user.uid)
                } else {
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                }
            }
        }
    }
    
    // MARK: - User Profile Management
    
    func fetchUserProfile(userId: String) async {
        isLoading = true
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        await MainActor.run {
            self.currentUser = self.generateMockUser()
            self.isLoading = false
        }
    }
    
    private func createDefaultUserProfile(userId: String) async {
        guard let authUser = Auth.auth().currentUser else { return }
        
        let defaultUser = User(
            id: userId,
            name: authUser.displayName ?? "User",
            team: "/teams/\(Team.killa.rawValue)",
            isCoach: false,
            username: generateUniqueUsername(),
            tokens: 0
        )
        
        do {
            try await firebaseService.createUser(defaultUser)
            currentUser = defaultUser
            isAuthenticated = true
        } catch {
            errorMessage = "Failed to create user profile: \(error.localizedDescription)"
        }
    }
    
    private func generateUniqueUsername() -> String {
        let baseUsername = "user\(Int.random(in: 1000...9999))"
        return baseUsername
    }
    
    // MARK: - Mock Data for Development
    
    private func generateMockUser() -> User {
        return User(
            id: "XXnXHthKKwVN5yfE0knWEPvHnOI2",
            name: "Fitrank Control",
            team: "/teams/0",
            isCoach: true,
            username: "fitrank",
            tokens: -1
        )
    }
    
    func fetchCurrentUser() async {
        isLoading = true
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        await MainActor.run {
            self.currentUser = self.generateMockUser()
            self.isLoading = false
        }
    }
    
    // MARK: - Profile Updates
    
    func updateProfile(name: String, username: String) async {
        guard var user = currentUser else { return }
        
        isLoading = true
        
        // Update local user
        user.name = name
        user.username = username
        
        await MainActor.run {
            self.currentUser = user
            self.isLoading = false
        }
        
        // In production, this would update Firebase
        // try await firebaseService.updateUser(user)
    }
    
    // MARK: - Team Management
    
    func updateTeam(team: String) async {
        guard var user = currentUser else { return }
        
        isLoading = true
        
        // Update local user
        user.team = team
        
        await MainActor.run {
            self.currentUser = user
            self.isLoading = false
        }
        
        // In production, this would update Firebase
        // try await firebaseService.updateUser(user)
    }
    
    func selectTeam(_ team: Team) async {
        await updateTeam(team: "/teams/\(team.rawValue)")
    }
    
    // MARK: - Token Management
    
    func addTokens(_ amount: Int) async {
        guard var user = currentUser else { return }
        
        user.tokens += amount
        
        do {
            try await firebaseService.updateUser(user)
            currentUser = user
        } catch {
            errorMessage = "Failed to update tokens: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
    
    func checkAuthenticationStatus() {
        // For development, always show as authenticated with mock data
        isAuthenticated = true
        currentUser = generateMockUser()
        
        // In production, this would check Firebase Auth
        // if let user = Auth.auth().currentUser {
        //     isAuthenticated = true
        //     Task {
        //         await fetchUserProfile(userId: user.uid)
        //     }
        // } else {
        //     isAuthenticated = false
        //     currentUser = nil
        // }
    }
}
