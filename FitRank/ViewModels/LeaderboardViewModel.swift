import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
class LeaderboardViewModel: ObservableObject {
    @Published var globalLeaderboard: [LeaderboardEntry] = []
    @Published var teamLeaderboard: [LeaderboardEntry] = []
    @Published var followingLeaderboard: [LeaderboardEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUserTeam: String = ""
    
    private let firebaseService = FirebaseService.shared
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Leaderboard Management
    
    func fetchLeaderboards(scoreType: ScoreType, liftType: LiftType? = nil) async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            // Get current user's team
            if let userId = Auth.auth().currentUser?.uid {
                let user = try await firebaseService.getUser(userId: userId)
                await MainActor.run {
                    self.currentUserTeam = user.team
                }
            }
            
            // Fetch leaderboards based on score type
            if scoreType == .tokens {
                await fetchTokenLeaderboards()
            } else {
                guard let liftType = liftType else { return }
                await fetchWeightLeaderboards(liftType: liftType)
            }
            
            await MainActor.run {
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Token Leaderboards
    
    private func fetchTokenLeaderboards() async {
        do {
            // Fetch all users ordered by tokens
            let snapshot = try await db.collection("users")
                .order(by: "tokens", descending: true)
                .limit(to: 100)
                .getDocuments()
            
            let entries = try snapshot.documents.compactMap { doc -> LeaderboardEntry? in
                guard let userId = doc.documentID as String?,
                      let name = doc.data()["name"] as? String,
                      let username = doc.data()["username"] as? String,
                      let team = doc.data()["team"] as? String,
                      let tokens = doc.data()["tokens"] as? Int else {
                    return nil
                }
                
                return LeaderboardEntry(
                    id: userId,
                    rank: 0, // Will be set later
                    userId: userId,
                    userName: name,
                    username: username,
                    team: team,
                    score: tokens,
                    scoreType: .tokens,
                    liftType: nil
                )
            }
            
            // Set ranks for global
            let globalEntries = entries.enumerated().map { index, entry in
                var updated = entry
                updated.rank = index + 1
                return updated
            }
            
            // Filter for team
            let teamEntries = entries.filter { $0.team == currentUserTeam }
                .enumerated().map { index, entry in
                    var updated = entry
                    updated.rank = index + 1
                    return updated
                }
            
            // Filter for following
            let followingEntries = await filterFollowingEntries(entries)
            
            await MainActor.run {
                self.globalLeaderboard = globalEntries
                self.teamLeaderboard = teamEntries
                self.followingLeaderboard = followingEntries
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Weight Leaderboards
    
    private func fetchWeightLeaderboards(liftType: LiftType) async {
        do {
            // Fetch all published workouts for this lift type
            let snapshot = try await db.collection("workouts")
                .whereField("liftType", isEqualTo: liftType.rawValue)
                .whereField("status", isEqualTo: "published")
                .getDocuments()
            
            // Group by user and get max weight
            var userMaxWeights: [String: (weight: Int, userId: String, name: String, username: String, team: String)] = [:]
            
            for doc in snapshot.documents {
                guard let userId = doc.data()["userId"] as? String,
                      let weight = doc.data()["weight"] as? Int else {
                    continue
                }
                
                if let existing = userMaxWeights[userId] {
                    if weight > existing.weight {
                        userMaxWeights[userId] = (weight, userId, existing.name, existing.username, existing.team)
                    }
                } else {
                    // Fetch user data
                    do {
                        let user = try await firebaseService.getUser(userId: userId)
                        userMaxWeights[userId] = (weight, userId, user.name, user.username, user.team)
                    } catch {
                        continue
                    }
                }
            }
            
            // Convert to entries and sort
            let entries = userMaxWeights.values.map { data in
                LeaderboardEntry(
                    id: data.userId,
                    rank: 0,
                    userId: data.userId,
                    userName: data.name,
                    username: data.username,
                    team: data.team,
                    score: data.weight,
                    scoreType: .weight,
                    liftType: liftType
                )
            }.sorted { $0.score > $1.score }
            
            // Set ranks for global
            let globalEntries = entries.enumerated().map { index, entry in
                var updated = entry
                updated.rank = index + 1
                return updated
            }
            
            // Filter for team
            let teamEntries = entries.filter { $0.team == currentUserTeam }
                .enumerated().map { index, entry in
                    var updated = entry
                    updated.rank = index + 1
                    return updated
                }
            
            // Filter for following
            let followingEntries = await filterFollowingEntries(entries)
            
            await MainActor.run {
                self.globalLeaderboard = globalEntries
                self.teamLeaderboard = teamEntries
                self.followingLeaderboard = followingEntries
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Following Filter
    
    private func filterFollowingEntries(_ entries: [LeaderboardEntry]) async -> [LeaderboardEntry] {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            return []
        }
        
        do {
            // Get list of users current user is following
            let friendsSnapshot = try await db.collection("users")
                .document(currentUserId)
                .collection("friends")
                .getDocuments()
            
            let followingUserIds = Set(friendsSnapshot.documents.compactMap { doc in
                doc.data()["userId"] as? String
            })
            
            // Filter entries to only include followed users
            let filteredEntries = entries.filter { entry in
                followingUserIds.contains(entry.userId)
            }
            
            // Re-rank the filtered entries
            return filteredEntries.enumerated().map { index, entry in
                var updated = entry
                updated.rank = index + 1
                return updated
            }
        } catch {
            print("Error fetching following list: \(error.localizedDescription)")
            return []
        }
    }
}

// MARK: - Leaderboard Entry Model

struct LeaderboardEntry: Identifiable, Equatable {
    let id: String
    var rank: Int
    let userId: String
    let userName: String
    let username: String
    let team: String
    let score: Int
    let scoreType: ScoreType
    let liftType: LiftType?
    
    static func == (lhs: LeaderboardEntry, rhs: LeaderboardEntry) -> Bool {
        lhs.id == rhs.id && lhs.rank == rhs.rank && lhs.score == rhs.score
    }
}

enum ScoreType: String, CaseIterable {
    case tokens = "Tokens"
    case weight = "Weight"
    
    var icon: String {
        switch self {
        case .tokens: return "star.fill"
        case .weight: return "dumbbell.fill"
        }
    }
}
