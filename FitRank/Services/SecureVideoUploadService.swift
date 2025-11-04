//
//  SecureVideoUploadService.swift
//  FitRank
//
//  PRODUCTION VERSION - Uses backend-generated presigned URLs
//  This keeps R2 credentials secure on your backend
//

import Foundation
import AVFoundation
import UIKit

@MainActor
class SecureVideoUploadService: ObservableObject {
    
    @Published var uploadProgress: Double = 0.0
    @Published var isUploading: Bool = false
    
    // MARK: - Secure Upload Flow
    
    /// Step 1: Request presigned URL from backend
    private func getPresignedUploadURL(workoutId: String) async throws -> String {
        // Call your Firebase Function
        let functionURL = "https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/generatePresignedUploadURL"
        
        guard let url = URL(string: functionURL) else {
            throw VideoError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["workoutId": workoutId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw VideoError.uploadFailed
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let presignedURL = json?["uploadUrl"] as? String else {
            throw VideoError.invalidURL
        }
        
        return presignedURL
    }
    
    /// Step 2: Upload directly to R2 using presigned URL (NO CREDENTIALS NEEDED!)
    func uploadVideoSecurely(localURL: URL, workoutId: String) async throws -> String {
        isUploading = true
        uploadProgress = 0.0
        
        defer {
            isUploading = false
            uploadProgress = 0.0
        }
        
        // Compress video
        print("📹 Compressing video...")
        uploadProgress = 0.1
        let compressedURL = try await compressVideo(url: localURL)
        
        // Read video data
        uploadProgress = 0.3
        guard let videoData = try? Data(contentsOf: compressedURL) else {
            throw VideoError.readFailed
        }
        
        // Get presigned URL from backend
        print("🔑 Getting presigned URL from backend...")
        uploadProgress = 0.4
        let presignedURL = try await getPresignedUploadURL(workoutId: workoutId)
        
        // Upload to R2 using presigned URL (no auth needed!)
        print("☁️ Uploading to R2...")
        uploadProgress = 0.5
        try await uploadWithPresignedURL(data: videoData, presignedURL: presignedURL)
        
        uploadProgress = 1.0
        
        // Cleanup
        try? FileManager.default.removeItem(at: compressedURL)
        
        // Return public URL
        let publicURL = "\(R2Config.publicBucketURL)/\(workoutId).mp4"
        return publicURL
    }
    
    private func uploadWithPresignedURL(data: Data, presignedURL: String) async throws {
        guard let url = URL(string: presignedURL) else {
            throw VideoError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("video/mp4", forHTTPHeaderField: "Content-Type")
        
        // No authentication headers needed - presigned URL handles it!
        let (_, response) = try await URLSession.shared.upload(for: request, from: data)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw VideoError.uploadFailed
        }
    }
    
    // ... (keep compression and thumbnail methods from original)
    
    private func compressVideo(url: URL) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            let asset = AVAsset(url: url)
            
            guard let exportSession = AVAssetExportSession(
                asset: asset,
                presetName: AVAssetExportPresetMediumQuality
            ) else {
                continuation.resume(throwing: VideoError.compressionFailed)
                return
            }
            
            let outputURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mp4")
            
            exportSession.outputURL = outputURL
            exportSession.outputFileType = .mp4
            exportSession.shouldOptimizeForNetworkUse = true
            
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    continuation.resume(returning: outputURL)
                case .failed:
                    continuation.resume(throwing: exportSession.error ?? VideoError.compressionFailed)
                case .cancelled:
                    continuation.resume(throwing: VideoError.compressionCancelled)
                default:
                    continuation.resume(throwing: VideoError.compressionFailed)
                }
            }
        }
    }
}
