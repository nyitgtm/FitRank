import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

// Small Data helper
fileprivate extension Data {
    mutating func appendString(_ string: String) {
        if let d = string.data(using: .utf8) {
            append(d)
        }
    }
}

// MARK: - Models (single source of truth)


struct CommunityComment: Identifiable, Hashable {
    let id: UUID = UUID()
    var backendId: String          // Firestore comment doc id
    var authorId: String           // who wrote it
    var authorName: String
    var text: String
    var createdAt: Date
}


struct CommunityPost: Identifiable, Hashable {
    let id: UUID = UUID()
    var backendId: String?          // Firestore doc id
    var authorId: String            // who wrote it
    var authorName: String
    var teamTag: String?
    var text: String
    var image: UIImage?             // local draft only
    var imageURLString: String?     // remote display
    var likeCount: Int
    var commentCount: Int
    var isLikedByMe: Bool
    var createdAt: Date
    var comments: [CommunityComment] = []
}

struct CommunityNotification: Identifiable, Hashable {
    let id: UUID = UUID()
    var backendId: String          // Firestore notification doc id
    var type: String               // "like" or "comment"
    var actorId: String            // who performed the action
    var actorName: String
    var postId: String             // which post
    var postText: String           // preview of post
    var isRead: Bool
    var createdAt: Date
}


// MARK: - Minimal Firebase Community Service
@MainActor

final class CommunityService {
    static let shared = CommunityService()
    private let db = Firestore.firestore()
    private let dailyTasksService = DailyTasksService.shared
    private init() {}

   public var feedListener: ListenerRegistration?
    func deleteComment(postId: String, commentId: String) async throws {
        let postRef = db.collection("posts").document(postId)
        try await postRef.collection("comments").document(commentId).delete()
        try await postRef.updateData(["commentCount": FieldValue.increment(Int64(-1))])
    }
    // 1) Add this property near the top of CommunityService (with feedListener)
    private var commentsListener: ListenerRegistration?
    private var notificationsListener: ListenerRegistration?

    // 2) Add these methods anywhere inside CommunityService:

    // Live comments for a post
    func startComments(postId: String, onChange: @escaping ([CommunityComment]) -> Void) {
        commentsListener?.remove()
        commentsListener = db.collection("posts").document(postId)
            .collection("comments")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snap, _ in
                let items: [CommunityComment] = (snap?.documents ?? []).compactMap { doc in
                    let data = doc.data()
                    return CommunityComment(
                        backendId: doc.documentID,
                        authorId: data["authorId"] as? String ?? "",
                        authorName: data["authorName"] as? String ?? "User",
                        text: data["text"] as? String ?? "",
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                }
                onChange(items)
            }
    }

    // Stop comments listener
    func stopComments() {
        commentsListener?.remove()
        commentsListener = nil
    }

    // Delete a single comment and decrement counter
   
    // MARK: - Notifications
    
    func startNotifications(onChange: @escaping ([CommunityNotification]) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        notificationsListener?.remove()
        notificationsListener = db.collection("users").document(uid)
            .collection("notifications")
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .addSnapshotListener { snap, _ in
                let items: [CommunityNotification] = (snap?.documents ?? []).compactMap { doc in
                    let data = doc.data()
                    return CommunityNotification(
                        backendId: doc.documentID,
                        type: data["type"] as? String ?? "like",
                        actorId: data["actorId"] as? String ?? "",
                        actorName: data["actorName"] as? String ?? "User",
                        postId: data["postId"] as? String ?? "",
                        postText: data["postText"] as? String ?? "",
                        isRead: data["isRead"] as? Bool ?? false,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                }
                onChange(items)
            }
    }
    
    func stopNotifications() {
        notificationsListener?.remove()
        notificationsListener = nil
    }
    
    func markNotificationAsRead(notificationId: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let notifRef = db.collection("users").document(uid).collection("notifications").document(notificationId)
        try? await notifRef.updateData(["isRead": true])
    }
    
    func markAllNotificationsAsRead() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let snapshot = try? await db.collection("users").document(uid)
            .collection("notifications")
            .whereField("isRead", isEqualTo: false)
            .getDocuments()
        
        guard let docs = snapshot?.documents else { return }
        for doc in docs {
            try? await doc.reference.updateData(["isRead": true])
        }
    }

    func startFeed(onChange: @escaping ([CommunityFeedItem]) -> Void) {
        feedListener?.remove()
        feedListener = db.collection("posts")
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .addSnapshotListener { snap, _ in
                let items: [CommunityFeedItem] = (snap?.documents ?? []).compactMap { doc in
                    let data = doc.data()
                    
                    // Debug: Check what createdAt value we're getting
                    if let timestamp = data["createdAt"] as? Timestamp {
                        let date = timestamp.dateValue()
                        print("📅 Post \(doc.documentID): createdAt = \(date)")
                    } else {
                        print("⚠️ Post \(doc.documentID): createdAt is nil!")
                    }
                    
                    // Try to get createdAt from document data
                    let createdAt: Date
                    if let timestamp = data["createdAt"] as? Timestamp {
                        createdAt = timestamp.dateValue()
                    } else if doc.metadata.hasPendingWrites {
                        // Brand new document being written
                        createdAt = Date()
                        print("🆕 Using current time for pending document")
                    } else {
                        // Existing document without timestamp - use fallback
                        createdAt = Date()
                        print("⚠️ Using fallback Date() for existing document without timestamp")
                    }
                    
                    return CommunityFeedItem(
                        id: doc.documentID,
                        authorId: data["authorId"] as? String ?? "",
                        authorName: data["authorName"] as? String ?? "User",
                        teamTag: data["teamTag"] as? String,
                        text: data["text"] as? String ?? "",
                        imageURLString: data["imageURL"] as? String,
                        likeCount: data["likeCount"] as? Int ?? 0,
                        commentCount: data["commentCount"] as? Int ?? 0,
                        createdAt: createdAt
                    )
                }
                onChange(items)
            }
    }


    func stopFeed() {
        feedListener?.remove()
        feedListener = nil
    }

    func publish(text: String, image: UIImage?) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { throw NSError(domain: "auth", code: 401) }

        // pull display name + team from users/{uid}
        let userDoc = try await db.collection("users").document(uid).getDocument()
        let authorName = (userDoc.data()?["name"] as? String)
                        ?? (userDoc.data()?["username"] as? String)
                        ?? "User"

        var teamName: String? = nil
        if let teamPathOrName = userDoc.data()?["team"] as? String, !teamPathOrName.isEmpty {
            if teamPathOrName.contains("/teams/") {
                // treat as document path
                let teamDoc = try await db.document(teamPathOrName).getDocument()
                teamName = teamDoc.data()?["name"] as? String ?? teamPathOrName
            } else {
                // treat as plain string
                teamName = teamPathOrName
            }
        }

        let ref = db.collection("posts").document()

        var imageURL: String? = nil
        var textToSave = text

        if let image, let data = image.jpegData(compressionQuality: 0.85) {
            // Try uploading to the external API first (store returned URL in imageURL)
            if let uploaded = try? await uploadImageToNetlifyAPI(data: data, fileName: "photo.jpg") {
                imageURL = uploaded
            } else {
                // Fallback: upload to Firebase Storage if external API fails
                let storageRef = Storage.storage().reference(withPath: "posts/\(ref.documentID)/photo.jpg")
                _ = try await storageRef.putDataAsync(data, metadata: nil)
                imageURL = try await storageRef.downloadURL().absoluteString
            }
        }

        try await ref.setData([
            "authorId": uid,
            "authorName": authorName,
            "teamTag": teamName as Any,
            "text": textToSave,
            "imageURL": imageURL as Any,
            "likeCount": 0,
            "commentCount": 0,
            "createdAt": FieldValue.serverTimestamp()
        ])
    }

    // Upload image bytes to the Netlify API endpoint and return the returned URL string.
    private func uploadImageToNetlifyAPI(data: Data, fileName: String) async throws -> String {
        let url = URL(string: "https://fitrank.netlify.app/api/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"")
        body.appendString(fileName)
        body.appendString("\"\r\n")
        body.appendString("Content-Type: image/jpeg\r\n\r\n")
        body.append(data)
        body.appendString("\r\n")
        body.appendString("--\(boundary)--\r\n")

        request.httpBody = body

        let (respData, resp) = try await URLSession.shared.data(for: request)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NSError(domain: "upload", code: 1, userInfo: ["response": resp])
        }

        // Try parse JSON: { "url": "https://..." }
        if let json = try? JSONSerialization.jsonObject(with: respData) as? [String: Any] {
            if let urlStr = (json["url"] as? String) ?? (json["link"] as? String) ?? (json["location"] as? String) {
                return urlStr
            }
        }

        // Fallback: treat body as plain text URL
        if let bodyString = String(data: respData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !bodyString.isEmpty {
            return bodyString
        }

        throw NSError(domain: "upload", code: 2, userInfo: [NSLocalizedDescriptionKey: "No URL returned from upload API"]) 
    }

    func toggleLike(postId: String, postAuthorId: String, postText: String, currentlyLiked: Bool) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let postRef = db.collection("posts").document(postId)
        let likeRef = postRef.collection("likes").document(uid)
        
        do {
            if currentlyLiked {
                // Unlike - remove like and notification
                try await likeRef.delete()
                try await postRef.updateData(["likeCount": FieldValue.increment(Int64(-1))])
                
                // Remove notification if it exists
                if postAuthorId != uid {
                    let notifSnapshot = try await db.collection("users").document(postAuthorId)
                        .collection("notifications")
                        .whereField("actorId", isEqualTo: uid)
                        .whereField("postId", isEqualTo: postId)
                        .whereField("type", isEqualTo: "like")
                        .getDocuments()
                    
                    for doc in notifSnapshot.documents {
                        try await doc.reference.delete()
                    }
                }
            } else {
                // Like - add like and create notification
                try await likeRef.setData(["createdAt": FieldValue.serverTimestamp()])
                try await postRef.updateData(["likeCount": FieldValue.increment(Int64(1))])
                
                // Create notification for post author (but not if liking own post)
                if postAuthorId != uid {
                    let userDoc = try await db.collection("users").document(uid).getDocument()
                    let likerName = (userDoc.data()?["name"] as? String)
                                   ?? (userDoc.data()?["username"] as? String)
                                   ?? "Someone"
                    
                    let notifRef = db.collection("users").document(postAuthorId)
                        .collection("notifications").document()
                    
                    try await notifRef.setData([
                        "type": "like",
                        "actorId": uid,
                        "actorName": likerName,
                        "postId": postId,
                        "postText": String(postText.prefix(50)),
                        "isRead": false,
                        "createdAt": FieldValue.serverTimestamp()
                    ])
                }
                
                // ✅ TRACK LIKE FOR DAILY TASKS (only when liking, not unliking)
                do {
                    let result = try await dailyTasksService.trackLike(userId: uid)
                    
                    if result.maxed {
                        print("✅ Like progress: \(result.newCount)/\(DailyTasks.maxLikes) - READY TO CLAIM!")
                        
                        // Post notification that task is complete
                        await MainActor.run {
                            NotificationCenter.default.post(
                                name: NSNotification.Name("DailyTaskComplete"),
                                object: nil,
                                userInfo: ["taskType": "likes", "count": result.newCount]
                            )
                        }
                    } else {
                        print("✅ Like progress: \(result.newCount)/\(DailyTasks.maxLikes)")
                    }
                } catch {
                    print("Failed to track like: \(error)")
                    // Don't fail the like if tracking fails
                }
            }
        } catch {
            print("toggleLike error:", error)
        }
    }

    func isLikedByMe(postId: String) async -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        let likeDoc = try? await db.collection("posts").document(postId)
            .collection("likes").document(uid).getDocument()
        return (likeDoc?.exists ?? false)
    }

    func addComment(postId: String, text: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            let userDoc = try await db.collection("users").document(uid).getDocument()
            let name = (userDoc.data()?["name"] as? String)
                     ?? (userDoc.data()?["username"] as? String) ?? "User"

            let ref = db.collection("posts").document(postId).collection("comments").document()
            try await ref.setData([
                "authorId": uid,
                "authorName": name,
                "text": text,
                "createdAt": FieldValue.serverTimestamp()
            ])

            try await db.collection("posts").document(postId)
                .updateData(["commentCount": FieldValue.increment(Int64(1))])
            
            // ✅ AWARD COINS FOR COMMENTING
            do {
                let result = try await dailyTasksService.addCommentCoins(userId: uid)
                
                if result.coinsEarned > 0 {
                    print("✅ Awarded \(result.coinsEarned) coins! Progress: \(result.newCount)/\(DailyTasks.maxComments)")
                    
                    // Post notification that coins were earned
                    await MainActor.run {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("CoinsEarned"),
                            object: nil,
                            userInfo: ["amount": result.coinsEarned]
                        )
                    }
                } else if result.maxed {
                    print("⚠️ Daily comment limit reached (3/3)")
                }
            } catch {
                print("Failed to award coins: \(error)")
                // Don't fail the comment if coin award fails
            }
            
        } catch {
            print("addComment error:", error)
        }
    }
}

// MARK: - Firebase-backed ViewModel
@MainActor
final class CommunityVM_Firebase: ObservableObject {
    @Published var posts: [CommunityPost] = []
    @Published var notifications: [CommunityNotification] = []
    @Published var isLoading = false
    @Published var showComposer = false
    @Published var draftText = ""
    @Published var draftImage: UIImage?
    @Published var showCoinReward = false
    @Published var coinsEarned = 0
    
    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    private let svc = CommunityService.shared

    init() { 
        listen()
        listenNotifications()
        setupCoinNotifications()
    }
    
    private func setupCoinNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("CoinsEarned"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let amount = notification.userInfo?["amount"] as? Int {
                self?.coinsEarned = amount
                self?.showCoinReward = true
                
                // Haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                // Hide after 2.5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    self?.showCoinReward = false
                }
            }
        }
    }

    private func listen() {
        isLoading = true
        svc.startFeed { [weak self] items in
            Task { @MainActor in
                guard let self else { return }
                var mapped: [CommunityPost] = []
                for it in items {
                    let liked = await self.svc.isLikedByMe(postId: it.id)
                    mapped.append(
                        CommunityPost(
                            backendId: it.id,
                            authorId: it.authorId, // Fixed: was empty string
                            authorName: it.authorName,
                            teamTag: it.teamTag,
                            text: it.text,
                            image: nil,
                            imageURLString: it.imageURLString,
                            likeCount: it.likeCount,
                            commentCount: it.commentCount,
                            isLikedByMe: liked,
                            createdAt: it.createdAt,
                            comments: []
                        )
                    )
                }
                self.posts = mapped
                self.isLoading = false
            }
        }
    }
    
    private func listenNotifications() {
        svc.startNotifications { [weak self] items in
            Task { @MainActor in
                self?.notifications = items
            }
        }
    }

    deinit {
        Task { @MainActor in
            CommunityService.shared.stopFeed()
            CommunityService.shared.stopNotifications()
        }
    }


    func publishDraft() {
        let trimmed = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || draftImage != nil else { return }
        Task {
            do {
                try await svc.publish(text: trimmed, image: draftImage)
                await MainActor.run {
                    draftText = ""
                    draftImage = nil
                    showComposer = false
                }
            } catch {
                print("publish error:", error)
            }
        }
    }

    func toggleLike(_ post: CommunityPost) {
        guard let id = post.backendId else { return }
        Task { 
            await svc.toggleLike(
                postId: id,
                postAuthorId: post.authorId,
                postText: post.text,
                currentlyLiked: post.isLikedByMe
            )
        }
        // optimistic UI
        if let i = posts.firstIndex(of: post) {
            posts[i].isLikedByMe.toggle()
            posts[i].likeCount += posts[i].isLikedByMe ? 1 : -1
        }
    }

    func addComment(_ text: String, to post: CommunityPost) {
        guard let id = post.backendId else { return }
        let msg = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !msg.isEmpty else { return }
        Task { await svc.addComment(postId: id, text: msg) }
    }
    
    func deletePost(_ post: CommunityPost) {
        guard let id = post.backendId else { return }
        
        // Optimistic UI - remove from list immediately
        if let index = posts.firstIndex(where: { $0.backendId == id }) {
            posts.remove(at: index)
        }
        
        // Delete from Firebase
        Task {
            do {
                try await svc.deletePost(postId: id)
            } catch {
                print("Failed to delete post: \(error)")
                // Could re-fetch or show error here
            }
        }
    }
    
    func markNotificationAsRead(_ notification: CommunityNotification) {
        Task {
            await svc.markNotificationAsRead(notificationId: notification.backendId)
        }
    }
    
    func markAllNotificationsAsRead() {
        Task {
            await svc.markAllNotificationsAsRead()
        }
    }
}


import FirebaseFirestore
import FirebaseStorage

extension CommunityService {
    /// Delete post + its subcollections (comments/likes) + storage image
    func deletePost(postId: String) async throws {
        let postRef = db.collection("posts").document(postId)

        // delete comments
        let commentsSnap = try await postRef.collection("comments").getDocuments()
        for doc in commentsSnap.documents {
            try await doc.reference.delete()
        }

        // delete likes
        let likesSnap = try await postRef.collection("likes").getDocuments()
        for doc in likesSnap.documents {
            try await doc.reference.delete()
        }

        // delete image (best-effort)
        let storageRef = Storage.storage().reference(withPath: "posts/\(postId)/photo.jpg")
        try? await storageRef.delete()

        // delete post
        try await postRef.delete()
    }
}
