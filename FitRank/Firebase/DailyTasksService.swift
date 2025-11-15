//
//  DailyTasksService.swift
//  FitRank
//
//  Service to handle daily task tracking and coin rewards (LOCAL STORAGE ONLY)
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class DailyTasksService {
    static let shared = DailyTasksService()
    private let db = Firestore.firestore()
    
    private let userDefaults = UserDefaults.standard
    private let tasksKey = "dailyTasks_"
    
    private init() {}
    
    // MARK: - Get Today's Tasks (Local)
    
    func getTodaysTasks(userId: String) async throws -> DailyTasks {
        let today = Calendar.current.startOfDay(for: Date())
        let dateString = formatDate(today)
        let key = "\(tasksKey)\(userId)_\(dateString)"
        
        // Try to load from UserDefaults
        if let data = userDefaults.data(forKey: key),
           let tasks = try? JSONDecoder().decode(DailyTasks.self, from: data),
           tasks.isToday {
            
            var updatedTasks = tasks
            var needsUpdate = false
            
            // Check if any tasks need to be reset
            if updatedTasks.canResetComments {
                updatedTasks.commentsCount = 0
                updatedTasks.commentsClaimed = false
                updatedTasks.commentsClaimedAt = nil
                needsUpdate = true
            }
            
            if updatedTasks.canResetUploads {
                updatedTasks.uploadsCount = 0
                updatedTasks.uploadsClaimed = false
                updatedTasks.uploadsClaimedAt = nil
                needsUpdate = true
            }
            
            if updatedTasks.canResetLikes {
                updatedTasks.likesCount = 0
                updatedTasks.likesClaimed = false
                updatedTasks.likesClaimedAt = nil
                needsUpdate = true
            }
            
            // Save reset tasks locally
            if needsUpdate {
                saveTasks(updatedTasks, key: key)
            }
            
            return updatedTasks
        } else {
            // Create new daily tasks for today
            let newTasks = DailyTasks(
                userId: userId,
                date: today,
                commentsCount: 0,
                commentsClaimed: false,
                commentsClaimedAt: nil,
                uploadsCount: 0,
                uploadsClaimed: false,
                uploadsClaimedAt: nil,
                likesCount: 0,
                likesClaimed: false,
                likesClaimedAt: nil,
                lastUpdated: Date()
            )
            saveTasks(newTasks, key: key)
            return newTasks
        }
    }
    
    // MARK: - Save Tasks Locally
    
    private func saveTasks(_ tasks: DailyTasks, key: String) {
        if let data = try? JSONEncoder().encode(tasks) {
            userDefaults.set(data, forKey: key)
            print("💾 Saved tasks locally: \(key)")
        }
    }
    
    // MARK: - Track Comment (NO COINS YET)
    
    func trackComment(userId: String) async throws -> (newCount: Int, maxed: Bool) {
        var tasks = try await getTodaysTasks(userId: userId)
        
        // Check if already maxed out
        guard tasks.commentsCount < DailyTasks.maxComments else {
            return (tasks.commentsCount, true)
        }
        
        // Increment count
        tasks.commentsCount += 1
        tasks.lastUpdated = Date()
        
        // Save updated tasks locally
        let dateString = formatDate(tasks.date)
        let key = "\(tasksKey)\(userId)_\(dateString)"
        saveTasks(tasks, key: key)
        
        let maxed = tasks.commentsCount >= DailyTasks.maxComments
        print("📝 Tracked comment: \(tasks.commentsCount)/\(DailyTasks.maxComments)")
        return (tasks.commentsCount, maxed)
    }
    
    // MARK: - Track Upload (NO COINS YET)
    
    func trackUpload(userId: String) async throws -> (newCount: Int, maxed: Bool) {
        var tasks = try await getTodaysTasks(userId: userId)
        
        // Check if already maxed out
        guard tasks.uploadsCount < DailyTasks.maxUploads else {
            return (tasks.uploadsCount, true)
        }
        
        // Increment count
        tasks.uploadsCount += 1
        tasks.lastUpdated = Date()
        
        // Save updated tasks locally
        let dateString = formatDate(tasks.date)
        let key = "\(tasksKey)\(userId)_\(dateString)"
        saveTasks(tasks, key: key)
        
        let maxed = tasks.uploadsCount >= DailyTasks.maxUploads
        print("⬆️ Tracked upload: \(tasks.uploadsCount)/\(DailyTasks.maxUploads)")
        return (tasks.uploadsCount, maxed)
    }
    
    // MARK: - Track Like (NO COINS YET)
    
    func trackLike(userId: String) async throws -> (newCount: Int, maxed: Bool) {
        var tasks = try await getTodaysTasks(userId: userId)
        
        // Check if already maxed out
        guard tasks.likesCount < DailyTasks.maxLikes else {
            return (tasks.likesCount, true)
        }
        
        // Increment count
        tasks.likesCount += 1
        tasks.lastUpdated = Date()
        
        // Save updated tasks locally
        let dateString = formatDate(tasks.date)
        let key = "\(tasksKey)\(userId)_\(dateString)"
        saveTasks(tasks, key: key)
        
        let maxed = tasks.likesCount >= DailyTasks.maxLikes
        print("❤️ Tracked like: \(tasks.likesCount)/\(DailyTasks.maxLikes)")
        return (tasks.likesCount, maxed)
    }
    
    // MARK: - Claim Comment Rewards
    
    func claimCommentRewards(userId: String) async throws -> Int {
        var tasks = try await getTodaysTasks(userId: userId)
        
        // Check if can claim
        guard tasks.canClaimComments else {
            throw ClaimError.cannotClaim
        }
        
        let coinsToAward = tasks.totalCommentsCoins
        
        // Mark as claimed with timestamp
        tasks.commentsClaimed = true
        tasks.commentsClaimedAt = Date()
        tasks.lastUpdated = Date()
        
        // Save updated tasks locally
        let dateString = formatDate(tasks.date)
        let key = "\(tasksKey)\(userId)_\(dateString)"
        saveTasks(tasks, key: key)
        
        // Add coins to Firebase user
        let userRef = db.collection("users").document(userId)
        try await userRef.updateData([
            "tokens": FieldValue.increment(Int64(coinsToAward))
        ])
        
        print("✅ Claimed comment rewards: \(coinsToAward) coins")
        return coinsToAward
    }
    
    // MARK: - Claim Upload Rewards
    
    func claimUploadRewards(userId: String) async throws -> Int {
        var tasks = try await getTodaysTasks(userId: userId)
        
        // Check if can claim
        guard tasks.canClaimUploads else {
            throw ClaimError.cannotClaim
        }
        
        let coinsToAward = tasks.totalUploadsCoins
        
        // Mark as claimed with timestamp
        tasks.uploadsClaimed = true
        tasks.uploadsClaimedAt = Date()
        tasks.lastUpdated = Date()
        
        // Save updated tasks locally
        let dateString = formatDate(tasks.date)
        let key = "\(tasksKey)\(userId)_\(dateString)"
        saveTasks(tasks, key: key)
        
        // Add coins to Firebase user
        let userRef = db.collection("users").document(userId)
        try await userRef.updateData([
            "tokens": FieldValue.increment(Int64(coinsToAward))
        ])
        
        print("✅ Claimed upload rewards: \(coinsToAward) coins")
        return coinsToAward
    }
    
    // MARK: - Claim Like Rewards
    
    func claimLikeRewards(userId: String) async throws -> Int {
        var tasks = try await getTodaysTasks(userId: userId)
        
        // Check if can claim
        guard tasks.canClaimLikes else {
            throw ClaimError.cannotClaim
        }
        
        let coinsToAward = tasks.totalLikesCoins
        
        // Mark as claimed with timestamp
        tasks.likesClaimed = true
        tasks.likesClaimedAt = Date()
        tasks.lastUpdated = Date()
        
        // Save updated tasks locally
        let dateString = formatDate(tasks.date)
        let key = "\(tasksKey)\(userId)_\(dateString)"
        saveTasks(tasks, key: key)
        
        // Add coins to Firebase user
        let userRef = db.collection("users").document(userId)
        try await userRef.updateData([
            "tokens": FieldValue.increment(Int64(coinsToAward))
        ])
        
        print("✅ Claimed like rewards: \(coinsToAward) coins")
        return coinsToAward
    }
    
    // MARK: - OLD METHOD (Keep for backwards compatibility, but just track)
    
    func addCommentCoins(userId: String) async throws -> (coinsEarned: Int, newCount: Int, maxed: Bool) {
        let result = try await trackComment(userId: userId)
        // Return 0 coins since they need to claim now
        return (0, result.newCount, result.maxed)
    }
    
    // MARK: - Clear Old Tasks (Optional cleanup)
    
    func clearOldTasks() {
        let allKeys = userDefaults.dictionaryRepresentation().keys
        let taskKeys = allKeys.filter { $0.hasPrefix(tasksKey) }
        
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        for key in taskKeys {
            if let data = userDefaults.data(forKey: key),
               let tasks = try? JSONDecoder().decode(DailyTasks.self, from: data),
               tasks.date < yesterday {
                userDefaults.removeObject(forKey: key)
                print("🗑️ Cleared old task: \(key)")
            }
        }
    }
    
    // MARK: - Helper
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - Errors

enum ClaimError: Error, LocalizedError {
    case cannotClaim
    case alreadyClaimed
    case notComplete
    
    var errorDescription: String? {
        switch self {
        case .cannotClaim:
            return "Cannot claim rewards yet"
        case .alreadyClaimed:
            return "Rewards already claimed"
        case .notComplete:
            return "Complete all tasks to claim rewards"
        }
    }
}
