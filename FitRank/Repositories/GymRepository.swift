import Foundation
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
                        var gym = try doc.data(as: Gym.self)
                        if gym.id == nil {
                            gym.id = doc.documentID
                        }
                        return gym
                    } catch {
                        print("Decoding gym failed for doc \(doc.documentID): \(error)")
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
    
    func addGym(_ gym: Gym) {
        do {
            _ = try db.collection("gyms").addDocument(from: gym) { error in
                if let error = error {
                    print("Error adding gym: \(error)")
                } else {
                    print("Gym added successfully")
                }
            }
        } catch {
            print("Error encoding gym: \(error)")
        }
    }
}
