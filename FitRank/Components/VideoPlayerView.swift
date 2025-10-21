//
//  VideoPlayerView.swift
//  FitRank
//
//  Video player component for displaying workout videos from R2
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let videoURL: String
    @State private var player: AVPlayer?
    @State private var isLoading = true
    @State private var showError = false
    
    var body: some View {
        ZStack {
            if isLoading {
                // Loading state
                Rectangle()
                    .fill(Color(.systemGray6))
                    .overlay(
                        ProgressView()
                            .scaleEffect(1.5)
                    )
            } else if showError {
                // Error state
                Rectangle()
                    .fill(Color(.systemGray6))
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            
                            Text("Failed to load video")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    )
            } else if let player = player {
                // Video player
                VideoPlayer(player: player)
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }
            }
        }
        .onAppear {
            loadVideo()
        }
    }
    
    private func loadVideo() {
        guard let url = URL(string: videoURL) else {
            showError = true
            isLoading = false
            return
        }
        
        // Create player with URL
        let player = AVPlayer(url: url)
        
        // Set to loop
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }
        
        self.player = player
        isLoading = false
    }
}

/// Lightweight video player for feed/list views
struct CompactVideoPlayer: View {
    let videoURL: String
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    
    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .disabled(true) // Disable controls for compact view
            } else {
                Rectangle()
                    .fill(Color(.systemGray6))
                    .overlay(
                        ProgressView()
                    )
            }
            
            // Play/Pause overlay
            if !isPlaying {
                Circle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "play.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    )
            }
        }
        .onTapGesture {
            togglePlayback()
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
        }
    }
    
    private func setupPlayer() {
        guard let url = URL(string: videoURL) else { return }
        
        let player = AVPlayer(url: url)
        player.isMuted = true // Muted by default in feed
        
        // Auto-loop
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            if isPlaying {
                player.play()
            }
        }
        
        self.player = player
    }
    
    private func togglePlayback() {
        guard let player = player else { return }
        
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }
}

#Preview {
    VStack {
        VideoPlayerView(videoURL: "https://pub-4f8e728946614c7887df487ba187d3ad.r2.dev/test.mp4")
            .frame(height: 400)
        
        CompactVideoPlayer(videoURL: "https://pub-4f8e728946614c7887df487ba187d3ad.r2.dev/test.mp4")
            .frame(height: 300)
    }
}
