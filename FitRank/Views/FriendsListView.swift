//
//  FriendsListView.swift
//  FitRank
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct Friend: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let name: String
    let username: String?
    let addedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case name
        case username
        case addedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decode(DocumentID<String>.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        name = try container.decode(String.self, forKey: .name)
        username = try container.decodeIfPresent(String.self, forKey: .username)
        
        if let timestamp = try? container.decode(Timestamp.self, forKey: .addedAt) {
            addedAt = timestamp.dateValue()
        } else {
            addedAt = Date()
        }
    }
}

struct FriendsListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = FriendsListViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading friends...")
                    Spacer()
                } else if viewModel.friends.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.slash.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No Friends Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Start following people to see them here")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button {
                            dismiss()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                Text("Search for Friends")
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(20)
                        }
                    }
                    .padding()
                    Spacer()
                } else {
                    // Friends count header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(viewModel.friends.count) Friend\(viewModel.friends.count == 1 ? "" : "s")")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            Text("People you're following")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    
                    Divider()
                    
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.friends) { friend in
                                FriendRow(
                                    friend: friend,
                                    onUnfollow: {
                                        viewModel.unfriendUser(friend)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Following")
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
            viewModel.loadFriends()
        }
    }
}

struct FriendRow: View {
    let friend: Friend
    let onUnfollow: () -> Void
    @State private var showingUnfollowAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.green, .blue],
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
                Text(friend.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let username = friend.username {
                    Text("@\(username)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                    Text("Following since \(friend.addedAt, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Unfollow button
            Button(action: {
                showingUnfollowAlert = true
            }) {
                Text("Following")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.15))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.green, lineWidth: 1)
                    )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .alert("Unfollow \(friend.name)?", isPresented: $showingUnfollowAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Unfollow", role: .destructive) {
                onUnfollow()
            }
        } message: {
            Text("You can always follow them again later.")
        }
    }
}

@MainActor
class FriendsListViewModel: ObservableObject {
    @Published var friends: [Friend] = []
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    deinit {
        listener?.remove()
    }
    
    func loadFriends() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        
        // Real-time listener for friends
        listener = db.collection("users").document(uid)
            .collection("friends")
            .order(by: "addedAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error loading friends: \(error.localizedDescription)")
                    self.isLoading = false
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.isLoading = false
                    return
                }
                
                Task {
                    var friendsList: [Friend] = []
                    
                    for doc in documents {
                        let userId = doc.data()["userId"] as? String ?? ""
                        let name = doc.data()["name"] as? String ?? "Unknown"
                        
                        // Try to get username from friend's profile
                        var username: String?
                        if !userId.isEmpty {
                            if let userDoc = try? await self.db.collection("users").document(userId).getDocument(),
                               let fetchedUsername = userDoc.data()?["username"] as? String {
                                username = fetchedUsername
                            }
                        }
                        
                        // Get addedAt timestamp
                        let timestamp = doc.data()["addedAt"] as? Timestamp ?? Timestamp()
                        
                        let friend = Friend(
                            id: doc.documentID,
                            userId: userId,
                            name: name,
                            username: username,
                            addedAt: timestamp.dateValue()
                        )
                        
                        friendsList.append(friend)
                    }
                    
                    await MainActor.run {
                        self.friends = friendsList
                        self.isLoading = false
                    }
                }
            }
    }
    
    func unfriendUser(_ friend: Friend) {
        guard let uid = Auth.auth().currentUser?.uid,
              let friendDocId = friend.id else { return }
        
        Task {
            do {
                // Remove from current user's friends
                try await db.collection("users").document(uid)
                    .collection("friends").document(friendDocId).delete()
                
                // Remove from friend's friends list
                let friendsFriendsSnapshot = try await db.collection("users").document(friend.userId)
                    .collection("friends")
                    .whereField("userId", isEqualTo: uid)
                    .getDocuments()
                
                for doc in friendsFriendsSnapshot.documents {
                    try await doc.reference.delete()
                }
                
                print("✅ Unfriended \(friend.name)")
                
                // Remove from local list
                await MainActor.run {
                    self.friends.removeAll { $0.id == friendDocId }
                }
                
            } catch {
                print("❌ Error unfriending user: \(error.localizedDescription)")
            }
        }
    }
}

// Helper extension for Friend initialization
extension Friend {
    init(id: String, userId: String, name: String, username: String?, addedAt: Date) {
        self._id = DocumentID(wrappedValue: id)
        self.userId = userId
        self.name = name
        self.username = username
        self.addedAt = addedAt
    }
}

#Preview {
    FriendsListView()
}
