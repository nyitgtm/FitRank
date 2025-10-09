//
//  UserSearchView.swift
//  FitRank
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct UserSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var searchVM = UserSearchViewModel()
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search by name or username...", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: searchText) { _, newValue in
                            // Real-time search as user types
                            searchVM.searchUsers(query: newValue)
                        }
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            searchVM.clearResults()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding()
                
                Divider()
                
                // Results
                if searchVM.isLoading {
                    Spacer()
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Searching...")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else if searchText.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("Find Friends")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Start typing a name or username")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    Spacer()
                } else if searchVM.searchResults.isEmpty && !searchVM.isLoading {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "person.fill.questionmark")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No users found")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("Try a different search")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(searchVM.searchResults, id: \.id) { user in
                                UserSearchRow(
                                    user: user,
                                    requestStatus: searchVM.getRequestStatus(for: user.id ?? ""),
                                    onRequestTap: {
                                        let status = searchVM.getRequestStatus(for: user.id ?? "")
                                        if status == .pending {
                                            searchVM.cancelFriendRequest(to: user)
                                        } else if status == .none {
                                            searchVM.sendFriendRequest(to: user)
                                        }
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Search Users")
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
            searchVM.loadFriendRequests()
        }
    }
}

struct UserSearchRow: View {
    let user: User
    let requestStatus: FriendRequestStatus
    let onRequestTap: () -> Void
    
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
                Text(user.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("@\(user.username)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if !user.team.isEmpty && user.team != "/teams/0" {
                    Text(user.team)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            // Request button
            Button(action: onRequestTap) {
                HStack(spacing: 6) {
                    Image(systemName: requestStatus.iconName)
                        .font(.caption)
                    Text(requestStatus.buttonText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(requestStatus.foregroundColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(requestStatus.backgroundColor)
                .cornerRadius(20)
            }
            .disabled(requestStatus == .alreadyFriends)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

enum FriendRequestStatus {
    case none
    case pending
    case alreadyFriends
    
    var buttonText: String {
        switch self {
        case .none: return "Add"
        case .pending: return "Pending"
        case .alreadyFriends: return "Friends"
        }
    }
    
    var iconName: String {
        switch self {
        case .none: return "person.badge.plus"
        case .pending: return "clock"
        case .alreadyFriends: return "checkmark"
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .none: return .white
        case .pending: return .orange
        case .alreadyFriends: return .green
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .none: return .blue
        case .pending: return .orange.opacity(0.2)
        case .alreadyFriends: return .green.opacity(0.2)
        }
    }
}

@MainActor
class UserSearchViewModel: ObservableObject {
    @Published var searchResults: [User] = []
    @Published var isLoading = false
    @Published var sentRequests: Set<String> = []
    @Published var friends: Set<String> = []
    
    private let db = Firestore.firestore()
    private var searchTask: Task<Void, Never>?
    
    func searchUsers(query: String) {
        // Cancel previous search task for efficiency
        searchTask?.cancel()
        
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            searchResults = []
            isLoading = false
            return
        }
        
        // Start searching immediately, even with 1 character
        isLoading = true
        
        searchTask = Task {
            // Add small debounce for better UX
            try? await Task.sleep(nanoseconds: 250_000_000) // 0.25 seconds
            
            if Task.isCancelled { return }
            
            do {
                let lowercaseQuery = trimmed.lowercased()
                
                // Fetch ALL users and filter in-memory for better partial matching
                // For production with many users, you'd want a better solution like Algolia
                let snapshot = try await db.collection("users")
                    .limit(to: 100) // Get more users for better results
                    .getDocuments()
                
                if Task.isCancelled { return }
                
                var matchedUsers: [User] = []
                
                for doc in snapshot.documents {
                    if let user = try? doc.data(as: User.self) {
                        // Don't show current user
                        if user.id == Auth.auth().currentUser?.uid {
                            continue
                        }
                        
                        let name = user.name.lowercased()
                        let username = user.username.lowercased()
                        
                        // Check if name or username contains the search query (partial match)
                        if name.contains(lowercaseQuery) || username.contains(lowercaseQuery) {
                            matchedUsers.append(user)
                        }
                    }
                }
                
                // Sort results: exact matches first, then by relevance
                matchedUsers.sort { user1, user2 in
                    let name1 = user1.name.lowercased()
                    let name2 = user2.name.lowercased()
                    let username1 = user1.username.lowercased()
                    let username2 = user2.username.lowercased()
                    
                    // Prioritize matches that start with the query
                    let name1Starts = name1.hasPrefix(lowercaseQuery)
                    let name2Starts = name2.hasPrefix(lowercaseQuery)
                    let username1Starts = username1.hasPrefix(lowercaseQuery)
                    let username2Starts = username2.hasPrefix(lowercaseQuery)
                    
                    if name1Starts && !name2Starts { return true }
                    if name2Starts && !name1Starts { return false }
                    if username1Starts && !username2Starts { return true }
                    if username2Starts && !username1Starts { return false }
                    
                    // If both start with query or neither does, sort alphabetically
                    return name1 < name2
                }
                
                if Task.isCancelled { return }
                
                await MainActor.run {
                    self.searchResults = Array(matchedUsers.prefix(20)) // Limit to 20 results
                    self.isLoading = false
                }
                
            } catch {
                if !Task.isCancelled {
                    print("❌ Search error: \(error.localizedDescription)")
                    await MainActor.run {
                        self.searchResults = []
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
    func clearResults() {
        searchTask?.cancel()
        searchResults = []
        isLoading = false
    }
    
    func loadFriendRequests() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Task {
            // Load sent requests
            let sentSnapshot = try? await db.collection("users").document(uid)
                .collection("friendRequests")
                .whereField("status", isEqualTo: "pending")
                .getDocuments()
            
            let sentIds = sentSnapshot?.documents.compactMap { $0.data()["toUserId"] as? String } ?? []
            
            // Load friends list
            let friendsSnapshot = try? await db.collection("users").document(uid)
                .collection("friends")
                .getDocuments()
            
            let friendIds = friendsSnapshot?.documents.compactMap { $0.documentID } ?? []
            
            await MainActor.run {
                self.sentRequests = Set(sentIds)
                self.friends = Set(friendIds)
            }
        }
    }
    
    func sendFriendRequest(to user: User) {
        guard let uid = Auth.auth().currentUser?.uid,
              let toUserId = user.id else { return }
        
        Task {
            do {
                // Get current user info
                let userDoc = try await db.collection("users").document(uid).getDocument()
                let fromName = (userDoc.data()?["name"] as? String) ?? "Someone"
                let fromUsername = (userDoc.data()?["username"] as? String) ?? ""
                
                // Create friend request document in recipient's collection
                let requestRef = db.collection("users").document(toUserId)
                    .collection("friendRequests").document()
                
                try await requestRef.setData([
                    "fromUserId": uid,
                    "fromName": fromName,
                    "fromUsername": fromUsername,
                    "toUserId": toUserId,
                    "status": "pending",
                    "createdAt": FieldValue.serverTimestamp()
                ])
                
                // Also save in sender's sent requests
                let sentRef = db.collection("users").document(uid)
                    .collection("friendRequests").document()
                
                try await sentRef.setData([
                    "fromUserId": uid,
                    "toUserId": toUserId,
                    "status": "pending",
                    "createdAt": FieldValue.serverTimestamp()
                ])
                
                await MainActor.run {
                    self.sentRequests.insert(toUserId)
                    print("✅ Friend request sent to \(user.name)")
                }
                
            } catch {
                print("❌ Error sending friend request: \(error.localizedDescription)")
            }
        }
    }
    
    func cancelFriendRequest(to user: User) {
        guard let uid = Auth.auth().currentUser?.uid,
              let toUserId = user.id else { return }
        
        Task {
            do {
                // Delete from recipient's friendRequests
                let recipientRequestsSnapshot = try await db.collection("users").document(toUserId)
                    .collection("friendRequests")
                    .whereField("fromUserId", isEqualTo: uid)
                    .whereField("status", isEqualTo: "pending")
                    .getDocuments()
                
                for doc in recipientRequestsSnapshot.documents {
                    try await doc.reference.delete()
                }
                
                // Delete from sender's friendRequests
                let senderRequestsSnapshot = try await db.collection("users").document(uid)
                    .collection("friendRequests")
                    .whereField("toUserId", isEqualTo: toUserId)
                    .whereField("status", isEqualTo: "pending")
                    .getDocuments()
                
                for doc in senderRequestsSnapshot.documents {
                    try await doc.reference.delete()
                }
                
                await MainActor.run {
                    self.sentRequests.remove(toUserId)
                    print("✅ Friend request cancelled for \(user.name)")
                }
                
            } catch {
                print("❌ Error cancelling friend request: \(error.localizedDescription)")
            }
        }
    }
    
    func getRequestStatus(for userId: String) -> FriendRequestStatus {
        if friends.contains(userId) {
            return .alreadyFriends
        } else if sentRequests.contains(userId) {
            return .pending
        } else {
            return .none
        }
    }
}

#Preview {
    UserSearchView()
}
