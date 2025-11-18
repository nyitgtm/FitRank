//
//  VideoPicker.swift
//  FitRank
//
//  Native iOS video picker with duration validation
//

import SwiftUI
import PhotosUI
import AVFoundation

struct VideoPicker: UIViewControllerRepresentable {
    @Binding var videoURL: URL?
    @Binding var showError: Bool
    @Binding var errorMessage: String
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .videos
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: VideoPicker
        
        init(_ parent: VideoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let result = results.first else { return }
            
            result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.parent.errorMessage = "Failed to load video: \(error.localizedDescription)"
                        self.parent.showError = true
                    }
                    return
                }
                
                guard let url = url else {
                    DispatchQueue.main.async {
                        self.parent.errorMessage = "Invalid video file"
                        self.parent.showError = true
                    }
                    return
                }
                
                // Copy to temporary location
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension("mov")
                
                do {
                    if FileManager.default.fileExists(atPath: tempURL.path) {
                        try FileManager.default.removeItem(at: tempURL)
                    }
                    try FileManager.default.copyItem(at: url, to: tempURL)
                    
                    // Validate duration
                    Task {
                        await self.validateAndSetVideo(url: tempURL)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.parent.errorMessage = "Failed to process video: \(error.localizedDescription)"
                        self.parent.showError = true
                    }
                }
            }
        }
        
        @MainActor
        private func validateAndSetVideo(url: URL) async {
            let asset = AVAsset(url: url)
            
            do {
                let duration = try await asset.load(.duration)
                let seconds = CMTimeGetSeconds(duration)
                
                if seconds > R2Config.maxVideoDurationSeconds {
                    self.parent.errorMessage = "Video must be 30 seconds or less (yours is \(Int(seconds))s)"
                    self.parent.showError = true
                    try? FileManager.default.removeItem(at: url)
                } else {
                    self.parent.videoURL = url
                    
                    // Try to extract location from video metadata
                    await self.extractLocationFromVideo(url: url)
                }
            } catch {
                self.parent.errorMessage = "Failed to validate video: \(error.localizedDescription)"
                self.parent.showError = true
                try? FileManager.default.removeItem(at: url)
            }
        }
        
        @MainActor
        private func extractLocationFromVideo(url: URL) async {
            let asset = AVAsset(url: url)
            
            do {
                // Get metadata from video
                let metadata = try await asset.load(.metadata)
                
                for item in metadata {
                    // Look for location metadata
                    if let keyString = item.commonKey?.rawValue,
                       keyString.contains("location") || keyString.contains("GPS") {
                        
                        if let locationData = try? await item.load(.value) as? String {
                            // Parse location string (format varies)
                            print("Found location metadata: \(locationData)")
                        }
                    }
                    
                    // iOS specific location key
                    if item.identifier?.rawValue.contains("location") == true,
                       let locationString = try? await item.load(.stringValue) {
                        print("Found iOS location: \(locationString)")
                        // Parse ISO 6709 format location string
                        if let location = self.parseISO6709Location(locationString) {
                            NotificationCenter.default.post(
                                name: NSNotification.Name("VideoLocationFound"),
                                object: location
                            )
                        }
                    }
                }
                
                // Also check common metadata
                let commonMetadata = try await asset.load(.commonMetadata)
                for item in commonMetadata {
                    if item.commonKey == .commonKeyLocation,
                       let locationString = try? await item.load(.stringValue) {
                        print("Found common location: \(locationString)")
                        if let location = self.parseISO6709Location(locationString) {
                            NotificationCenter.default.post(
                                name: NSNotification.Name("VideoLocationFound"),
                                object: location
                            )
                        }
                    }
                }
            } catch {
                print("Could not extract location from video: \(error)")
            }
        }
        
        private func parseISO6709Location(_ locationString: String) -> CLLocation? {
            // ISO 6709 format: +40.7484-073.9857/ or similar
            // Remove any trailing slashes
            let cleaned = locationString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            
            // Simple regex to extract lat/lon
            let pattern = "([+-]?\\d+\\.\\d+)([+-]\\d+\\.\\d+)"
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned)) else {
                return nil
            }
            
            guard match.numberOfRanges >= 3,
                  let latRange = Range(match.range(at: 1), in: cleaned),
                  let lonRange = Range(match.range(at: 2), in: cleaned),
                  let latitude = Double(cleaned[latRange]),
                  let longitude = Double(cleaned[lonRange]) else {
                return nil
            }
            
            return CLLocation(latitude: latitude, longitude: longitude)
        }
    }
}
