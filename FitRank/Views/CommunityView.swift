import SwiftUI
import PhotosUI

// MARK: - Models

struct CommunityPost: Identifiable, Hashable {
    let id: UUID = UUID()
    var authorName: String
    var teamTag: String?         // e.g., "Killa Gorilla" / "Dark Sharks" / "Regal Eagle"
    var text: String
    var image: UIImage?
    var likeCount: Int
    var commentCount: Int
    var isLikedByMe: Bool
    var createdAt: Date
    var comments: [CommunityComment] = []
}

struct CommunityComment: Identifiable, Hashable {
    let id: UUID = UUID()
    var authorName: String
    var text: String
    var createdAt: Date
}

// MARK: - ViewModel (mock/local)

@MainActor
final class CommunityVM: ObservableObject {
    @Published var posts: [CommunityPost] = []
    @Published var isLoading = false
    @Published var showComposer = false
    @Published var draftText = ""
    @Published var draftImage: UIImage?

    init() { seed() }

    func seed() {
        posts = [
            CommunityPost(
                authorName: "Alex M.",
                teamTag: "Killa Gorilla",
                text: "Hit a new squat PR today! 🏋️‍♂️",
                image: nil,
                likeCount: 12,
                commentCount: 3,
                isLikedByMe: false,
                createdAt: Date().addingTimeInterval(-3600),
                comments: [
                    CommunityComment(authorName: "Priya", text: "Let's gooo! 🔥", createdAt: Date().addingTimeInterval(-3500)),
                    CommunityComment(authorName: "Ben", text: "Proud of you!", createdAt: Date().addingTimeInterval(-3400))
                ]
            ),
            CommunityPost(
                authorName: "Jenna",
                teamTag: "Dark Sharks",
                text: "Team session at 6pm — bring water & good vibes.",
                image: UIImage(systemName: "figure.run"),
                likeCount: 5,
                commentCount: 1,
                isLikedByMe: true,
                createdAt: Date().addingTimeInterval(-7200),
                comments: [
                    CommunityComment(authorName: "Sam", text: "See you there!", createdAt: Date().addingTimeInterval(-7100))
                ]
            ),
            CommunityPost(
                authorName: "Ava",
                teamTag: "Regal Eagle",
                text: "Plyo day ✨ Anyone got shoe recs?",
                image: nil,
                likeCount: 9,
                commentCount: 0,
                isLikedByMe: false,
                createdAt: Date().addingTimeInterval(-8200)
            )
        ]
    }

    func toggleLike(_ post: CommunityPost) {
        guard let idx = posts.firstIndex(of: post) else { return }
        posts[idx].isLikedByMe.toggle()
        posts[idx].likeCount += posts[idx].isLikedByMe ? 1 : -1
    }

    func addComment(_ text: String, to post: CommunityPost) {
        guard let idx = posts.firstIndex(of: post),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let c = CommunityComment(authorName: "You", text: text, createdAt: Date())
        posts[idx].comments.append(c)
        posts[idx].commentCount = posts[idx].comments.count
    }

    func publishDraft() {
        let trimmed = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || draftImage != nil else { return }
        let new = CommunityPost(
            authorName: "You",
            teamTag: "Team Demo",
            text: trimmed,
            image: draftImage,
            likeCount: 0,
            commentCount: 0,
            isLikedByMe: false,
            createdAt: Date()
        )
        posts.insert(new, at: 0)
        draftText = ""
        draftImage = nil
        showComposer = false
    }
}

// MARK: - Team Filter

enum TeamFilter: String, CaseIterable, Identifiable {
    case all = "Community"
    case killaGorilla = "Killa Gorilla"
    case darkSharks = "Dark Sharks"
    case regalEagle = "Regal Eagle"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .all:          return Color.secondary.opacity(0.25)
        case .killaGorilla: return Color.green.opacity(0.25)   // light green
        case .darkSharks:   return Color.blue.opacity(0.25)    // light blue
        case .regalEagle:   return Color.yellow.opacity(0.35)  // light yellow
        }
    }
    var accent: Color {
        switch self {
        case .all:          return .secondary
        case .killaGorilla: return .green
        case .darkSharks:   return .blue
        case .regalEagle:   return .yellow
        }
    }
}

// MARK: - Community View

struct CommunityView: View {
    @StateObject private var vm = CommunityVM()
    @State private var commentingPost: CommunityPost?

    @State private var showFilter = false
    @State private var hoveredTeam: TeamFilter? = nil
    @State private var teamFilter: TeamFilter = .all
    @State private var searchText: String = ""

    // Filtered posts based on team + search logic
    private var filteredPosts: [CommunityPost] {
        var items = vm.posts

        // Team filter
        if teamFilter != .all {
            items = items.filter { $0.teamTag?.localizedCaseInsensitiveContains(teamFilter.rawValue) == true }
        }

        // Search
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return items }

        if q.hasPrefix("@") {
            let tag = String(q.dropFirst()).lowercased()
            // match author or team when using @
            return items.filter {
                $0.authorName.lowercased().contains(tag) ||
                ($0.teamTag?.lowercased().contains(tag) ?? false)
            }
        } else {
            // plain text matches post text OR author name OR team
            return items.filter {
                $0.text.lowercased().contains(q.lowercased()) ||
                $0.authorName.lowercased().contains(q.lowercased()) ||
                ($0.teamTag?.lowercased().contains(q.lowercased()) ?? false)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header: Post + Filter (chip removed)
            HStack {
                Spacer()

                // Post button (composer)
                Button {
                    vm.showComposer = true
                } label: {
                    Label("Post", systemImage: "square.and.pencil")
                        .font(.subheadline)
                }

                // Filter button (popover)
                Button {
                    showFilter.toggle()
                } label: {
                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                        .labelStyle(.titleAndIcon)
                        .font(.subheadline)
                }
                .popover(isPresented: $showFilter, arrowEdge: .top) {
                    FilterPopover(
                        selected: teamFilter,
                        hovered: $hoveredTeam,
                        onSelect: { sel in
                            teamFilter = sel
                            showFilter = false
                        }
                    )
                    .frame(maxWidth: 280)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 6)

            // Search bar
            SearchBar(text: $searchText)
                .padding(.horizontal, 16)
                .padding(.bottom, 6)

            Divider()

            // Feed
            Group {
                if vm.isLoading {
                    Spacer()
                    ProgressView("Loading community...")
                    Spacer()
                } else if filteredPosts.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary)
                        Text("No posts match your filter")
                            .font(.headline)
                        Text("Try a different team or search.")
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredPosts) { post in
                                PostCardView(
                                    post: post,
                                    likeAction: { vm.toggleLike(post) },
                                    commentAction: { commentingPost = post }
                                )
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
        }
        .navigationTitle("") // keep navbar visible, no large title
        .navigationBarTitleDisplayMode(.inline)

        // Composer Sheet
        .sheet(isPresented: $vm.showComposer) {
            NewPostSheet(
                text: $vm.draftText,
                image: $vm.draftImage,
                onPost: vm.publishDraft
            )
        }

        // Comments Sheet
        .sheet(item: $commentingPost) { post in
            CommentsSheet(
                post: post,
                onSend: { txt in vm.addComment(txt, to: post) }
            )
            .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - Filter Popover

private struct FilterPopover: View {
    let selected: TeamFilter
    @Binding var hovered: TeamFilter?
    var onSelect: (TeamFilter) -> Void

    private let options: [TeamFilter] = [.all, .killaGorilla, .darkSharks, .regalEagle]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Filter Teams")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.top, 4)

            ForEach(options) { option in
                Button {
                    onSelect(option)
                } label: {
                    HStack {
                        Text(option.rawValue)
                            .font(.subheadline)
                            .fontWeight(option == selected ? .semibold : .regular)
                        Spacer()
                        if option == selected {
                            Image(systemName: "checkmark").font(.footnote)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        (hovered == option ? option.color : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    )
                    .contentShape(Rectangle())
                }
                // Hover highlight (iPad/macOS pointer). Ignored on iPhone.
                .onHover { isHovering in
                    hovered = isHovering ? option : nil
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Search Bar

private struct SearchBar: View {
    @Binding var text: String
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundColor(.secondary)
            TextField("Search @user or @team", text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focused)
            if !text.isEmpty {
                Button {
                    text = ""
                    focused = false
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Post Card

struct PostCardView: View {
    let post: CommunityPost
    var likeAction: () -> Void
    var commentAction: () -> Void

    // Map team tag -> chip color
    private var teamColor: Color {
        let tag = post.teamTag?.lowercased() ?? ""
        if tag.contains("killa gorilla") { return .green }
        if tag.contains("dark sharks")   { return .blue }
        if tag.contains("regal eagle")   { return .yellow }
        return .orange
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 10) {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .overlay(Image(systemName: "person.fill"))
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName).font(.subheadline).fontWeight(.semibold)
                    HStack(spacing: 6) {
                        if let tag = post.teamTag {
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6).padding(.vertical, 3)
                                .background(teamColor.opacity(0.15))
                                .foregroundColor(teamColor)
                                .cornerRadius(6)
                        }
                        Text(post.createdAt, style: .time)
                            .font(.caption2).foregroundColor(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "ellipsis")
            }

            // Text
            if !post.text.isEmpty {
                Text(post.text).font(.body)
            }

            // Image
            if let img = post.image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipped()
                    .cornerRadius(12)
            }

            // Actions
            HStack(spacing: 18) {
                Button(action: likeAction) {
                    Label("\(post.likeCount)", systemImage: post.isLikedByMe ? "heart.fill" : "heart")
                }
                Button(action: commentAction) {
                    Label("\(post.commentCount)", systemImage: "text.bubble")
                }
                Spacer()
                Button { /* share later */ } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            .font(.subheadline)
            .foregroundColor(.primary.opacity(0.8))
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Composer

struct NewPostSheet: View {
    @Binding var text: String
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    @State private var pickerItem: PhotosPickerItem?

    var onPost: () -> Void

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 12) {
                TextEditor(text: $text)
                    .frame(minHeight: 140)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(12)
                        .overlay(alignment: .topTrailing) {
                            Button {
                                self.image = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .padding(6)
                                    .background(Color.white.opacity(0.8))
                                    .clipShape(Circle())
                            }
                            .padding(6)
                        }
                }

                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Label("Add Photo", systemImage: "photo")
                }
                .onChange(of: pickerItem) { _, newValue in
                    guard let newValue else { return }
                    Task {
                        if let data = try? await newValue.loadTransferable(type: Data.self),
                           let ui = UIImage(data: data) {
                            image = ui
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("New Post")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        onPost()
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && image == nil)
                }
            }
        }
    }
}

// MARK: - Comments

struct CommentsSheet: View {
    let post: CommunityPost
    var onSend: (String) -> Void

    @State private var input: String = ""

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.secondary.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 8).padding(.bottom, 12)

            Text("Comments")
                .font(.headline)
                .padding(.bottom, 8)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    ForEach(post.comments) { c in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(c.authorName).font(.subheadline).fontWeight(.semibold)
                                Text(c.createdAt, style: .relative)
                                    .foregroundColor(.secondary).font(.caption)
                            }
                            Text(c.text)
                        }
                        .padding(.horizontal)
                    }
                    if post.comments.isEmpty {
                        Text("Be the first to comment.")
                            .foregroundColor(.secondary)
                            .padding(.vertical, 40)
                    }
                }
                .padding(.top, 8)
            }

            Divider()

            HStack {
                TextField("Write a comment…", text: $input)
                    .textFieldStyle(.roundedBorder)
                Button {
                    let msg = input.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !msg.isEmpty else { return }
                    onSend(msg)
                    input = ""
                } label: {
                    Image(systemName: "paperplane.fill")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

