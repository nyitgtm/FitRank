//
//  EnvironmentConfig.swift
//  FitRank
//
//  Loads configuration from .env file
//  Keeps sensitive credentials out of source code
//

import Foundation

enum EnvironmentConfig {
    
    private static var envVars: [String: String] = {
        loadEnvFile()
    }()
    
    /// Load .env file from bundle
    private static func loadEnvFile() -> [String: String] {
        var envVars: [String: String] = [:]
        
        // Try to find .env file in bundle
        guard let envPath = Bundle.main.path(forResource: ".env", ofType: nil) else {
            print("⚠️ Warning: .env file not found. Using default values.")
            return envVars
        }
        
        do {
            let envContent = try String(contentsOfFile: envPath, encoding: .utf8)
            let lines = envContent.components(separatedBy: .newlines)
            
            for line in lines {
                // Skip empty lines and comments
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                    continue
                }
                
                // Parse KEY=VALUE format
                let parts = trimmedLine.components(separatedBy: "=")
                if parts.count == 2 {
                    let key = parts[0].trimmingCharacters(in: .whitespaces)
                    let value = parts[1].trimmingCharacters(in: .whitespaces)
                    envVars[key] = value
                }
            }
            
            print("✅ Loaded \(envVars.count) environment variables from .env")
        } catch {
            print("❌ Error reading .env file: \(error)")
        }
        
        return envVars
    }
    
    /// Get environment variable value
    private static func get(_ key: String) -> String? {
        return envVars[key]
    }
    
    // MARK: - R2 Configuration
    
    static var r2AccountId: String {
        return get("R2_ACCOUNT_ID") ?? ""
    }
    
    static var r2AccessKeyId: String {
        return get("R2_ACCESS_KEY_ID") ?? ""
    }
    
    static var r2SecretAccessKey: String {
        return get("R2_SECRET_ACCESS_KEY") ?? ""
    }
    
    static var r2BucketName: String {
        return get("R2_BUCKET_NAME") ?? "videos"
    }
    
    static var r2PublicURL: String {
        return get("R2_PUBLIC_URL") ?? ""
    }
    
    // MARK: - Validation
    
    static func validateConfiguration() -> Bool {
        let required = [
            r2AccountId,
            r2AccessKeyId,
            r2SecretAccessKey,
            r2PublicURL
        ]
        
        let allPresent = required.allSatisfy { !$0.isEmpty }
        
        if !allPresent {
            print("❌ Missing required environment variables!")
            print("   Make sure .env file exists and contains all required values.")
            print("   Copy .env.template to .env and fill in your credentials.")
        }
        
        return allPresent
    }
}
