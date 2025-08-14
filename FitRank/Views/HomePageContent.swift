//
//  HomePageContent.swift
//  FitRank
//
//  Created by Navraj Singh on 6/8/25.
//

import SwiftUI
import FirebaseFirestore

@MainActor
final class SettingsViewModel: ObservableObject {
    func logOut() throws {
        try AuthenticationManager.shared.signOut()
    }
}

@MainActor
final class HomePageViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // Display fields
    @Published var displayName: String = ""
    @Published var username: String = ""
    @Published var tokens: Int = 0
    @Published var teamName: String = ""
    @Published var teamColorHex: String = "#666666"

    private let db = Firestore.firestore()

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let uid = try AuthenticationManager.shared.getCurrentUserUID()
            let snapshot = try await db.collection("users")
                .whereField("uid", isEqualTo: uid)
                .limit(to: 1)
                .getDocuments()

            guard let doc = snapshot.documents.first else {
                errorMessage = "User not found."
                return
            }

            // Decode using your existing User model
            guard let user = try? doc.data(as: User.self) else {
                errorMessage = "Failed to decode user."
                return
            }

            displayName = user.name
            username = "@" + user.username
            tokens = user.tokens

            // Resolve team document (DocumentReference)
            let teamRef = user.team
            let teamDoc = try await teamRef.getDocument()
            if let teamData = teamDoc.data() {
                teamName = (teamData["name"] as? String) ?? "Team"
                teamColorHex = (teamData["color"] as? String) ?? "#666666"
            } else {
                teamName = "Team"
                teamColorHex = "#666666"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct HomePageContent: View {
    @StateObject private var settingsVM = SettingsViewModel()
    @StateObject private var viewModel = HomePageViewModel()
    @Binding var showSignInView: Bool

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                } else if let error = viewModel.errorMessage {
                    errorState(error)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            headerSection
                            tokensCard
                            teamCard
                            Spacer(minLength: 20)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Home")
                        .font(.title2).fontWeight(.bold)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            Task {
                                do {
                                    try settingsVM.logOut()
                                    showSignInView = true
                                } catch {
                                    // Optionally present error UI
                                    print(error)
                                }
                            }
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome,")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(viewModel.displayName.isEmpty ? "Athlete" : viewModel.displayName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)

            if !viewModel.username.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "person.fill")
                        .foregroundColor(.secondary)
                    Text(viewModel.username)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var tokensCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Points")
                .font(.headline)
                .foregroundColor(.primary)

            HStack(alignment: .center) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 72, height: 72)
                        .shadow(color: Color.blue.opacity(0.25), radius: 10, x: 0, y: 6)
                    Image(systemName: "star.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 28, weight: .bold))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Total Points")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.tokens)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                }
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        }
    }

    private var teamCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Team")
                .font(.headline)
                .foregroundColor(.primary)

            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: viewModel.teamColorHex) ?? .gray)
                    .frame(width: 22, height: 22)
                    .shadow(color: (Color(hex: viewModel.teamColorHex) ?? .gray).opacity(0.4), radius: 6, x: 0, y: 3)

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.teamName.isEmpty ? "Team" : viewModel.teamName)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text("Compete, upload, and lead the board.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        }
    }

    // MARK: - Error State
    private func errorState(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundColor(.orange)
            Text("Something went wrong")
                .font(.title3)
                .fontWeight(.semibold)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await viewModel.load() }
            }
            .foregroundColor(.blue)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
        }
        .padding()
    }
}

#Preview {
    HomePageContent(showSignInView: .constant(false))
}
