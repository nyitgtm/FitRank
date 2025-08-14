import SwiftUI
import FirebaseFirestore

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var team: Team?
    @Published var isLoading = true
    @Published var errorMessage: String?
    
    private let userRepository = UserRepository()
    private let authManager = AuthenticationManager.shared
    
    init() {
        Task {
            await loadUserProfile()
        }
    }
    
    func loadUserProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let uid = try authManager.getCurrentUserUID()
            let userData = try await userRepository.getUser(uid: uid)
            
            if let userData = userData {
                self.user = userData
                // Load team information
                await loadTeamInfo(teamRef: userData.team)
            } else {
                errorMessage = "Failed to load user profile"
            }
        } catch {
            errorMessage = "Error loading profile: \(error.localizedDescription)"
            print("Profile loading error: \(error)")
        }
        
        isLoading = false
    }
    
    private func loadTeamInfo(teamRef: DocumentReference) async {
        do {
            let teamData = try await teamRef.getDocument()
            if teamData.exists {
                self.team = try teamData.data(as: Team.self)
            }
        } catch {
            print("Team loading error: \(error)")
        }
    }
    
    func signOut() {
        do {
            try authManager.signOut()
            // This will trigger the authentication flow in RootView
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
    }
}

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @Binding var showSignInView: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView("Loading profile...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                } else if let user = viewModel.user {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Profile Header
                            ProfileHeaderView(user: user, team: viewModel.team)
                            
                            // Profile Information
                            ProfileInfoSection(user: user, team: viewModel.team)
                            
                                                          // Account Actions
                              AccountActionsSection(showSignInView: $showSignInView)
                            
                            Spacer(minLength: 40)
                        }
                        .padding(.horizontal, 20)
                    }
                } else {
                    // Error state
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        
                        Text("Profile Not Found")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button("Try Again") {
                            Task {
                                await viewModel.loadUserProfile()
                            }
                        }
                        .foregroundColor(.blue)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.1))
                        )
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.loadUserProfile()
            }
        }
    }
}

struct ProfileHeaderView: View {
    let user: User
    let team: Team?
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Picture Placeholder
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
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
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            
            // User Name
            Text(user.name)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Username
            Text("@\(user.username)")
                .font(.title3)
                .foregroundColor(.secondary)
            
            // Team Badge
            if let team = team {
                TeamBadgeView(team: team)
            }
        }
        .padding(.vertical, 20)
    }
}

struct ProfileInfoSection: View {
    let user: User
    let team: Team?
    
    var body: some View {
        VStack(spacing: 16) {
            // Section Header
            HStack {
                Text("Profile Information")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // Info Cards
            VStack(spacing: 12) {
                InfoCard(
                    icon: "person.circle",
                    title: "Full Name",
                    value: user.name,
                    color: .blue
                )
                
                InfoCard(
                    icon: "at",
                    title: "Username",
                    value: user.username,
                    color: .green
                )
                
                InfoCard(
                    icon: "flag",
                    title: "Team",
                    value: team?.name ?? "Unknown",
                    color: .orange
                )
                
                InfoCard(
                    icon: "trophy",
                    title: "Tokens",
                    value: "\(user.tokens)",
                    color: .purple
                )
                
                InfoCard(
                    icon: "shield.lefthalf.fill",
                    title: "Role",
                    value: user.isCoach ? "Coach" : "Member",
                    color: user.isCoach ? .red : .blue
                )
            }
        }
    }
}

struct InfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
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
}

struct AccountActionsSection: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    @Binding var showSignInView: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Section Header
            HStack {
                Text("Account Actions")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // Action Buttons
            VStack(spacing: 12) {
                                  Button(action: {
                      Task {
                          do {
                              try viewModel.logOut()
                              showSignInView = true
                          } catch {
                              print(error)
                              // Handle error properly in the future
                          }
                      }
                  }) {
                    HStack(spacing: 12) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.title3)
                            .foregroundColor(.red)
                        
                        Text("Sign Out")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 16)
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
    }
}

//spent wayyyy too much time making this
struct TeamBadgeView: View {
    let team: Team
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Animated color indicator
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: team.color) ?? .gray)
                .frame(width: 20, height: 20)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
                .shadow(
                    color: (Color(hex: team.color) ?? .gray).opacity(0.6),
                    radius: isAnimating ? 8 : 4,
                    x: 0,
                    y: isAnimating ? 4 : 2
                )
            
            Text(team.name)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.systemBackground),
                            Color(.systemGray6)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    (Color(hex: team.color) ?? .gray).opacity(0.3),
                                    (Color(hex: team.color) ?? .gray).opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
        .shadow(
            color: (Color(hex: team.color) ?? .gray).opacity(0.3),
            radius: 12,
            x: 0,
            y: 6
        )
        .shadow(
            color: Color.black.opacity(0.1),
            radius: 4,
            x: 0,
            y: 2
        )
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    ProfileView(showSignInView: .constant(false))
}
