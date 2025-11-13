import SwiftUI
import FirebaseFirestore

struct GymDetailView: View {
    let gym: Gym
    @StateObject private var viewModel: GymDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedWorkout: Workout?
    @State private var showWorkoutDetail = false
    
    init(gym: Gym) {
        self.gym = gym
        _viewModel = StateObject(wrappedValue: GymDetailViewModel(gym: gym))
    }
    
    var body: some View {
        ZStack {
            if viewModel.isInitialLoading {
                // Loading state
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading gym details...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header Section
                        headerSection
                        
                        Divider()
                        
                        // Location Section
                        locationSection
                        
                        Divider()
                        
                        // Owner Team Section
                        if viewModel.ownerTeam != nil {
                            ownerTeamSection
                            Divider()
                        }
                        
                        // Best Lifts Section
                        bestLiftsSection
                        
                        Spacer()
                    }
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Gym Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .task {
            await viewModel.loadData()
        }
        .sheet(isPresented: $showWorkoutDetail) {
            if let workout = selectedWorkout {
                WorkoutDetailView(workout: workout)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "building.2.fill")
                    .font(.title)
                    .foregroundColor(.blue)
                
                Text(gym.name)
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
    }
    
    // MARK: - Location Section
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Location", systemImage: "mappin.circle.fill")
                .font(.headline)
                .foregroundColor(.blue)
            
            if let address = gym.location.address {
                Text(address)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Lat: \(gym.location.lat, specifier: "%.6f")")
                Spacer()
                Text("Lon: \(gym.location.lon, specifier: "%.6f")")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Owner Team Section
    private var ownerTeamSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Owner Team", systemImage: "person.3.fill")
                .font(.headline)
                .foregroundColor(.blue)
            
            if let team = viewModel.ownerTeam {
                HStack {
                    if let icon = team.icon {
                        Image(systemName: icon)
                            .foregroundColor(Color(hex: team.color) ?? .gray)
                    }
                    
                    Text(team.name)
                        .font(.body)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Circle()
                        .fill(Color(hex: team.color) ?? .gray)
                        .frame(width: 20, height: 20)
                }
                .padding()
                .background(Color(hex: team.color)?.opacity(0.1) ?? Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Best Lifts Section
    private var bestLiftsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Best Lifts", systemImage: "figure.strengthtraining.traditional")
                .font(.headline)
                .foregroundColor(.blue)
            
            if viewModel.isLoadingWorkouts {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Finding best lifts...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    Spacer()
                }
            } else {
                // Best Bench
                liftCard(
                    title: "Bench Press",
                    workout: viewModel.bestBenchWorkout,
                    icon: "figure.strengthtraining.traditional"
                )
                
                // Best Squat
                liftCard(
                    title: "Squat",
                    workout: viewModel.bestSquatWorkout,
                    icon: "figure.walk"
                )
                
                // Best Deadlift
                liftCard(
                    title: "Deadlift",
                    workout: viewModel.bestDeadliftWorkout,
                    icon: "figure.strengthtraining.functional"
                )
            }
        }
    }
    
    // MARK: - Lift Card Component
    private func liftCard(title: String, workout: Workout?, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.orange)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            if let workout = workout {
                Button(action: {
                    selectedWorkout = workout
                    showWorkoutDetail = true
                }) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(workout.weight) lbs")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        if let user = viewModel.users[workout.userId] {
                            Text("by \(user.name)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            HStack(spacing: 4) {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("Loading user...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if let team = viewModel.teams[workout.teamId] {
                            HStack(spacing: 4) {
                                if let icon = team.icon {
                                    Image(systemName: icon)
                                        .font(.caption2)
                                }
                                Text(team.name)
                                    .font(.caption)
                            }
                            .foregroundColor(Color(hex: team.color) ?? .gray)
                        }
                        
                        HStack {
                            Text("Views: \(workout.views)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            // Note: Votes now in subcollection
                            Text("• Votes: —")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            } else {
                Text("No record set")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            }
        }
    }
}

// MARK: - View Model
@MainActor
class GymDetailViewModel: ObservableObject {
    @Published var ownerTeam: Team?
    @Published var bestBenchWorkout: Workout?
    @Published var bestSquatWorkout: Workout?
    @Published var bestDeadliftWorkout: Workout?
    @Published var users: [String: User] = [:]
    @Published var teams: [String: Team] = [:]
    
    @Published var isInitialLoading = true
    @Published var isLoadingWorkouts = false
    
    private let gym: Gym
    private let db = Firestore.firestore()
    private let firebaseService = FirebaseService.shared
    
    init(gym: Gym) {
        self.gym = gym
    }
    
    func loadData() async {
        // Load basic info first (fast)
        if let ownerTeamId = gym.ownerTeamId, ownerTeamId != "teams/0" {
            await loadOwnerTeam(teamId: ownerTeamId)
        }
        
        // Show content immediately
        isInitialLoading = false
        
        // Then load workouts in background
        await loadBestLifts()
    }
    
    private func loadOwnerTeam(teamId: String) async {
        do {
            // Extract team ID from path if needed
            let cleanTeamId = teamId.components(separatedBy: "/").last ?? teamId
            
            let document = try await db.collection("teams").document(cleanTeamId).getDocument()
            if let team = try? document.data(as: Team.self) {
                self.ownerTeam = team
            }
        } catch {
            print("Error loading owner team: \(error)")
        }
    }
    
    private func loadBestLifts() async {
        guard let gymId = gym.id else { 
            isLoadingWorkouts = false
            return 
        }
        
        isLoadingWorkouts = true
        
        do {
            // Query only published workouts for this gym - optimized query
            let snapshot = try await db.collection("workouts")
                .whereField("gymId", isEqualTo: gymId)
                .whereField("status", isEqualTo: "published")
                .limit(to: 100) // Limit results for performance
                .getDocuments()
            
            let workouts = try snapshot.documents.compactMap { try $0.data(as: Workout.self) }
            
            // Find best lifts by weight for each type
            let benchWorkouts = workouts.filter { $0.liftType == "bench" }
            let squatWorkouts = workouts.filter { $0.liftType == "squat" }
            let deadliftWorkouts = workouts.filter { $0.liftType == "deadlift" }
            
            bestBenchWorkout = benchWorkouts.max(by: { $0.weight < $1.weight })
            bestSquatWorkout = squatWorkouts.max(by: { $0.weight < $1.weight })
            bestDeadliftWorkout = deadliftWorkouts.max(by: { $0.weight < $1.weight })
            
            isLoadingWorkouts = false
            
            // Load related data in background (non-blocking)
            let allBestWorkouts = [bestBenchWorkout, bestSquatWorkout, bestDeadliftWorkout].compactMap { $0 }
            
            await withTaskGroup(of: Void.self) { group in
                for workout in allBestWorkouts {
                    group.addTask { await self.loadUserAndTeam(for: workout) }
                }
            }
            
        } catch {
            print("Error loading best lifts: \(error)")
            isLoadingWorkouts = false
        }
    }
    
    private func loadUserAndTeam(for workout: Workout) async {
        // Load user if not already loaded
        if users[workout.userId] == nil {
            do {
                let user = try await firebaseService.getUser(userId: workout.userId)
                users[workout.userId] = user
            } catch {
                print("Error loading user \(workout.userId): \(error)")
            }
        }
        
        // Load team if not already loaded
        if teams[workout.teamId] == nil {
            do {
                let cleanTeamId = workout.teamId.components(separatedBy: "/").last ?? workout.teamId
                let document = try await db.collection("teams").document(cleanTeamId).getDocument()
                if let team = try? document.data(as: Team.self) {
                    teams[workout.teamId] = team
                }
            } catch {
                print("Error loading team \(workout.teamId): \(error)")
            }
        }
    }
}

#Preview {
    let testGym = Gym(
        name: "Test Gym",
        location: Location(address: "123 Test St", lat: 40.7589, lon: -73.9851),
        bestSquat: nil,
        bestBench: nil,
        bestDeadlift: nil,
        ownerTeamId: "teams/1"
    )
    GymDetailView(gym: testGym)
}
