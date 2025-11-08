import SwiftUI
import AVKit
import FirebaseAuth

struct TikTokFeedView: View {
    @StateObject private var voteService = VoteService.shared
    @State private var workouts: [Workout] = []
    @State private var currentIndex = 0
    @State private var isLoading = true
    @State private var showComments = false
    
    private let firebaseService = FirebaseService.shared
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView("Loading workouts...")
            } else if workouts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "dumbbell")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No workouts yet")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Be the first to upload!")
                        .foregroundColor(.secondary)
                }
            } else {
                TabView(selection: $currentIndex) {
                    ForEach(Array(workouts.enumerated()), id: \.element.id) { index, workout in
                        WorkoutFeedCard(
                            workout: workout,
                            voteService: voteService,
                            showComments: $showComments
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
            }
        }
        .task {
            await loadWorkouts()
        }
        .onChange(of: currentIndex) { _, newIndex in
            if newIndex < workouts.count {
                Task {
                    await loadVoteData(for: workouts[newIndex])
                }
            }
        }
    }
    
    private func loadWorkouts() async {
        isLoading = true
        do {
            // Fetch published workouts ordered by creation date
            workouts = try await firebaseService.getPublishedWorkouts(limit: 20)
            
            // Load vote data for first workout
            if let firstWorkout = workouts.first {
                await loadVoteData(for: firstWorkout)
            }
        } catch {
            print("Error loading workouts: \(error)")
        }
        isLoading = false
    }
    
    private func loadVoteData(for workout: Workout) async {
        guard let workoutId = workout.id,
              let userId = Auth.auth().currentUser?.uid else { return }
        
        await voteService.fetchVoteCounts(workoutId: workoutId)
        await voteService.fetchUserVote(workoutId: workoutId, userId: userId)
    }
}

struct WorkoutFeedCard: View {
    let workout: Workout
    @ObservedObject var voteService: VoteService
    @Binding var showComments: Bool
    
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    
    private var voteCounts: (upvotes: Int, downvotes: Int) {
        voteService.voteCounts[workout.id ?? ""] ?? (0, 0)
    }
    
    private var userVote: VoteType? {
        voteService.userVotes[workout.id ?? ""]
    }
    
    var body: some View {
        ZStack {
            // Video Player
            if let url = URL(string: workout.videoUrl) {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onTapGesture {
                        togglePlayPause()
                    }
            }
            
            // Gradient overlay for better text visibility
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .center,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Content Overlay
            VStack {
                Spacer()
                
                HStack(alignment: .bottom) {
                    // Left side - Info
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                            Text("User") // TODO: Fetch username
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        
                        Text("\(workout.weight) lbs • \(workout.liftTypeEnum.displayName)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                        
                        if let gymId = workout.gymId {
                            Text("📍 Gym: \(gymId)") // TODO: Fetch gym name
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    Spacer()
                    
                    // Right side - Actions
                    VStack(spacing: 24) {
                        // Upvote
                        VStack(spacing: 4) {
                            Button {
                                Task {
                                    await handleVote(.upvote)
                                }
                            } label: {
                                Image(systemName: userVote == .upvote ? "hand.thumbsup.fill" : "hand.thumbsup")
                                    .font(.title2)
                                    .foregroundColor(userVote == .upvote ? .green : .white)
                            }
                            Text("\(voteCounts.upvotes)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        
                        // Downvote
                        VStack(spacing: 4) {
                            Button {
                                Task {
                                    await handleVote(.downvote)
                                }
                            } label: {
                                Image(systemName: userVote == .downvote ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                                    .font(.title2)
                                    .foregroundColor(userVote == .downvote ? .red : .white)
                            }
                            Text("\(voteCounts.downvotes)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        
                        // Comments
                        VStack(spacing: 4) {
                            Button {
                                showComments = true
                            } label: {
                                Image(systemName: "text.bubble")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            Text("0") // TODO: Fetch comment count
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        
                        // Share
                        VStack(spacing: 4) {
                            Button {
                                // TODO: Share functionality
                            } label: {
                                Image(systemName: "arrowshape.turn.up.right")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
        }
    }
    
    private func setupPlayer() {
        guard let url = URL(string: workout.videoUrl) else { return }
        player = AVPlayer(url: url)
        player?.play()
        isPlaying = true
        
        // Loop video
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { _ in
            player?.seek(to: .zero)
            player?.play()
        }
    }
    
    private func togglePlayPause() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isPlaying.toggle()
    }
    
    private func handleVote(_ voteType: VoteType) async {
        guard let workoutId = workout.id,
              let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            try await voteService.toggleVote(
                workoutId: workoutId,
                userId: userId,
                voteType: voteType
            )
        } catch {
            print("Error voting: \(error)")
        }
    }
}
