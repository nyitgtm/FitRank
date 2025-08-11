// HeatmapManager.swift
import Foundation
import FirebaseFirestore

struct LiftRecord: Codable, Equatable {
    var weight: Double
    var userId: String
    var teamId: String
    var workoutId: String
}

struct Location: Codable, Equatable {
    let address: String?
    let lat: Double
    let lon: Double
}

struct Team: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var name: String
    var color: String // hex color or color name
    var icon: String? // SF Symbol name or icon reference
}

struct Gym: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var name: String
    var location: Location
    var bestSquat: LiftRecord?
    var bestBench: LiftRecord?
    var bestDeadlift: LiftRecord?
    var ownerTeamId: String? // Will be extracted from DocumentReference
    
    // Custom coding keys to handle DocumentReference
    enum CodingKeys: String, CodingKey {
        case id, name, location, bestSquat, bestBench, bestDeadlift, ownerTeamId
    }
    
    // Custom decoder to handle DocumentReference
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try container.decode(String.self, forKey: .name)
        location = try container.decode(Location.self, forKey: .location)
        bestSquat = try container.decodeIfPresent(LiftRecord.self, forKey: .bestSquat)
        bestBench = try container.decodeIfPresent(LiftRecord.self, forKey: .bestBench)
        bestDeadlift = try container.decodeIfPresent(LiftRecord.self, forKey: .bestDeadlift)
        
        // Handle ownerTeamId as either String or DocumentReference
        if let teamRef = try? container.decode(DocumentReference.self, forKey: .ownerTeamId) {
            ownerTeamId = teamRef.documentID
        } else if let teamString = try? container.decodeIfPresent(String.self, forKey: .ownerTeamId) {
            ownerTeamId = teamString
        } else {
            ownerTeamId = nil
        }
    }
    
    // Custom encoder (in case you need to write back to Firestore)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(location, forKey: .location)
        try container.encodeIfPresent(bestSquat, forKey: .bestSquat)
        try container.encodeIfPresent(bestBench, forKey: .bestBench)
        try container.encodeIfPresent(bestDeadlift, forKey: .bestDeadlift)
        try container.encodeIfPresent(ownerTeamId, forKey: .ownerTeamId)
    }
    
    // Custom Equatable implementation
    static func == (lhs: Gym, rhs: Gym) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.location.lat == rhs.location.lat &&
               lhs.location.lon == rhs.location.lon &&
               lhs.ownerTeamId == rhs.ownerTeamId
    }
}

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
