import SwiftUI
import Foundation
import FirebaseAuth
import Combine

struct ProfileView: View {
    @StateObject private var userViewModel = UserViewModel()
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @StateObject private var themeManager = ThemeManager.shared
    
    @Binding var showSignInView: Bool
    
    var body: some View {
        NavigationView {
                    ZStack {
                        Color(.systemGroupedBackground)
                            .ignoresSafeArea()
                        
                        if userViewModel.isLoading {
                            ProgressView("Loading profile...")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        } else if let user = userViewModel.currentUser {
                            ScrollView {
                                VStack(spacing: 28) {
                                    
                                    // Header
                                    ModernProfileHeaderView(user: user)
                                    
                                    // Info Cards
                                    VStack(spacing: 20) {
                                        ProfileInfoCard(icon: "person.circle", title: "Full Name", value: user.name)
                                        ProfileInfoCard(icon: "at", title: "Username", value: "@\(user.username)")
                                        ProfileInfoCard(icon: "flag", title: "Team", value: user.team)
                                        ProfileInfoCard(icon: "shield.lefthalf.fill", title: "Role", value: user.isCoach ? "Coach" : "Member")
                                    }
                                    
                                    // Stats Section
                                    StatsSectionModern(workoutCount: workoutViewModel.workouts.count)
                                    
                                    // Dark Mode Toggle
                                    DarkModeToggleCard(isDarkMode: $themeManager.isDarkMode)
                                    
                                    // Sign Out Button
                                    VStack(spacing: 16) {
                                        ModernActionButton(
                                            icon: "rectangle.portrait.and.arrow.right",
                                            title: "Sign Out",
                                            color: .red
                                        ) {
                                            userViewModel.signOut()
                                            showSignInView = true
                                        }
                                    }
                                    
                                    // Recent Workouts
                                    ModernRecentWorkoutsSection(workouts: workoutViewModel.workouts)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 30)
                            }
                        } else {
                            ProgressView("Loading profile...")
                        }
                    }
                    .navigationTitle("Profile")
                    .navigationBarTitleDisplayMode(.large)
                    .refreshable {
                        await loadUserAndWorkouts()
                    }
                    .task {
                        await loadUserAndWorkouts()
                    }
                    .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
        }
    }
    
    // MARK: - Helper function
    private func loadUserAndWorkouts() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            // No authenticated user, show sign in screen
            print("ProfileView: No authenticated user found")
            showSignInView = true
            return
        }
        
        print("ProfileView: Fetching user with UID: \(uid)")
        
        do {
            if let user = try await UserRepository().getUser(uid: uid) {
                print("ProfileView: User fetched successfully - \(user.username)")
                userViewModel.currentUser = user
                
                // Load dark mode preference from user profile
                if let isDarkMode = user.isDarkMode {
                    themeManager.isDarkMode = isDarkMode
                    print("✅ Loaded dark mode from user profile: \(isDarkMode)")
                }
            } else {
                // Firestore user not found, show sign in screen
                print("ProfileView: User document not found in Firestore for UID: \(uid)")
                showSignInView = true
            }
        } catch {
            print("ProfileView: Error fetching user - \(error.localizedDescription)")
            print("ProfileView: Full error - \(error)")
            // Error fetching user, show sign in screen
            showSignInView = true
        }
        
        workoutViewModel.fetchWorkouts()
    }
}

// MARK: - Modernized Components

struct ModernProfileHeaderView: View {
    let user: User
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Picture
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                )
                .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
            
            Text(user.name)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("@\(user.username)")
                .font(.title3)
                .foregroundColor(.secondary)
            
            if user.isCoach {
                Label("Coach", systemImage: "shield.fill")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .cornerRadius(12)
            }
        }
        .padding(.vertical, 20)
    }
}

struct ProfileInfoCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 0.5)
        )
    }
}

struct StatsSectionModern: View {
    let workoutCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Stats")
                .font(.title2)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                ModernStatCard(title: "Workouts", value: "\(workoutCount)", icon: "dumbbell.fill", color: .blue)
                ModernStatCard(title: "Tokens", value: "0", icon: "star.fill", color: .yellow)
                ModernStatCard(title: "Team Rank", value: "#1", icon: "trophy.fill", color: .orange)
            }
        }
    }
}

struct ModernStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        )
    }
}

struct ModernActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ModernRecentWorkoutsSection: View {
    let workouts: [Workout]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Workouts")
                .font(.title2)
                .fontWeight(.semibold)
            
            if workouts.isEmpty {
                Text("No workouts yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(workouts.prefix(5)) { workout in
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
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                    )
                }
            }
        }
    }
}

// MARK: - Dark Mode Toggle Card

struct DarkModeToggleCard: View {
    @Binding var isDarkMode: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Appearance")
                .font(.title2)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                    .font(.title2)
                    .foregroundColor(isDarkMode ? .purple : .orange)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("DARK MODE")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(isDarkMode ? "Enabled" : "Disabled")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Toggle("", isOn: $isDarkMode)
                    .labelsHidden()
                    .tint(.blue)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 0.5)
            )
        }
    }
}

#Preview {
    ProfileView(showSignInView: .constant(false))
}
