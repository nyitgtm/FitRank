import SwiftUI
import Foundation
import FirebaseAuth
import Combine

struct ProfileView: View {
    @StateObject private var userViewModel = UserViewModel()
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @Binding var showSignInView: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.selectedTheme.backgroundColor
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
                            StatsSectionModern(workoutCount: workoutViewModel.userWorkouts.count)
                            
                            // Appearance Navigation Button
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Settings")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                NavigationLink(destination: AppearanceView()) {
                                    AppearanceNavigationCard(currentTheme: themeManager.selectedTheme)
                                }
                            }
                            
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
                            ModernRecentWorkoutsSection(workouts: workoutViewModel.userWorkouts)
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
            .preferredColorScheme(themeManager.selectedTheme.colorScheme)
            .accentColor(themeManager.selectedTheme.accentColor)
        }
    }
    
    // MARK: - Helper function
    private func loadUserAndWorkouts() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("ProfileView: No authenticated user found")
            showSignInView = true
            return
        }
        
        print("ProfileView: Fetching user with UID: \(uid)")
        
        do {
            if let user = try await UserRepository().getUser(uid: uid) {
                print("ProfileView: User fetched successfully - \(user.username)")
                userViewModel.currentUser = user
                
                // Fetch actual user workouts
                await workoutViewModel.fetchAllUserWorkouts(userId: uid)
            } else {
                print("ProfileView: User document not found in Firestore for UID: \(uid)")
                showSignInView = true
            }
        } catch {
            print("ProfileView: Error fetching user - \(error.localizedDescription)")
            print("ProfileView: Full error - \(error)")
            showSignInView = true
        }
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
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(themeManager.selectedTheme.accentColor)
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
        .background(RoundedRectangle(cornerRadius: 12).fill(themeManager.selectedTheme.cardBackgroundColor))
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
                VStack(spacing: 12) {
                    Image(systemName: "dumbbell")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No workouts yet")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            } else {
                ForEach(workouts.prefix(5)) { workout in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(workout.liftTypeEnum.displayName)
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

// MARK: - Appearance Navigation Card

struct AppearanceNavigationCard: View {
    let currentTheme: AppTheme
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconForTheme(currentTheme))
                .font(.title2)
                .foregroundColor(currentTheme.accentColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("APPEARANCE")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(currentTheme.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 0.5)
        )
    }
    
    private func iconForTheme(_ theme: AppTheme) -> String {
        switch theme {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .ocean: return "drop.fill"
        case .sunset: return "sun.horizon.fill"
        case .forest: return "leaf.fill"
        }
    }
}

#Preview {
    ProfileView(showSignInView: .constant(false))
}


