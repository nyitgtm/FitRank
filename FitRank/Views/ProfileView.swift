import SwiftUI

struct ProfileView: View {
    @StateObject private var userViewModel = UserViewModel()
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @State private var showingEditProfile = false
    @State private var showingTeamSelection = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    ProfileHeaderView(user: userViewModel.currentUser)
                    
                    // Stats Section
                    StatsSectionView(workoutCount: workoutViewModel.workouts.count)
                    
                    // Team Section
                    if let user = userViewModel.currentUser {
                        TeamSectionView(team: user.team)
                    }
                    
                    // Actions Section
                    ActionsSectionView(
                        onEditProfile: { showingEditProfile = true },
                        onSelectTeam: { showingTeamSelection = true }
                    )
                    
                    // Recent Workouts
                    RecentWorkoutsSection(workouts: workoutViewModel.workouts)
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await userViewModel.fetchCurrentUser()
                workoutViewModel.fetchWorkouts()
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(userViewModel: userViewModel)
        }
        .sheet(isPresented: $showingTeamSelection) {
            TeamSelectionView(userViewModel: userViewModel)
        }
        .onAppear {
            Task {
                await userViewModel.fetchCurrentUser()
            }
            workoutViewModel.fetchWorkouts()
        }
    }
}

struct ProfileHeaderView: View {
    let user: User?
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Image
            Circle()
                .fill(Color.blue.gradient)
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                )
            
            // User Info
            VStack(spacing: 8) {
                Text(user?.name ?? "Loading...")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("@\(user?.username ?? "username")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if user?.isCoach == true {
                    HStack {
                        Image(systemName: "shield.fill")
                            .foregroundColor(.orange)
                        Text("Coach")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

struct StatsSectionView: View {
    let workoutCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Stats")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 20) {
                StatCard(title: "Workouts", value: "\(workoutCount)", icon: "dumbbell.fill")
                StatCard(title: "Tokens", value: "0", icon: "star.fill")
                StatCard(title: "Team Rank", value: "#1", icon: "trophy.fill")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TeamSectionView: View {
    let team: String
    
    private func getTeamColor(_ team: String) -> Color {
        switch team {
        case "/teams/0": return Color(hex: "#ff7700") ?? .orange
        case "/teams/1": return Color(hex: "#007bff") ?? .blue
        case "/teams/2": return Color(hex: "#6f42c1") ?? .purple
        default: return .gray
        }
    }
    
    private func getTeamName(_ team: String) -> String {
        switch team {
        case "/teams/0": return "Killa Gorillaz"
        case "/teams/1": return "Dark Sharks"
        case "/teams/2": return "Regal Eagles"
        default: return "Unknown Team"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Team")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                Circle()
                    .fill(getTeamColor(team))
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(getTeamName(team))
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("Team Member")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

struct ActionsSectionView: View {
    let onEditProfile: () -> Void
    let onSelectTeam: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                Button(action: onEditProfile) {
                    HStack {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                        Text("Edit Profile")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                Button(action: onSelectTeam) {
                    HStack {
                        Image(systemName: "person.2")
                            .foregroundColor(.green)
                        Text("Change Team")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

struct RecentWorkoutsSection: View {
    let workouts: [Workout]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Workouts")
                .font(.headline)
                .fontWeight(.semibold)
            
            if workouts.isEmpty {
                Text("No workouts yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(workouts.prefix(5)) { workout in
                        WorkoutRowView(workout: workout)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

struct WorkoutRowView: View {
    let workout: Workout
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.liftType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(workout.weight) lbs")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(workout.createdAt, style: .relative)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Helper Views

struct EditProfileView: View {
    @ObservedObject var userViewModel: UserViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var username = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Profile Information") {
                    TextField("Name", text: $name)
                    TextField("Username", text: $username)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await userViewModel.updateProfile(name: name, username: username)
                            dismiss()
                        }
                    }
                }
            }
        }
        .onAppear {
            if let user = userViewModel.currentUser {
                name = user.name
                username = user.username
            }
        }
    }
}

struct TeamSelectionView: View {
    @ObservedObject var userViewModel: UserViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Team.allCases, id: \.self) { team in
                    Button {
                        Task {
                            await userViewModel.updateTeam(team: "/teams/\(team.rawValue)")
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Circle()
                                .fill(Color(hex: team.color) ?? .gray)
                                .frame(width: 20, height: 20)
                            
                            Text(team.displayName)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if userViewModel.currentUser?.team == "/teams/\(team.rawValue)" {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileView()
}
