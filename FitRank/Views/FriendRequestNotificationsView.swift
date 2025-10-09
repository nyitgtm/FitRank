//
//  FriendRequestNotificationsView.swift
//  FitRank
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct FriendRequestNotification: Identifiable, Codable {
    @DocumentID var id: String?
    let fromUserId: String
    let fromName: String
    let fromUsername: String?
    let status: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case fromUserId
        case fromName
        case fromUsername
        case status
        case createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decode(DocumentID<String>.self, forKey: .id)
        fromUserId = try container.decode(String.self, forKey: .fromUserId)
        fromName = try container.decode(String.self, forKey: .fromName)
        fromUsername = try container.decodeIfPresent(String.self, forKey: .fromUsername)
        status = try container.decode(String.self, forKey: .status)
        
        if let timestamp = try? container.decode(Timestamp.self, forKey: .createdAt) {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = Date()
        }
    }
}

struct FriendRequestNotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = FriendRequestViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading...")
                    Spacer()
                } else if viewModel.pendingRequests.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No Friend Requests")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("You'll see friend requests here")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.pendingRequests) { request in
                                FriendRequestRow(
                                    request: request,
                                    onAccept: {
                                        viewModel.acceptFriendRequest(request)
                                    },
                                    onDecline: {
                                        viewModel.declineFriendRequest(request)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Friend Requests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadFriendRequests()
        }
    }
}

struct FriendRequestRow: View {
    let request: FriendRequestNotification
    let onAccept: () -> Void
    let onDecline: () -> Void
    @State private var isProcessing = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                )
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text(request.fromName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let username = request.fromUsername {
                    Text("@\(username)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text(request.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isProcessing {
                ProgressView()
                    .padding(.trailing, 8)
            } else {
                // Action buttons
                HStack(spacing: 8) {
                    // Decline button
                    Button(action: {
                        isProcessing = true
                        onDecline()
                    }) {
                        Image(systemName: "xmark")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.red)
                            .clipShape(Circle())
                    }
                    
                    // Accept button
                    Button(action: {
                        isProcessing = true
                        onAccept()
                    }) {
                        Image(systemName: "checkmark")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.green)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

@MainActor
class FriendRequestViewModel: ObservableObject {
    @Published var pendingRequests: [FriendRequestNotification] = []
    @Published var isLoading = false
    @Published var unreadCount = 0
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    deinit {
        listener?.remove()
    }
    
    func loadFriendRequests() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        
        // Real-time listener for pending friend requests
        listener = db.collection("users").document(uid)
            .collection("friendRequests")
            .whereField("status", isEqualTo: "pending")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error loading friend requests: \(error.localizedDescription)")
                    self.isLoading = false
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.isLoading = false
                    return
                }
                
                Task {
                    var requests: [FriendRequestNotification] = []
                    
                    for doc in documents {
                        // Fetch the username of the sender
                        let fromUserId = doc.data()["fromUserId"] as? String ?? ""
                        let fromName = doc.data()["fromName"] as? String ?? "Someone"
                        
                        // Try to get username from sender's profile
                        var fromUsername: String?
                        if !fromUserId.isEmpty {
                            if let userDoc = try? await self.db.collection("users").document(fromUserId).getDocument(),
                               let username = userDoc.data()?["username"] as? String {
                                fromUsername = username
                            }
                        }
                        
                        // Create notification object
                        if let request = try? doc.data(as: FriendRequestNotification.self) {
                            var updatedRequest = request
                            if fromUsername != nil {
                                // Create new instance with username
                                let data = doc.data()
                                let timestamp = data["createdAt"] as? Timestamp ?? Timestamp()
                                
                                let newRequest = FriendRequestNotification(
                                    id: doc.documentID,
                                    fromUserId: fromUserId,
                                    fromName: fromName,
                                    fromUsername: fromUsername,
                                    status: "pending",
                                    createdAt: timestamp.dateValue()
                                )
                                requests.append(newRequest)
                            } else {
                                requests.append(request)
                            }
                        }
                    }
                    
                    await MainActor.run {
                        self.pendingRequests = requests
                        self.unreadCount = requests.count
                        self.isLoading = false
                    }
                }
            }
    }
    
    func acceptFriendRequest(_ request: FriendRequestNotification) {
        guard let uid = Auth.auth().currentUser?.uid,
              let requestId = request.id else { return }
        
        Task {
            do {
                // Add to both users' friends lists
                let batch = db.batch()
                
                // Add to current user's friends
                let userFriendRef = db.collection("users").document(uid)
                    .collection("friends").document(request.fromUserId)
                batch.setData([
                    "userId": request.fromUserId,
                    "name": request.fromName,
                    "addedAt": FieldValue.serverTimestamp()
                ], forDocument: userFriendRef)
                
                // Add to sender's friends
                let senderFriendRef = db.collection("users").document(request.fromUserId)
                    .collection("friends").document(uid)
                
                // Get current user's info
                let currentUserDoc = try await db.collection("users").document(uid).getDocument()
                let currentUserName = (currentUserDoc.data()?["name"] as? String) ?? "Someone"
                
                batch.setData([
                    "userId": uid,
                    "name": currentUserName,
                    "addedAt": FieldValue.serverTimestamp()
                ], forDocument: senderFriendRef)
                
                // Update the request status to accepted
                let requestRef = db.collection("users").document(uid)
                    .collection("friendRequests").document(requestId)
                batch.updateData(["status": "accepted"], forDocument: requestRef)
                
                // Create acceptance notification for the sender
                let notificationRef = db.collection("users").document(request.fromUserId)
                    .collection("notifications").document()
                batch.setData([
                    "type": "friend_accepted",
                    "fromUserId": uid,
                    "fromName": currentUserName,
                    "message": "\(currentUserName) accepted your friend request",
                    "createdAt": FieldValue.serverTimestamp(),
                    "isRead": false
                ], forDocument: notificationRef)
                
                try await batch.commit()
                
                print("✅ Friend request accepted")
                
                // Remove from local list
                await MainActor.run {
                    self.pendingRequests.removeAll { $0.id == requestId }
                    self.unreadCount = self.pendingRequests.count
                }
                
            } catch {
                print("❌ Error accepting friend request: \(error.localizedDescription)")
            }
        }
    }
    
    func declineFriendRequest(_ request: FriendRequestNotification) {
        guard let uid = Auth.auth().currentUser?.uid,
              let requestId = request.id else { return }
        
        Task {
            do {
                // Delete the request
                try await db.collection("users").document(uid)
                    .collection("friendRequests").document(requestId).delete()
                
                // Also delete from sender's sent requests
                let senderRequests = try await db.collection("users").document(request.fromUserId)
                    .collection("friendRequests")
                    .whereField("toUserId", isEqualTo: uid)
                    .whereField("status", isEqualTo: "pending")
                    .getDocuments()
                
                for doc in senderRequests.documents {
                    try await doc.reference.delete()
                }
                
                print("✅ Friend request declined")
                
                // Remove from local list
                await MainActor.run {
                    self.pendingRequests.removeAll { $0.id == requestId }
                    self.unreadCount = self.pendingRequests.count
                }
                
            } catch {
                print("❌ Error declining friend request: \(error.localizedDescription)")
            }
        }
    }
}

// Helper struct for manual construction when needed
extension FriendRequestNotification {
    init(id: String, fromUserId: String, fromName: String, fromUsername: String?, status: String, createdAt: Date) {
        self._id = DocumentID(wrappedValue: id)
        self.fromUserId = fromUserId
        self.fromName = fromName
        self.fromUsername = fromUsername
        self.status = status
        self.createdAt = createdAt
    }
}
