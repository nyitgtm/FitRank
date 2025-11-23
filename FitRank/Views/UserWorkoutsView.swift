import SwiftUI

struct UserWorkoutsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var workoutViewModel: WorkoutViewModel
    let userId: String
    let userName: String
    let userUsername: String
    
    @State private var showingDeleteAlert = false
    @State private var workoutToDelete: Workout?
    @State private var selectedWorkout: Workout?
    @StateObject private var gymRepository = GymRepository()
    
    // Filters
    @State private var selectedFilter: WorkoutFilterType = .all
    @State private var showFilters = false
    @State private var isCollapsed = false
    @State private var lastScrollOffset: CGFloat = 0
    
    // Gym Filter
    @State private var selectedGymFilter: String?
    @State private var showingGymPicker = false
    
    // Computed personal records
    private var bestSquat: Int? {
        workouts(for: "squat").max(by: { $0.weight < $1.weight })?.weight
    }
    
    private var bestBench: Int? {
        workouts(for: "bench").max(by: { $0.weight < $1.weight })?.weight
    }
    
    private var bestDeadlift: Int? {
        workouts(for: "deadlift").max(by: { $0.weight < $1.weight })?.weight
    }
    
    // Stats
    private var totalWorkouts: Int {
        workoutViewModel.userWorkouts.count
    }
    
    private var totalWeight: Int {
        workoutViewModel.userWorkouts.reduce(0) { $0 + $1.weight }
    }
    
    // Note: Upvotes now tracked in subcollection, would need to fetch separately
    private var totalUpvotes: Int {
        0 // TODO: Fetch from votes subcollection
    }
    
    private var favoriteLift: String {
        let liftCounts = Dictionary(grouping: workoutViewModel.userWorkouts, by: { $0.liftType })
        let mostFrequent = liftCounts.max { $0.value.count < $1.value.count }
        if let liftTypeString = mostFrequent?.key,
           let liftType = LiftType(rawValue: liftTypeString) {
            return liftType.displayName
        }
        return "N/A"
    }
    
    private var favoriteGym: (name: String, address: String?) {        let gymCounts = Dictionary(grouping: workoutViewModel.userWorkouts.compactMap { $0.gymId }, by: { $0 })
        let mostFrequentId = gymCounts.max { $0.value.count < $1.value.count }?.key
        
        if let gymId = mostFrequentId,
           let gym = gymRepository.gyms.first(where: { $0.id == gymId }) {
            return (name: gym.name, address: gym.location.address)
        }
        return (name: "N/A", address: nil)
    }
    
    private func workouts(for liftType: String) -> [Workout] {
        workoutViewModel.userWorkouts.filter { $0.liftType == liftType }
    }
    
    private var filteredWorkouts: [Workout] {
        switch selectedFilter {
        case .all, .following:
            // Following filter doesn't apply in user-specific workout view
            return workoutViewModel.userWorkouts
        case .squat:
            return workouts(for: "squat")
        case .bench:
            return workouts(for: "bench")
        case .deadlift:
            return workouts(for: "deadlift")
        case .gym:
            if let gymId = selectedGymFilter {
                return workoutViewModel.userWorkouts.filter { $0.gymId == gymId }
            }
            return workoutViewModel.userWorkouts
        }
    }
    
    var selectedGymName: String {
        if let gymId = selectedGymFilter,
           let gym = gymRepository.gyms.first(where: { $0.id == gymId }) {
            return gym.name
        }
        return "Gym"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if workoutViewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading workouts...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                } else if workoutViewModel.userWorkouts.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "dumbbell")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary)
                        
                        Text("No Workouts Yet")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Start uploading workouts to see them here!")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        // Scroll Reader
                        GeometryReader { geo in
                            Color.clear
                                .preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .global).minY)
                        }
                        .frame(height: 0)
                        
                        VStack(spacing: 16) {
                            // Filter Bar (Collapsible)
                            if showFilters {
                                WorkoutFilterBar(
                                    selectedFilter: $selectedFilter,
                                    isCollapsed: $isCollapsed,
                                    selectedGymName: selectedGymName,
                                    onGymTap: {
                                        showingGymPicker = true
                                    }
                                )
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                            
                            // Personal Records (S, B, D)
                            PersonalRecordsCard(
                                squat: bestSquat,
                                bench: bestBench,
                                deadlift: bestDeadlift
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            
                            // Overall Stats
                            OverallStatsCard(
                                totalWorkouts: totalWorkouts,
                                totalWeight: totalWeight,
                                totalUpvotes: totalUpvotes,
                                favoriteLift: favoriteLift,
                                favoriteGym: favoriteGym
                            )
                            .padding(.horizontal, 20)
                            
                            // Workout cards with delete
                            ForEach(filteredWorkouts) { workout in
                                WorkoutCardWithDelete(
                                    workout: workout,
                                    onTap: {
                                        selectedWorkout = workout
                                    },
                                    onDelete: {
                                        workoutToDelete = workout
                                        showingDeleteAlert = true
                                    }
                                )
                                .padding(.horizontal, 20)
                            }
                            
                            // Bottom padding
                            Color.clear.frame(height: 20)
                        }
                        .padding(.vertical, 16)
                    }
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        if value < lastScrollOffset - 10 {
                            withAnimation(.spring()) { isCollapsed = true }
                        } else if value > lastScrollOffset + 10 {
                            withAnimation(.spring()) { isCollapsed = false }
                        }
                        lastScrollOffset = value
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button {
                        withAnimation(.spring()) {
                            showFilters.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("My Workouts")
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
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingGymPicker) {
            GymPickerSheet(
                gyms: gymRepository.gyms,
                selectedGym: $selectedGymFilter
            )
        }
        .sheet(item: $selectedWorkout) { workout in
            WorkoutDetailView(workout: workout)
        }
        .alert("Delete Workout?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                workoutToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let workout = workoutToDelete {
                    deleteWorkout(workout)
                }
            }
        } message: {
            Text("This will permanently delete this workout. This action cannot be undone.")
        }
        .onAppear {
            Task {
                await gymRepository.fetchGyms()
                await workoutViewModel.fetchAllUserWorkouts(userId: userId)
            }
        }
    }
    
    private func deleteWorkout(_ workout: Workout) {
        Task {
            await workoutViewModel.deleteWorkout(workout)
            workoutToDelete = nil
        }
    }
}

// MARK: - Personal Records Card
struct PersonalRecordsCard: View {
    let squat: Int?
    let bench: Int?
    let deadlift: Int?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                    .font(.title3)
                
                Text("Personal Records")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                PRBox(
                    letter: "S",
                    weight: squat,
                    color: .green,
                    title: "Squat"
                )
                
                PRBox(
                    letter: "B",
                    weight: bench,
                    color: .blue,
                    title: "Bench"
                )
                
                PRBox(
                    letter: "D",
                    weight: deadlift,
                    color: .red,
                    title: "Deadlift"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct PRBox: View {
    let letter: String
    let weight: Int?
    let color: Color
    let title: String
    
    var body: some View {
        VStack(spacing: 8) {
            // Letter badge
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 50, height: 50)
                
                Text(letter)
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(.white)
            }
            
            // Weight
            if let weight = weight {
                Text("\(weight)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("lbs")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("—")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                Text("No PR")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Overall Stats Card
struct OverallStatsCard: View {
    let totalWorkouts: Int
    let totalWeight: Int
    let totalUpvotes: Int
    let favoriteLift: String
    let favoriteGym: (name: String, address: String?)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                Text("Overall Stats")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            // Two rows of stats
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    StatMiniBox(
                        title: "Workouts",
                        value: "\(totalWorkouts)",
                        icon: "number.circle.fill",
                        color: .blue
                    )
                    
                    StatMiniBox(
                        title: "Total Weight",
                        value: "\(totalWeight) lbs",
                        icon: "scalemass.fill",
                        color: .orange
                    )
                }
                
                HStack(spacing: 12) {
                    StatMiniBox(
                        title: "Upvotes",
                        value: "\(totalUpvotes)",
                        icon: "hand.thumbsup.fill",
                        color: .green
                    )
                    
                    StatMiniBox(
                        title: "Favorite Lift",
                        value: favoriteLift,
                        icon: "star.fill",
                        color: .purple
                    )
                }
                
                // Favorite gym (full width)
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.red)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Favorite Gym")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(favoriteGym.name)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .lineLimit(1)
                        
                        if let address = favoriteGym.address {
                            Text(address)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct StatMiniBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(title)
                    .font(.caption2)
            }
            .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Workout Card with Delete
struct WorkoutCardWithDelete: View {
    let workout: Workout
    let onTap: () -> Void
    let onDelete: () -> Void
    @ObservedObject private var voteService = VoteService.shared
    @State private var upvotes: Int = 0
    @State private var downvotes: Int = 0
    @State private var userVote: VoteType? = nil
    @State private var isProcessingVote: Bool = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with lift type and delete button
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.liftTypeEnum.displayName)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("\(workout.weight) lbs")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    // Delete button
                    Button(action: onDelete) {
                        Image(systemName: "trash.fill")
                            .font(.title3)
                            .foregroundColor(.red)
                            .padding(8)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                Divider()
                
                // Stats
                HStack(spacing: 20) {
                    WorkoutStatItem(icon: "eye.fill", value: "\(workout.views)", color: .secondary)
                    WorkoutStatItem(icon: userVote == .upvote ? "hand.thumbsup.fill" : "hand.thumbsup", value: "\(upvotes)", color: .green)
                    WorkoutStatItem(icon: userVote == .downvote ? "hand.thumbsdown.fill" : "hand.thumbsdown", value: "\(downvotes)", color: .red)
                }
                
                // Date and status
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(workout.createdAt, style: .relative)
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(workout.statusEnum.displayName)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor(workout.statusEnum))
                        .cornerRadius(8)
                }
                
                // Tap to view details hint
                HStack {
                    Spacer()
                    Text("Tap for details")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .task {
            if let id = workout.id {
                await voteService.fetchVoteCounts(workoutId: id)
                if let currentUser = try? AuthenticationManager.shared.getAuthenticatedUser() {
                    await voteService.fetchUserVote(workoutId: id, userId: currentUser.uid)
                }
                if let counts = voteService.voteCounts[id] {
                    upvotes = counts.upvotes
                    downvotes = counts.downvotes
                }
                userVote = voteService.userVotes[id]
            }
        }
        .onReceive(voteService.$voteCounts) { _ in
            if let id = workout.id, let counts = voteService.voteCounts[id] {
                upvotes = counts.upvotes
                downvotes = counts.downvotes
            }
        }
        .onReceive(voteService.$userVotes) { _ in
            if let id = workout.id {
                userVote = voteService.userVotes[id]
            }
        }
    }
    
    private func statusColor(_ status: WorkoutStatus) -> Color {
        switch status {
        case .published: return .green
        case .pending: return .orange
        case .removed: return .red
        }
    }
}

struct WorkoutStatItem: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
    }
}

#Preview {
    UserWorkoutsView(
        workoutViewModel: WorkoutViewModel(),
        userId: "user1",
        userName: "John Doe",
        userUsername: "johndoe"
    )
}

// MARK: - Workout Filters
enum WorkoutFilterType: String, CaseIterable, Identifiable {
    case all = "All"
    case following = "Following"
    case squat = "Squat"
    case bench = "Bench"
    case deadlift = "Deadlift"
    case gym = "Gym"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .all: return "dumbbell.fill"
        case .following: return "person.2.fill"
        case .squat: return "figure.strengthtraining.traditional"
        case .bench: return "figure.strengthtraining.functional"
        case .deadlift: return "figure.core.training"
        case .gym: return "mappin.circle.fill"
        }
    }
}

struct WorkoutFilterBar: View {
    @Binding var selectedFilter: WorkoutFilterType
    @Binding var isCollapsed: Bool
    var selectedGymName: String = "Gym"
    var onGymTap: (() -> Void)?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(WorkoutFilterType.allCases) { filter in
                    Button {
                        if filter == .gym {
                            selectedFilter = filter
                            onGymTap?()
                        } else {
                            withAnimation(.spring()) {
                                selectedFilter = filter
                            }
                        }
                    } label: {
                        HStack(spacing: isCollapsed ? 0 : 6) {
                            Image(systemName: filter.icon)
                                .font(isCollapsed ? .footnote : .caption)
                            
                            if !isCollapsed {
                                Text(filter == .gym ? selectedGymName : filter.rawValue)
                                    .font(.caption)
                                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                            }
                        }
                        .fontWeight(selectedFilter == filter ? .semibold : .medium)
                        .padding(.vertical, 8)
                        .padding(.horizontal, isCollapsed ? 12 : 16)
                        .background(
                            Capsule()
                                .fill(selectedFilter == filter ? Color.blue : Color(.secondarySystemBackground))
                        )
                        .foregroundColor(selectedFilter == filter ? .white : .primary)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
