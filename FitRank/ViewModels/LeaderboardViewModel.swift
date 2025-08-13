import Foundation
import FirebaseAuth
import Combine

@MainActor
class LeaderboardViewModel: ObservableObject {
    @Published var globalLeaderboard: [LeaderboardEntry] = []
    @Published var teamLeaderboard: [LeaderboardEntry] = []
    @Published var gymLeaderboard: [LeaderboardEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firebaseService = FirebaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Leaderboard Management
    
    func fetchLeaderboards() {
        isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.globalLeaderboard = self.calculateGlobalLeaderboard()
            self.teamLeaderboard = self.calculateTeamLeaderboard()
            self.gymLeaderboard = self.calculateGymLeaderboard()
            self.isLoading = false
        }
    }
    
    func refreshLeaderboards() async {
        await MainActor.run {
            isLoading = true
        }
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        await MainActor.run {
            self.globalLeaderboard = self.calculateGlobalLeaderboard()
            self.teamLeaderboard = self.calculateTeamLeaderboard()
            self.gymLeaderboard = self.calculateGymLeaderboard()
            self.isLoading = false
        }
    }
    
    // MARK: - Mock Data for Development
    
    private func generateMockLeaderboard() -> [LeaderboardEntry] {
        return [
            LeaderboardEntry(
                id: "user1",
                rank: 1,
                userId: "user1",
                userName: "Fitrank Control",
                team: "/teams/0",
                score: 1500,
                scoreType: .tokens,
                liftType: .bench
            ),
            LeaderboardEntry(
                id: "user2",
                rank: 2,
                userId: "user2",
                userName: "John Doe",
                team: "/teams/1",
                score: 1200,
                scoreType: .tokens,
                liftType: .squat
            ),
            LeaderboardEntry(
                id: "user3",
                rank: 3,
                userId: "user3",
                userName: "Jane Smith",
                team: "/teams/2",
                score: 1100,
                scoreType: .tokens,
                liftType: .deadlift
            ),
            LeaderboardEntry(
                id: "user4",
                rank: 4,
                userId: "user4",
                userName: "Mike Johnson",
                team: "/teams/0",
                score: 950,
                scoreType: .tokens,
                liftType: .bench
            ),
            LeaderboardEntry(
                id: "user5",
                rank: 5,
                userId: "user5",
                userName: "Sarah Wilson",
                team: "/teams/1",
                score: 800,
                scoreType: .tokens,
                liftType: .squat
            )
        ]
    }
    
    // MARK: - Leaderboard Calculations
    
    private func calculateGlobalLeaderboard() -> [LeaderboardEntry] {
        // For now, return mock data
        // In production, this would query Firestore for actual user data
        return generateMockLeaderboard().sorted { $0.score > $1.score }
    }
    
    private func calculateTeamLeaderboard() -> [LeaderboardEntry] {
        // For now, return mock data filtered by team
        // In production, this would query Firestore for team-specific data
        return generateMockLeaderboard().sorted { $0.score > $1.score }
    }
    
    private func calculateGymLeaderboard() -> [LeaderboardEntry] {
        // For now, return mock data
        // In production, this would query Firestore for gym-specific data
        return generateMockLeaderboard().sorted { $0.score > $1.score }
    }
    
    // MARK: - Team Management
    
    private func getTeamName(_ teamId: String) -> String {
        switch teamId {
        case "/teams/0": return "Killa Gorillaz"
        case "/teams/1": return "Dark Sharks"
        case "/teams/2": return "Regal Eagles"
        default: return "Unknown Team"
        }
    }
    
    private func getTeamColor(_ teamId: String) -> String {
        switch teamId {
        case "/teams/0": return "#ff7700"
        case "/teams/1": return "#007bff"
        case "/teams/2": return "#6f42c1"
        default: return "#666666"
        }
    }
}

// MARK: - Leaderboard Entry Model

struct LeaderboardEntry: Identifiable {
    let id: String
    let rank: Int
    let userId: String
    let userName: String
    let team: String
    let score: Int
    let scoreType: ScoreType
    let liftType: LiftType?
    
    init(id: String, rank: Int, userId: String, userName: String, team: String, score: Int, scoreType: ScoreType, liftType: LiftType? = nil) {
        self.id = id
        self.rank = rank
        self.userId = userId
        self.userName = userName
        self.team = team
        self.score = score
        self.scoreType = scoreType
        self.liftType = liftType
    }
}

enum ScoreType {
    case tokens
    case weight
    
    var displayName: String {
        switch self {
        case .tokens: return "Tokens"
        case .weight: return "Weight (lbs)"
        }
    }
    
    var icon: String {
        switch self {
        case .tokens: return "star.fill"
        case .weight: return "dumbbell.fill"
        }
    }
}
