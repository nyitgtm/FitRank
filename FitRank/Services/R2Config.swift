//
//  R2Config.swift
//  FitRank
//
//  Cloudflare R2 Configuration
//  Now reads from .env file for security!
//

import Foundation

struct R2Config {
    // MARK: - Cloudflare R2 Credentials (from .env)
    static let accountId = EnvironmentConfig.r2AccountId
    static let accessKeyId = EnvironmentConfig.r2AccessKeyId
    static let secretAccessKey = EnvironmentConfig.r2SecretAccessKey
    static let bucketName = EnvironmentConfig.r2BucketName
    
    // MARK: - Endpoints
    static let endpoint = "https://\(accountId).r2.cloudflarestorage.com"
    static let publicBucketURL = EnvironmentConfig.r2PublicURL
    
    // MARK: - Constraints
    static let maxVideoDurationSeconds: Double = 30.0
    static let maxFileSizeMB: Double = 50.0 // Max size before compression
    
    // MARK: - Validation
    static func isConfigured() -> Bool {
        return EnvironmentConfig.validateConfiguration()
    }
}
