import Foundation
import CoreLocation
import FirebaseFirestore

class GymRepository: ObservableObject {
    private let db = Firestore.firestore()
    @Published var gyms: [Gym] = []
    @Published var teams: [String: Team] = [:] // Cache teams by ID
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        fetchTeams() // Load teams first
    }
    
    func fetchTeams() {
        db.collection("teams").addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching teams: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No teams found")
                return
            }
            
            let decoded = documents.compactMap { doc -> Team? in
                do {
                    var team = try doc.data(as: Team.self)
                    if team.id == nil {
                        team.id = doc.documentID
                    }
                    return team
                } catch {
                    print("Decoding team failed for doc \(doc.documentID): \(error)")
                    return nil
                }
            }
            
            DispatchQueue.main.async {
                // Convert to dictionary for quick lookup
                self?.teams = Dictionary(uniqueKeysWithValues: decoded.compactMap { team in
                    guard let id = team.id else { return nil }
                    return (id, team)
                })
                print("Successfully loaded \(decoded.count) teams")
            }
        }
    }
    
    func fetchGyms() {
        isLoading = true
        errorMessage = nil
        
        db.collection("gyms").addSnapshotListener { [weak self] snapshot, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("Error fetching gyms: \(error)")
                    self?.errorMessage = "Failed to load gyms: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No gyms found")
                    self?.gyms = []
                    return
                }
                
                let decoded = documents.compactMap { doc -> Gym? in
                    do {
                        print("Attempting to decode gym document: \(doc.documentID)")
                        print("Document data: \(doc.data())")
                        
                        var gym = try doc.data(as: Gym.self)
                        if gym.id == nil {
                            gym.id = doc.documentID
                        }
                        
                        print("Successfully decoded gym: \(gym.name), ownerTeamId: \(gym.ownerTeamId ?? "nil")")
                        return gym
                    } catch {
                        print("Decoding gym failed for doc \(doc.documentID): \(error)")
                        print("Error details: \(error)")
                        return nil
                    }
                }
                
                self?.gyms = decoded
                print("Successfully loaded \(decoded.count) gyms")
            }
        }
    }
    
    func getTeam(for teamId: String?) -> Team? {
        guard let teamId = teamId else { return nil }
        return teams[teamId]
    }
    
    func getTeamColor(for teamId: String?) -> String {
        return getTeam(for: teamId)?.color ?? "gray"
    }
    
    // MARK: - Mock Data for Development (fallback)
    
    private func generateMockGyms() -> [Gym] {
        return [
            Gym(
                id: "gIlZvXqqfaj3qdCfAUns",
                name: "Aneva",
                location: Location(
                    address: "24-09 41st Ave, Long Island City, NY 11101",
                    lat: 40.75266615909022,
                    lon: -73.93922240996022
                ),
                bestSquatId: "/workouts/0",
                bestBenchId: "/workouts/0",
                bestDeadliftId: "/workouts/0",
                ownerTeamId: "0" // Use just the ID, not the full path
            )
        ]
    }
    
    // Fallback method for development
    func fetchGymsMock() {
        print("Debug: fetchGymsMock called")
        isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let mockGyms = self.generateMockGyms()
            print("Debug: Generated mock gyms: \(mockGyms)")
            self.gyms = mockGyms
            print("Debug: Set gyms in repository: \(self.gyms)")
            self.isLoading = false
        }
    }
}



