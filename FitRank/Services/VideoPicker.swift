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
                }
            } catch {
                self.parent.errorMessage = "Failed to validate video: \(error.localizedDescription)"
                self.parent.showError = true
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
}
