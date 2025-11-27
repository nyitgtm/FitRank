import SwiftUI
import AVKit
import FirebaseAuth

// Custom video player layer for TikTok-style feed
struct CustomVideoPlayer: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.backgroundColor = .black
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: PlayerView, context: Context) {
        // Update player if needed
        if uiView.playerLayer.player !== player {
            uiView.playerLayer.player = player
        }
    }
    
    // Custom UIView subclass that properly manages AVPlayerLayer
    class PlayerView: UIView {
        override class var layerClass: AnyClass {
            return AVPlayerLayer.self
        }
        
        var playerLayer: AVPlayerLayer {
            return layer as! AVPlayerLayer
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            // Frame is automatically managed by the layer
        }
    }
}

struct TikTokFeedView: View {
    @StateObject private var voteService = VoteService.shared
    @StateObject private var gymRepository = GymRepository()
    @StateObject private var friendsVM = FriendsListViewModel()
    @State private var workouts: [Workout] = []
    @State private var currentIndex = 0
    @State private var isLoading = true
    
    // Community Guidelines Disclaimer
    @AppStorage("hasSeenCommunityGuidelines") private var hasSeenGuidelines = false
    @State private var showGuidelines = false
    
    // Filters
    @State private var selectedFilter: WorkoutFilterType = .all
    @State private var showFilters = false
    @State private var selectedGymFilter: String?
    @State private var showingGymPicker = false
    
    private let firebaseService = FirebaseService.shared
    
    // Filtered workouts
    private var filteredWorkouts: [Workout] {
        var filtered: [Workout]
        
        switch selectedFilter {
        case .all:
            filtered = workouts
        case .following:
            let friendIds = Set(friendsVM.friends.map { $0.userId })
            filtered = workouts.filter { friendIds.contains($0.userId) }
        case .squat:
            filtered = workouts.filter { $0.liftType == "squat" }
        case .bench:
            filtered = workouts.filter { $0.liftType == "bench" }
        case .deadlift:
            filtered = workouts.filter { $0.liftType == "deadlift" }
        case .gym:
            if let gymId = selectedGymFilter {
                filtered = workouts.filter { $0.gymId == gymId }
            } else {
                filtered = workouts
            }
        }
        
        return filtered
    }
    
    var selectedGymName: String {
        if let gymId = selectedGymFilter,
           let gym = gymRepository.gyms.first(where: { $0.id == gymId }) {
            return gym.name
        }
        return "Gym"
    }
    
    var body: some View {
        ZStack {
            // Main content
            ZStack {
                if isLoading {
                    ProgressView("Loading workouts...")
                } else if filteredWorkouts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "dumbbell")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text(filteredWorkouts.isEmpty && !workouts.isEmpty ? "No workouts match filter" : "No workouts yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text(filteredWorkouts.isEmpty && !workouts.isEmpty ? "Try a different filter" : "Be the first to upload!")
                            .foregroundColor(.secondary)
                    }
                } else {
                    TabView(selection: $currentIndex) {
                        ForEach(Array(filteredWorkouts.enumerated()), id: \.element.id) { index, workout in
                            WorkoutFeedCard(
                                workout: workout,
                                voteService: voteService
                            )
                            .tag(index)
                            .id(workout.id) // Force recreate on workout change
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            
            // Filter bar overlay at top
            VStack {
                if showFilters {
                    WorkoutFilterBar(
                        selectedFilter: $selectedFilter,
                        isCollapsed: .constant(false),
                        selectedGymName: selectedGymName,
                        onGymTap: {
                            showingGymPicker = true
                        }
                    )
                    .padding(.top, 8)
                    .background(Color(.systemBackground).opacity(0.95))
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Spacer()
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button {
                    withAnimation(.spring()) {
                        showFilters.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("Workout Feed")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .rotationEffect(Angle(degrees: showFilters ? 180 : 0))
                    }
                }
            }
        }
        .sheet(isPresented: $showingGymPicker) {
            GymPickerSheet(
                gyms: gymRepository.gyms,
                selectedGym: $selectedGymFilter
            )
        }
        .sheet(isPresented: $showGuidelines) {
            CommunityGuidelinesView {
                hasSeenGuidelines = true
                showGuidelines = false
            }
        }
        .task {
            await loadWorkouts()
            await gymRepository.fetchGyms()
        }
        .onAppear {
            // Show guidelines on first visit
            if !hasSeenGuidelines {
                showGuidelines = true
            }
            friendsVM.loadFriends()
        }
        .onChange(of: currentIndex) { _, newIndex in
            if newIndex < filteredWorkouts.count {
                Task {
                    await loadVoteData(for: filteredWorkouts[newIndex])
                }
            }
        }
        .onChange(of: selectedFilter) { _, _ in
            // Reset to first workout when filter changes
            currentIndex = 0
            // Auto-collapse filters when a filter is selected
            withAnimation(.spring()) {
                showFilters = false
            }
        }
    }
    
    private func loadWorkouts() async {
        isLoading = true
        do {
            // Fetch ALL workouts for now (including pending)
            // TODO: Filter by published only once moderation is set up
            let allWorkouts = try await firebaseService.getAllWorkouts(limit: 50)
            
            // Filter out blocked users
            if let currentUser = try? await UserRepository().getUser(uid: Auth.auth().currentUser?.uid ?? ""),
               let blockedUsers = currentUser.blockedUsers {
                workouts = allWorkouts.filter { !blockedUsers.contains($0.userId) }
            } else {
                workouts = allWorkouts
            }
            
            print("✅ Loaded \(workouts.count) workouts")
            
            // Load vote data for first workout
            if let firstWorkout = workouts.first {
                await loadVoteData(for: firstWorkout)
            }
        } catch {
            print("❌ Error loading workouts: \(error)")
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
    @State private var showComments: Bool = false
    
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var playerReady = false
    @State private var user: User?
    @State private var gym: Gym?
    @State private var isLoadingGym = true
    @State private var commentCount = 0
    @State private var hasIncrementedView = false
    @State private var statusObservation: NSKeyValueObservation?
    @State private var showReportSheet = false
    @State private var reportReason = ""
    @State private var selectedUserId: String?
    
    @StateObject private var userRepository = UserRepository()
    @StateObject private var gymRepository = GymRepository()
    @StateObject private var commentService = CommentService.shared
    @StateObject private var reportService = ReportService.shared
    
    private var voteCounts: (upvotes: Int, downvotes: Int) {
        voteService.voteCounts[workout.id ?? ""] ?? (0, 0)
    }
    
    private var userVote: VoteType? {
        voteService.userVotes[workout.id ?? ""]
    }
    
    private var actionButtons: some View {
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
                Text("\(commentCount)")
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
            
            // Views
            VStack(spacing: 4) {
                Image(systemName: "eye")
                    .font(.title2)
                    .foregroundColor(.white)
                Text("\(formatViewCount(workout.views))")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Black background
                Color.black
                    .ignoresSafeArea()
                
                // Video Player (Custom View)
                if let player = player, playerReady {
                    CustomVideoPlayer(player: player)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                } else {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }
                
                // Tap area for play/pause (only center portion, not sides)
                Color.clear
                    .frame(width: geometry.size.width * 0.6) // Only 60% of width in center
                    .contentShape(Rectangle())
                    .onTapGesture {
                        togglePlayPause()
                    }
                
                // Pause Icon Overlay (show before gradient so it's visible)
                if !isPlaying {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(radius: 10)
                        .transition(.scale.combined(with: .opacity))
                        .allowsHitTesting(false)
                }
                
                // Gradient overlay for better text visibility
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
                
                // Content Overlay
                VStack {
                    Spacer()
                    
                    HStack(alignment: .bottom) {
                        // Left side - Info
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.title2)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(user?.name ?? "Loading...")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                    Text("@\(user?.username ?? "user")")
                                        .font(.subheadline)
                                        .opacity(0.8)
                                }
                            }
                            .foregroundColor(.white)
                            .onTapGesture {
                                selectedUserId = workout.userId
                            }
                            
                            Text("\(workout.weight) lbs • \(workout.liftTypeEnum.displayName)")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                            
                            if workout.gymId != nil {
                                HStack(spacing: 4) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.caption)
                                    if isLoadingGym {
                                        Text("Loading gym...")
                                            .font(.caption)
                                    } else if let gymName = gym?.name {
                                        Text(gymName)
                                            .font(.caption)
                                    } else {
                                        Text("No gym info")
                                            .font(.caption)
                                    }
                                }
                                .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .allowsHitTesting(false)
                        
                        Spacer()
                        
                        // Right side - Actions
                        VStack(spacing: 20) {
                            // Report/Block Menu
                            Menu {
                                Button(role: .destructive) {
                                    showReportSheet = true
                                } label: {
                                    Label("Report Workout", systemImage: "exclamationmark.bubble")
                                }
                                
                                Button(role: .destructive) {
                                    Task {
                                        await blockUser()
                                    }
                                } label: {
                                    Label("Block User", systemImage: "hand.raised.slash")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.black.opacity(0.3))
                                    .clipShape(Circle())
                            }
                            
                            actionButtons
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .sheet(isPresented: $showComments) {
            if let workoutID = workout.id {
                CommentsSheetView(workoutID: workoutID)
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.medium, .large])
                    .onAppear {
                        // Clear any cached comments for this workout and then fetch fresh ones
                        commentService.clearCommentsForWorkout(workoutID)
                        Task {
                            await commentService.fetchComments(workoutID: workoutID)
                        }
                    }
                    .onDisappear {
                        // Refresh comment count when sheet closes
                        Task {
                            await loadCommentCount()
                        }
                    }
            }
        }
        .sheet(isPresented: $showReportSheet) {
            ReportSheet(isPresented: $showReportSheet, reportType: .lift, targetId: workout.id ?? "", parentId: nil, workoutId: nil, parentCommentId: nil)
        }
        .sheet(item: $selectedUserId) { userId in
            PublicProfileView(userId: userId)
        }
        .onAppear {
            print("🎬 Card appeared for workout: \(workout.id ?? "unknown")")
            setupPlayer()
            Task {
                await loadUserAndGym()
                await loadCommentCount()
                await incrementView()
            }
        }
        .onDisappear {
            print("👋 Card disappeared for workout: \(workout.id ?? "unknown")")
            cleanupPlayer()
        }
    }
    
    private func setupPlayer() {
        // Clean up any existing player first
        if player != nil {
            cleanupPlayer()
        }
        
        guard let url = URL(string: workout.videoUrl) else {
            print("❌ Invalid video URL: \(workout.videoUrl)")
            return
        }
        
        print("🎥 Setting up player for URL: \(url)")
        
        // Create player item first to observe its status
        let playerItem = AVPlayerItem(url: url)
        
        // Create new player
        let newPlayer = AVPlayer(playerItem: playerItem)
        newPlayer.actionAtItemEnd = .none
        
        // Set player immediately so the view can render
        self.player = newPlayer
        
        // Observe player item status to know when it's ready
        let statusObserver = playerItem.observe(\.status, options: [.new]) { item, _ in
            DispatchQueue.main.async {
                switch item.status {
                case .readyToPlay:
                    print("✅ Player ready to play")
                    self.playerReady = true
                    newPlayer.play()
                    self.isPlaying = true
                    print("▶️ Player started playing, rate: \(newPlayer.rate)")
                case .failed:
                    print("❌ Player failed: \(item.error?.localizedDescription ?? "unknown error")")
                    self.playerReady = false
                case .unknown:
                    print("⏳ Player status unknown")
                @unknown default:
                    break
                }
            }
        }
        
        // Store observer to prevent deallocation
        self.statusObservation = statusObserver
        
        // Loop video
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            print("🔄 Video ended, looping...")
            newPlayer.seek(to: .zero)
            if self.isPlaying {
                newPlayer.play()
            }
        }
    }
    
    private func cleanupPlayer() {
        print("🧹 Cleaning up player")
        
        // Remove notification observers
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        
        // Cancel status observation
        statusObservation?.invalidate()
        statusObservation = nil
        
        // Stop and clear player
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        playerReady = false
        isPlaying = false
    }
    
    private func togglePlayPause() {
        guard let player = player else { 
            print("⚠️ No player to toggle")
            return 
        }
        
        print("🔄 Toggle called. Current state - isPlaying: \(isPlaying), player.rate: \(player.rate)")
        
        withAnimation(.easeInOut(duration: 0.2)) {
            if isPlaying {
                player.pause()
                isPlaying = false
                print("⏸️ Video paused. New rate: \(player.rate)")
            } else {
                player.play()
                isPlaying = true
                print("▶️ Video playing. New rate: \(player.rate)")
            }
        }
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
    
    private func loadUserAndGym() async {
        // Load user
        do {
            let loadedUser = try await userRepository.getUser(uid: workout.userId)
            await MainActor.run {
                self.user = loadedUser
            }
            print("✅ Loaded user: \(loadedUser?.name ?? "unknown")")
        } catch {
            print("❌ Error loading user: \(error)")
        }
        
        // Load gym if exists
        if let gymId = workout.gymId {
            print("🏋️ Loading gym with ID: \(gymId)")
            
            await MainActor.run {
                self.isLoadingGym = true
            }
            
            // Fetch gyms if not already loaded
            if gymRepository.gyms.isEmpty {
                print("📥 Gyms not loaded yet, fetching...")
                gymRepository.fetchGyms()
                
                // Wait for gyms to load (max 3 seconds)
                for i in 0..<30 {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    if !gymRepository.gyms.isEmpty {
                        print("✅ Gyms loaded after \(Double(i+1) * 0.1) seconds")
                        break
                    }
                }
            }
            
            let foundGym = gymRepository.gyms.first(where: { $0.id == gymId })
            
            await MainActor.run {
                self.gym = foundGym
                self.isLoadingGym = false
                
                if let gymName = foundGym?.name {
                    print("✅ Loaded gym: \(gymName)")
                } else {
                    print("⚠️ Gym not found with ID: \(gymId)")
                    print("⚠️ Total gyms available: \(gymRepository.gyms.count)")
                }
            }
        } else {
            await MainActor.run {
                self.isLoadingGym = false
            }
        }
    }
    
    private func loadCommentCount() async {
        guard let workoutID = workout.id else { return }
        await commentService.fetchComments(workoutID: workoutID)
        await MainActor.run {
            self.commentCount = commentService.commentCounts[workoutID] ?? 0
        }
    }
    
    private func incrementView() async {
        guard let workoutID = workout.id else { return }
        
        // Only increment once per card instance
        guard !hasIncrementedView else {
            print("⏭️ View already incremented for this workout")
            return
        }
        
        await FirebaseService.shared.incrementViewCount(workoutId: workoutID)
        
        await MainActor.run {
            hasIncrementedView = true
        }
    }
    
    private func formatViewCount(_ count: Int) -> String {
        if count < 1000 {
            return "\(count)"
        } else if count < 1_000_000 {
            let thousands = Double(count) / 1000.0
            return String(format: "%.1fK", thousands)
        } else {
            let millions = Double(count) / 1_000_000.0
            return String(format: "%.1fM", millions)
        }
    }
    
    private func blockUser() async {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              let blockedUserId = workout.userId as String? else { return }
        
        do {
            try await userRepository.blockUser(currentUserId: currentUserId, blockedUserId: blockedUserId)
            print("✅ User blocked")
        } catch {
            print("❌ Error blocking user: \(error)")
        }
    }
}
