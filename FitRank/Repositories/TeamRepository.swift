import Foundation
import FirebaseFirestore

@MainActor
class TeamRepository: ObservableObject {
    @Published var teams: [Team] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    func fetchTeams() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let snapshot = try await db.collection("teams").getDocuments()
            let fetchedTeams = snapshot.documents.compactMap { document -> Team? in
                try? document.data(as: Team.self)
            }
            
            self.teams = fetchedTeams
            self.isLoading = false
        } catch {
            self.errorMessage = "Failed to fetch teams: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
    
    func getTeam(byId teamId: String) -> Team? {
        return teams.first { $0.id == teamId }
    }
    
    func getTeam(byReference reference: String) -> Team? {
        // Extract the team ID from the reference path (e.g., "/teams/0" -> "0")
        let components = reference.components(separatedBy: "/")
        guard components.count >= 2, let teamId = components.last else { return nil }
        return getTeam(byId: teamId)
    }
}
