import SwiftUI

struct LeaderboardView: View {
    @StateObject private var viewModel = LeaderboardViewModel()
    @StateObject private var teamRepository = TeamRepository()
    @State private var selectedMetric: ScoreType = .tokens
    @State private var selectedLift: LiftType = .bench
    @State private var selectedTab: LeaderboardTab = .global
    
    enum LeaderboardTab: String, CaseIterable {
        case global = "Global"
        case team = "Team"
        case following = "Following"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Metric Toggle (Tokens / Weight)
                HStack(spacing: 0) {
                    ForEach(ScoreType.allCases, id: \.self) { metric in
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedMetric = metric
                                Task {
                                    await viewModel.fetchLeaderboards(
                                        scoreType: metric,
                                        liftType: metric == .weight ? selectedLift : nil
                                    )
                                }
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: metric.icon)
                                    .font(.system(size: 16, weight: .semibold))
                                Text(metric.rawValue)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(selectedMetric == metric ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedMetric == metric ? Color.blue : Color.gray.opacity(0.15))
                            )
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
                
                // Lift Type Selector (only shown for Weight)
                if selectedMetric == .weight {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(LiftType.allCases, id: \.self) { lift in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedLift = lift
                                        Task {
                                            await viewModel.fetchLeaderboards(
                                                scoreType: .weight,
                                                liftType: lift
                                            )
                                        }
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: lift.icon)
                                            .font(.system(size: 14))
                                        Text(lift.displayName)
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(selectedLift == lift ? .white : .primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        Capsule()
                                            .fill(selectedLift == lift ? Color.blue : Color.gray.opacity(0.15))
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 8)
                }
                
                // Tab Selector (Global / Team / Following)
                Picker("Leaderboard Type", selection: $selectedTab) {
                    ForEach(LeaderboardTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Leaderboard Content
                if viewModel.isLoading {
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading leaderboard...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    TabView(selection: $selectedTab) {
                        LeaderboardContentView(
                            entries: viewModel.globalLeaderboard,
                            showTeam: true,
                            teamRepository: teamRepository
                        )
                        .tag(LeaderboardTab.global)
                        
                        LeaderboardContentView(
                            entries: viewModel.teamLeaderboard,
                            showTeam: false,
                            teamRepository: teamRepository
                        )
                        .tag(LeaderboardTab.team)
                        
                        LeaderboardContentView(
                            entries: viewModel.followingLeaderboard,
                            showTeam: true,
                            teamRepository: teamRepository,
                            emptyMessage: "You're not following anyone yet",
                            emptySubMessage: "Follow friends to see their rankings here"
                        )
                        .tag(LeaderboardTab.following)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            await teamRepository.fetchTeams()
            await viewModel.fetchLeaderboards(
                scoreType: selectedMetric,
                liftType: selectedMetric == .weight ? selectedLift : nil
            )
        }
    }
}

struct LeaderboardContentView: View {
    let entries: [LeaderboardEntry]
    let showTeam: Bool
    @ObservedObject var teamRepository: TeamRepository
    var emptyMessage: String = "No entries yet"
    var emptySubMessage: String = "Be the first to compete!"
    
    var body: some View {
        if entries.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.gray.opacity(0.4))
                Text(emptyMessage)
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(emptySubMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(entries) { entry in
                        LeaderboardRowView(
                            entry: entry,
                            showTeam: showTeam,
                            teamRepository: teamRepository
                        )
                    }
                }
                .padding()
            }
        }
    }
}

struct LeaderboardRowView: View {
    let entry: LeaderboardEntry
    let showTeam: Bool
    @ObservedObject var teamRepository: TeamRepository
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank Badge
            ZStack {
                Circle()
                    .fill(rankGradient)
                    .frame(width: 50, height: 50)
                    .shadow(color: rankShadowColor, radius: 4, x: 0, y: 2)
                
                if entry.rank <= 3 {
                    Image(systemName: rankIcon)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(entry.rank)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            // User Info
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.userName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Text("@\(entry.username)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    if showTeam, let teamData = teamRepository.getTeam(byReference: entry.team) {
                        Text("•")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                        
                        HStack(spacing: 4) {
                            if let icon = teamData.icon {
                                Image(systemName: icon)
                                    .font(.system(size: 12))
                                    .foregroundColor(colorFromHex(teamData.color))
                            }
                            Text(teamData.name)
                                .font(.system(size: 14))
                                .foregroundColor(colorFromHex(teamData.color))
                        }
                    }
                }
            }
            
            Spacer()
            
            // Score
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Text("\(entry.score)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    if entry.scoreType == .weight {
                        Text("lbs")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 4) {
                    Image(systemName: entry.scoreType.icon)
                        .font(.system(size: 11))
                    Text(entry.scoreType == .tokens ? "tokens" : (entry.liftType?.displayName ?? ""))
                        .font(.system(size: 12))
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(rankBorderColor, lineWidth: entry.rank <= 3 ? 2 : 0)
        )
    }
    
    private func colorFromHex(_ hex: String) -> Color {
        return Color(hex: hex) ?? .gray
    }
    
    private var rankGradient: LinearGradient {
        switch entry.rank {
        case 1:
            return LinearGradient(
                colors: [colorFromHex("FFD700"), colorFromHex("FFA500")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 2:
            return LinearGradient(
                colors: [colorFromHex("C0C0C0"), colorFromHex("A8A8A8")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 3:
            return LinearGradient(
                colors: [colorFromHex("CD7F32"), colorFromHex("B87333")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var rankIcon: String {
        switch entry.rank {
        case 1: return "crown.fill"
        case 2: return "medal.fill"
        case 3: return "medal.fill"
        default: return ""
        }
    }
    
    private var rankShadowColor: Color {
        switch entry.rank {
        case 1: return colorFromHex("FFD700").opacity(0.4)
        case 2: return colorFromHex("C0C0C0").opacity(0.4)
        case 3: return colorFromHex("CD7F32").opacity(0.4)
        default: return Color.blue.opacity(0.2)
        }
    }
    
    private var rankBorderColor: Color {
        switch entry.rank {
        case 1: return colorFromHex("FFD700").opacity(0.5)
        case 2: return colorFromHex("C0C0C0").opacity(0.5)
        case 3: return colorFromHex("CD7F32").opacity(0.5)
        default: return Color.clear
        }
    }
}

#Preview {
    LeaderboardView()
}
