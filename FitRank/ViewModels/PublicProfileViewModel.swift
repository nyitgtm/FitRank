import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
class PublicProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var friendStatus: FriendStatus = .none
    @Published var bestSquat: Int = 0
    @Published var bestBench: Int = 0
    @Published var bestDeadlift: Int = 0
    @Published var favoriteGym: String = "None"
    @Published var workoutCount: Int = 0
    @Published var friendsCount: Int = 0
    
    private let db = Firestore.firestore()
    
    enum FriendStatus {
        case none
        case pending
        case friends
        case selfProfile
    }
    
    func loadUser(userId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Fetch User
            let userDoc = try await db.collection("users").document(userId).getDocument()
            // Manual decoding similar to UserRepository to handle @DocumentID
            if var data = userDoc.data() {
                // Fix for old documents: Convert FIRDocumentReference to String path
                if let teamRef = data["team"] as? DocumentReference {
                    data["team"] = teamRef.path
                }
                if data["id"] == nil {
                    data["id"] = userDoc.documentID
                }
                
                // Decode manually to ensure safety
                if let name = data["name"] as? String,
                   let team = data["team"] as? String,
                   let username = data["username"] as? String {
                    
                    let isCoach = (data["isCoach"] as? Bool) ?? ((data["isCoach"] as? Int) == 1)
                    let tokens = (data["tokens"] as? Int) ?? 0
                    let blockedUsers = data["blockedUsers"] as? [String]
                    let deleteUser = data["deleteUser"] as? Bool
                    
                    var loadedUser = User(
                        id: nil,
                        name: name,
                        team: team,
                        isCoach: isCoach,
                        username: username,
                        tokens: tokens,
                        blockedUsers: blockedUsers,
                        deleteUser: deleteUser
                    )
                    loadedUser.id = userId
                    self.user = loadedUser
                }
            }
            
            // Load Stats
            await loadStats(userId: userId)
            
            // Check Friend Status
            if let currentUid = Auth.auth().currentUser?.uid {
                if currentUid == userId {
                    friendStatus = .selfProfile
                } else {
                    await checkFriendStatus(currentUid: currentUid, targetUserId: userId)
                }
            }
            
            // Load Friends Count
            let friendsSnapshot = try await db.collection("users").document(userId).collection("friends").getDocuments()
            friendsCount = friendsSnapshot.count
            
        } catch {
            print("Error loading public profile: \(error)")
        }
    }
    
    private func loadStats(userId: String) async {
        do {
            let workoutsSnapshot = try await db.collection("workouts")
                .whereField("userId", isEqualTo: userId)
                .whereField("status", isEqualTo: "published")
                .getDocuments()
            
            let workouts = workoutsSnapshot.documents.compactMap { try? $0.data(as: Workout.self) }
            workoutCount = workouts.count
            
            // Calculate Best SQD
            bestSquat = workouts.filter { $0.liftType == "squat" }.map { $0.weight }.max() ?? 0
            bestBench = workouts.filter { $0.liftType == "bench" }.map { $0.weight }.max() ?? 0
            bestDeadlift = workouts.filter { $0.liftType == "deadlift" }.map { $0.weight }.max() ?? 0
            
            // Calculate Favorite Gym
            let gymIds = workouts.compactMap { $0.gymId }
            if !gymIds.isEmpty {
                let gymCounts = gymIds.reduce(into: [:]) { counts, id in counts[id, default: 0] += 1 }
                if let topGymId = gymCounts.max(by: { $0.value < $1.value })?.key {
                    // Fetch Gym Name
                    let gymDoc = try await db.collection("gyms").document(topGymId).getDocument()
                    if let gymName = gymDoc.data()?["name"] as? String {
                        favoriteGym = gymName
                    }
                }
            }
            
        } catch {
            print("Error loading stats: \(error)")
        }
    }
    
    private func checkFriendStatus(currentUid: String, targetUserId: String) async {
        do {
            // Check if already friends
            let friendDoc = try await db.collection("users").document(currentUid)
                .collection("friends").document(targetUserId).getDocument()
            
            if friendDoc.exists {
                friendStatus = .friends
                return
            }
            
            // Check if request pending (sent by current user)
            let requestQuery = try await db.collection("users").document(targetUserId)
                .collection("friendRequests")
                .whereField("fromUserId", isEqualTo: currentUid)
                .whereField("status", isEqualTo: "pending")
                .getDocuments()
            
            if !requestQuery.isEmpty {
                friendStatus = .pending
                return
            }
            
            friendStatus = .none
            
        } catch {
            print("Error checking friend status: \(error)")
        }
    }
    
    func sendFriendRequest(targetUserId: String) async {
        guard let currentUid = Auth.auth().currentUser?.uid,
              let currentUser = try? await UserRepository().getUser(uid: currentUid) else { return }
        
        do {
            let requestRef = db.collection("users").document(targetUserId).collection("friendRequests").document()
            try await requestRef.setData([
                "fromUserId": currentUid,
                "fromName": currentUser.name,
                "fromUsername": currentUser.username,
                "status": "pending",
                "createdAt": FieldValue.serverTimestamp()
            ])
            
            friendStatus = .pending
            print("Friend request sent")
        } catch {
            print("Error sending friend request: \(error)")
        }
    }
    
    func blockUser(targetUserId: String) async {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        do {
            try await UserRepository().blockUser(currentUserId: currentUid, blockedUserId: targetUserId)
            print("User blocked")
        } catch {
            print("Error blocking user: \(error)")
        }
    }
}
