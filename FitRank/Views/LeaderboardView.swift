import SwiftUI

struct LeaderboardView: View {
    @StateObject private var leaderboardViewModel = LeaderboardViewModel()
    @State private var selectedTab: LeaderboardTab = .global
    
    enum LeaderboardTab: String, CaseIterable {
        case global = "Global"
        case team = "Team"
        case gym = "Gym"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                Picker("Leaderboard Type", selection: $selectedTab) {
                    ForEach(LeaderboardTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Leaderboard content
                if leaderboardViewModel.isLoading {
                    Spacer()
                    ProgressView("Loading leaderboard...")
                        .scaleEffect(1.2)
                    Spacer()
                } else {
                    TabView(selection: $selectedTab) {
                        GlobalLeaderboardView(entries: leaderboardViewModel.globalLeaderboard)
                            .tag(LeaderboardTab.global)
                        
                        TeamLeaderboardView(entries: leaderboardViewModel.teamLeaderboard)
                            .tag(LeaderboardTab.team)
                        
                        GymLeaderboardView(entries: leaderboardViewModel.gymLeaderboard)
                            .tag(LeaderboardTab.gym)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await leaderboardViewModel.refreshLeaderboards()
            }
        }
        .onAppear {
            leaderboardViewModel.fetchLeaderboards()
        }
    }
}

struct GlobalLeaderboardView: View {
    let entries: [LeaderboardEntry]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    LeaderboardRowView(
                        rank: index + 1,
                        entry: entry,
                        showTeam: true
                    )
                }
            }
            .padding()
        }
    }
}

struct TeamLeaderboardView: View {
    let entries: [LeaderboardEntry]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    LeaderboardRowView(
                        rank: index + 1,
                        entry: entry,
                        showTeam: false
                    )
                }
            }
            .padding()
        }
    }
}

struct GymLeaderboardView: View {
    let entries: [LeaderboardEntry]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    LeaderboardRowView(
                        rank: index + 1,
                        entry: entry,
                        showTeam: true
                    )
                }
            }
            .padding()
        }
    }
}

struct LeaderboardRowView: View {
    let rank: Int
    let entry: LeaderboardEntry
    let showTeam: Bool
    @StateObject private var teamRepository = TeamRepository()
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank
            ZStack {
                Circle()
                    .fill(rankColor)
                    .frame(width: 40, height: 40)
                
                Text("\(rank)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.userName)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if showTeam {
                    Text(getTeamName(entry.team))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Score
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(entry.score)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("points")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onAppear {
            Task {
                await teamRepository.fetchTeams()
            }
        }
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .brown
        default: return .blue
        }
    }
    
    private func getTeamName(_ team: String) -> String {
        if let teamData = teamRepository.getTeam(byReference: team) {
            return teamData.name
        }
        return "Unknown Team"
    }
}

#Preview {
    LeaderboardView()
}
