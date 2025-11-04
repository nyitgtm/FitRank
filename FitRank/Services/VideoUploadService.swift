//
//  VideoUploadService.swift
//  FitRank
//
//  Production-ready video upload service for Cloudflare R2
//

import Foundation
import AVFoundation
import UIKit
import CryptoKit

enum VideoError: LocalizedError {
    case compressionFailed
    case compressionCancelled
    case invalidURL
    case uploadFailed
    case videoDurationExceeded
    case fileSizeTooLarge
    case readFailed
    case invalidVideoFormat
    
    var errorDescription: String? {
        switch self {
        case .compressionFailed: return "Failed to compress video"
        case .compressionCancelled: return "Video compression was cancelled"
        case .invalidURL: return "Invalid upload URL"
        case .uploadFailed: return "Failed to upload video to server"
        case .videoDurationExceeded: return "Video must be 30 seconds or less"
        case .fileSizeTooLarge: return "Video file is too large"
        case .readFailed: return "Failed to read video file"
        case .invalidVideoFormat: return "Invalid video format"
        }
    }
}

@MainActor
class VideoUploadService: ObservableObject {
    
    @Published var uploadProgress: Double = 0.0
    @Published var isUploading: Bool = false
    
    // MARK: - Validation
    
    /// Validate video duration (max 30 seconds)
    func validateVideoDuration(url: URL) async throws {
        let asset = AVAsset(url: url)
        let duration = try await asset.load(.duration)
        let seconds = CMTimeGetSeconds(duration)
        
        if seconds > R2Config.maxVideoDurationSeconds {
            throw VideoError.videoDurationExceeded
        }
    }
    
    /// Get video duration in seconds
    func getVideoDuration(url: URL) async throws -> Double {
        let asset = AVAsset(url: url)
        let duration = try await asset.load(.duration)
        return CMTimeGetSeconds(duration)
    }
    
    // MARK: - Video Compression
    
    /// Compress video to optimize for mobile streaming
    func compressVideo(url: URL) async throws -> URL {
        // First validate duration
        try await validateVideoDuration(url: url)
        
        return try await withCheckedThrowingContinuation { continuation in
            let asset = AVAsset(url: url)
            
            // Use medium quality for good balance between size and quality
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
            
            // Optional: Set video composition for additional compression
            exportSession.videoComposition = nil
            
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
    
    /// Generate thumbnail from video first frame
    func generateThumbnail(from url: URL, at time: CMTime = .zero) async -> UIImage? {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 400, height: 400) // Limit thumbnail size
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            print("❌ Error generating thumbnail: \(error)")
            return nil
        }
    }
    
    // MARK: - R2 Upload
    
    /// Main upload function - compresses and uploads video to R2
    func uploadVideo(localURL: URL, workoutId: String) async throws -> String {
        isUploading = true
        uploadProgress = 0.0
        
        defer {
            isUploading = false
            uploadProgress = 0.0
        }
        
        do {
            // 1. Validate and compress video
            print("📹 Validating and compressing video...")
            uploadProgress = 0.1
            let compressedURL = try await compressVideo(url: localURL)
            
            // 2. Read video data
            uploadProgress = 0.3
            guard let videoData = try? Data(contentsOf: compressedURL) else {
                throw VideoError.readFailed
            }
            
            let fileSizeMB = Double(videoData.count) / 1_000_000
            print("📦 Compressed video size: \(String(format: "%.2f", fileSizeMB)) MB")
            
            // 3. Upload to R2
            uploadProgress = 0.5
            let fileName = "\(workoutId).mp4"
            let publicURL = try await uploadToR2(data: videoData, fileName: fileName)
            
            uploadProgress = 1.0
            print("✅ Upload complete: \(publicURL)")
            
            // Cleanup temp file
            try? FileManager.default.removeItem(at: compressedURL)
            
            return publicURL
            
        } catch {
            print("❌ Upload failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Upload data to R2 using S3-compatible API
    private func uploadToR2(data: Data, fileName: String) async throws -> String {
        let urlString = "\(R2Config.endpoint)/\(R2Config.bucketName)/\(fileName)"
        
        guard let url = URL(string: urlString) else {
            throw VideoError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("video/mp4", forHTTPHeaderField: "Content-Type")
        request.setValue(String(data.count), forHTTPHeaderField: "Content-Length")
        
        // Add AWS Signature V4 headers
        let signedRequest = signRequestAWSV4(request, data: data, fileName: fileName)
        
        // Perform upload
        let (_, response) = try await URLSession.shared.upload(for: signedRequest, from: data)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw VideoError.uploadFailed
        }
        
        print("📡 R2 Response Status: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            print("❌ R2 Error Response: \(httpResponse)")
            throw VideoError.uploadFailed
        }
        
        // Return public URL
        return "\(R2Config.publicBucketURL)/\(fileName)"
    }
    
    // MARK: - AWS Signature V4
    
    private func signRequestAWSV4(_ request: URLRequest, data: Data, fileName: String) -> URLRequest {
        var signedRequest = request
        
        // Date formatting
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        let timestamp = dateFormatter.string(from: Date())
        
        let dateStamp = String(timestamp.prefix(8))
        
        // Calculate payload hash
        let payloadHash = SHA256.hash(data: data)
        let payloadHashString = payloadHash.compactMap { String(format: "%02x", $0) }.joined()
        
        // Add headers
        signedRequest.setValue(timestamp, forHTTPHeaderField: "x-amz-date")
        signedRequest.setValue(payloadHashString, forHTTPHeaderField: "x-amz-content-sha256")
        
        // Create canonical request
        let canonicalURI = "/\(R2Config.bucketName)/\(fileName)"
        let canonicalHeaders = "host:\(R2Config.accountId).r2.cloudflarestorage.com\nx-amz-content-sha256:\(payloadHashString)\nx-amz-date:\(timestamp)\n"
        let signedHeaders = "host;x-amz-content-sha256;x-amz-date"
        
        let canonicalRequest = "PUT\n\(canonicalURI)\n\n\(canonicalHeaders)\n\(signedHeaders)\n\(payloadHashString)"
        
        let canonicalRequestHash = SHA256.hash(data: Data(canonicalRequest.utf8))
        let canonicalRequestHashString = canonicalRequestHash.compactMap { String(format: "%02x", $0) }.joined()
        
        // Create string to sign
        let credentialScope = "\(dateStamp)/auto/s3/aws4_request"
        let stringToSign = "AWS4-HMAC-SHA256\n\(timestamp)\n\(credentialScope)\n\(canonicalRequestHashString)"
        
        // Calculate signature
        let signature = calculateSignature(stringToSign: stringToSign, dateStamp: dateStamp)
        
        // Create authorization header
        let authorizationHeader = "AWS4-HMAC-SHA256 Credential=\(R2Config.accessKeyId)/\(credentialScope), SignedHeaders=\(signedHeaders), Signature=\(signature)"
        
        signedRequest.setValue(authorizationHeader, forHTTPHeaderField: "Authorization")
        
        return signedRequest
    }
    
    private func calculateSignature(stringToSign: String, dateStamp: String) -> String {
        let kDate = hmac(key: "AWS4\(R2Config.secretAccessKey)".data(using: .utf8)!, data: dateStamp.data(using: .utf8)!)
        let kRegion = hmac(key: kDate, data: "auto".data(using: .utf8)!)
        let kService = hmac(key: kRegion, data: "s3".data(using: .utf8)!)
        let kSigning = hmac(key: kService, data: "aws4_request".data(using: .utf8)!)
        let signature = hmac(key: kSigning, data: stringToSign.data(using: .utf8)!)
        
        return signature.map { String(format: "%02x", $0) }.joined()
    }
    
    private func hmac(key: Data, data: Data) -> Data {
        let hmac = HMAC<SHA256>.authenticationCode(for: data, using: SymmetricKey(data: key))
        return Data(hmac)
    }
}
