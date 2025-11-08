//
//  DailyTasksService.swift
//  FitRank
//
//  Service to handle daily task tracking and coin rewards
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class DailyTasksService {
    static let shared = DailyTasksService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Get Today's Tasks
    
    func getTodaysTasks(userId: String) async throws -> DailyTasks {
        let today = Calendar.current.startOfDay(for: Date())
        let dateString = formatDate(today)
        
        let docRef = db.collection("dailyTasks").document("\(userId)_\(dateString)")
        let document = try await docRef.getDocument()
        
        if var tasks = try? document.data(as: DailyTasks.self), tasks.isToday {
            // Check if any tasks need to be reset
            var needsUpdate = false
            
            if tasks.canResetComments {
                tasks.commentsCount = 0
                tasks.commentsClaimed = false
                tasks.commentsClaimedAt = nil
                needsUpdate = true
            }
            
            if tasks.canResetUploads {
                tasks.uploadsCount = 0
                tasks.uploadsClaimed = false
                tasks.uploadsClaimedAt = nil
                needsUpdate = true
            }
            
            if tasks.canResetLikes {
                tasks.likesCount = 0
                tasks.likesClaimed = false
                tasks.likesClaimedAt = nil
                needsUpdate = true
            }
            
            // Save reset tasks
            if needsUpdate {
                try await docRef.setData(from: tasks)
            }
            
            return tasks
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
            try await docRef.setData(from: newTasks)
            return newTasks
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
        
        // Save updated tasks
        let dateString = formatDate(tasks.date)
        let docRef = db.collection("dailyTasks").document("\(userId)_\(dateString)")
        try await docRef.setData(from: tasks)
        
        let maxed = tasks.commentsCount >= DailyTasks.maxComments
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
        
        // Save updated tasks
        let dateString = formatDate(tasks.date)
        let docRef = db.collection("dailyTasks").document("\(userId)_\(dateString)")
        try await docRef.setData(from: tasks)
        
        let maxed = tasks.uploadsCount >= DailyTasks.maxUploads
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
        
        // Save updated tasks
        let dateString = formatDate(tasks.date)
        let docRef = db.collection("dailyTasks").document("\(userId)_\(dateString)")
        try await docRef.setData(from: tasks)
        
        let maxed = tasks.likesCount >= DailyTasks.maxLikes
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
        
        // Save updated tasks
        let dateString = formatDate(tasks.date)
        let docRef = db.collection("dailyTasks").document("\(userId)_\(dateString)")
        try await docRef.setData(from: tasks)
        
        // Add coins to user
        let userRef = db.collection("users").document(userId)
        try await userRef.updateData([
            "tokens": FieldValue.increment(Int64(coinsToAward))
        ])
        
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
        
        // Save updated tasks
        let dateString = formatDate(tasks.date)
        let docRef = db.collection("dailyTasks").document("\(userId)_\(dateString)")
        try await docRef.setData(from: tasks)
        
        // Add coins to user
        let userRef = db.collection("users").document(userId)
        try await userRef.updateData([
            "tokens": FieldValue.increment(Int64(coinsToAward))
        ])
        
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
        
        // Save updated tasks
        let dateString = formatDate(tasks.date)
        let docRef = db.collection("dailyTasks").document("\(userId)_\(dateString)")
        try await docRef.setData(from: tasks)
        
        // Add coins to user
        let userRef = db.collection("users").document(userId)
        try await userRef.updateData([
            "tokens": FieldValue.increment(Int64(coinsToAward))
        ])
        
        return coinsToAward
    }
    
    // MARK: - OLD METHOD (Keep for backwards compatibility, but just track)
    
    func addCommentCoins(userId: String) async throws -> (coinsEarned: Int, newCount: Int, maxed: Bool) {
        let result = try await trackComment(userId: userId)
        // Return 0 coins since they need to claim now
        return (0, result.newCount, result.maxed)
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
