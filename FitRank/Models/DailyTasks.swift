//
//  DailyTasks.swift
//  FitRank
//
//  Model for tracking daily coin-earning tasks
//

import Foundation
import FirebaseFirestore

struct DailyTasks: Codable {
    var userId: String
    var date: Date
    var commentsCount: Int = 0
    var commentsClaimed: Bool = false
    var commentsClaimedAt: Date?  // NEW: Track when claimed
    var uploadsCount: Int = 0
    var uploadsClaimed: Bool = false
    var uploadsClaimedAt: Date?  // NEW: Track when claimed
    var likesCount: Int = 0  // NEW
    var likesClaimed: Bool = false  // NEW
    var likesClaimedAt: Date?  // NEW: Track when claimed
    var lastUpdated: Date
    
    // Daily limits
    static let maxComments = 3
    static let coinsPerComment = 100
    static let maxUploads = 1
    static let coinsPerUpload = 100
    static let maxLikes = 5  // NEW
    static let coinsPerLike = 100  // NEW
    static let resetIntervalHours = 12  // NEW: 12 hour reset
    
    enum CodingKeys: String, CodingKey {
        case userId
        case date
        case commentsCount
        case commentsClaimed
        case commentsClaimedAt
        case uploadsCount
        case uploadsClaimed
        case uploadsClaimedAt
        case likesCount
        case likesClaimed
        case likesClaimedAt
        case lastUpdated
    }
    
    // Check if this is today's record
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    // Check if comments are maxed out
    var commentsMaxed: Bool {
        commentsCount >= Self.maxComments
    }
    
    // Check if uploads are maxed out
    var uploadsMaxed: Bool {
        uploadsCount >= Self.maxUploads
    }
    
    // Check if likes are maxed out
    var likesMaxed: Bool {
        likesCount >= Self.maxLikes
    }
    
    // Get progress for comments (0.0 to 1.0)
    var commentsProgress: Double {
        Double(commentsCount) / Double(Self.maxComments)
    }
    
    // Get progress for uploads (0.0 to 1.0)
    var uploadsProgress: Double {
        Double(uploadsCount) / Double(Self.maxUploads)
    }
    
    // Get progress for likes (0.0 to 1.0)
    var likesProgress: Double {
        Double(likesCount) / Double(Self.maxLikes)
    }
    
    // Total coins available to claim for comments
    var totalCommentsCoins: Int {
        commentsCount * Self.coinsPerComment
    }
    
    // Total coins available to claim for uploads
    var totalUploadsCoins: Int {
        uploadsCount * Self.coinsPerUpload
    }
    
    // Total coins available to claim for likes
    var totalLikesCoins: Int {
        likesCount * Self.coinsPerLike
    }
    
    // MARK: - Timer Logic
    
    // Check if comments can be reset (12 hours passed since claim)
    var canResetComments: Bool {
        guard let claimedAt = commentsClaimedAt, commentsClaimed else {
            return false
        }
        let hoursSinceClaim = Date().timeIntervalSince(claimedAt) / 3600
        return hoursSinceClaim >= Double(Self.resetIntervalHours)
    }
    
    // Check if uploads can be reset
    var canResetUploads: Bool {
        guard let claimedAt = uploadsClaimedAt, uploadsClaimed else {
            return false
        }
        let hoursSinceClaim = Date().timeIntervalSince(claimedAt) / 3600
        return hoursSinceClaim >= Double(Self.resetIntervalHours)
    }
    
    // Check if likes can be reset
    var canResetLikes: Bool {
        guard let claimedAt = likesClaimedAt, likesClaimed else {
            return false
        }
        let hoursSinceClaim = Date().timeIntervalSince(claimedAt) / 3600
        return hoursSinceClaim >= Double(Self.resetIntervalHours)
    }
    
    // Time remaining for comments reset (in seconds)
    var commentsTimeRemaining: TimeInterval {
        guard let claimedAt = commentsClaimedAt, commentsClaimed else {
            return 0
        }
        let resetTime = claimedAt.addingTimeInterval(TimeInterval(Self.resetIntervalHours * 3600))
        return max(0, resetTime.timeIntervalSince(Date()))
    }
    
    // Time remaining for uploads reset
    var uploadsTimeRemaining: TimeInterval {
        guard let claimedAt = uploadsClaimedAt, uploadsClaimed else {
            return 0
        }
        let resetTime = claimedAt.addingTimeInterval(TimeInterval(Self.resetIntervalHours * 3600))
        return max(0, resetTime.timeIntervalSince(Date()))
    }
    
    // Time remaining for likes reset
    var likesTimeRemaining: TimeInterval {
        guard let claimedAt = likesClaimedAt, likesClaimed else {
            return 0
        }
        let resetTime = claimedAt.addingTimeInterval(TimeInterval(Self.resetIntervalHours * 3600))
        return max(0, resetTime.timeIntervalSince(Date()))
    }
    
    // Can claim comment rewards (maxed and not claimed, or ready for reset)
    var canClaimComments: Bool {
        if canResetComments {
            return true  // Can claim again after reset
        }
        return commentsMaxed && !commentsClaimed
    }
    
    // Can claim upload rewards
    var canClaimUploads: Bool {
        if canResetUploads {
            return true
        }
        return uploadsMaxed && !uploadsClaimed
    }
    
    // Can claim like rewards
    var canClaimLikes: Bool {
        if canResetLikes {
            return true
        }
        return likesMaxed && !likesClaimed
    }
}
