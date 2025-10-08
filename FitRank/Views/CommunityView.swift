import SwiftUI
import PhotosUI
import FirebaseAuth

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
        case .killaGorilla: return Color.green.opacity(0.25)
        case .darkSharks:   return Color.blue.opacity(0.25)
        case .regalEagle:   return Color.yellow.opacity(0.35)
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
    // SWAP: we now use the Firebase-backed VM
    @StateObject private var vm = CommunityVM_Firebase()
    @State private var commentingPost: CommunityPost?
    @State private var showNotifications = false

    @State private var showFilter = false
    @State private var hoveredTeam: TeamFilter? = nil
    @State private var teamFilter: TeamFilter = .all
    @State private var searchText: String = ""

    // Filtered posts based on team + search logic
    private var filteredPosts: [CommunityPost] {
        var items = vm.posts

        if teamFilter != .all {
            items = items.filter { $0.teamTag?.localizedCaseInsensitiveContains(teamFilter.rawValue) == true }
        }

        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return items }

        if q.hasPrefix("@") {
            let tag = String(q.dropFirst()).lowercased()
            return items.filter {
                $0.authorName.lowercased().contains(tag) ||
                ($0.teamTag?.lowercased().contains(tag) ?? false)
            }
        } else {
            return items.filter {
                $0.text.lowercased().contains(q.lowercased()) ||
                $0.authorName.lowercased().contains(q.lowercased()) ||
                ($0.teamTag?.lowercased().contains(q.lowercased()) ?? false)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                
                // Notifications button with badge
                Button {
                    showNotifications = true
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 20))
                        
                        if vm.unreadCount > 0 {
                            Text("\(vm.unreadCount)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(minWidth: 16, minHeight: 16)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: 8, y: -8)
                        }
                    }
                }
                
                Button {
                    vm.showComposer = true
                } label: {
                    Label("Post", systemImage: "square.and.pencil")
                        .font(.subheadline)
                }
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
                                    commentAction: { commentingPost = post },
                                    deleteAction: { vm.deletePost(post) }
                                )
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)

        // Composer Sheet
        .sheet(isPresented: $vm.showComposer) {
            NewPostSheet(
                text: $vm.draftText,
                image: $vm.draftImage,
                onPost: vm.publishDraft
            )
        }

        // Comments Sheet (simple send; live sheet feed can be added later)
        .sheet(item: $commentingPost) { post in
            CommentsSheet(
                post: post,
                onSend: { txt in vm.addComment(txt, to: post) }
            )
            .presentationDetents([.medium, .large])
        }
        
        // Notifications Sheet
        .sheet(isPresented: $showNotifications) {
            NotificationsSheet(
                notifications: vm.notifications,
                onTapNotification: { notification in
                    vm.markNotificationAsRead(notification)
                },
                onMarkAllRead: {
                    vm.markAllNotificationsAsRead()
                }
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
    var deleteAction: (() -> Void)? = nil
    
    @State private var showDeleteAlert = false

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
                
                // Menu for post actions (delete if owner)
                let isOwner = Auth.auth().currentUser?.uid == post.authorId
                Menu {
                    if isOwner {
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Label("Delete Post", systemImage: "trash")
                        }
                    } else {
                        Button {
                        } label: {
                            Label("Only author can delete", systemImage: "lock.fill")
                        }.disabled(true)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .padding(.horizontal, 4)
                }
            }

            // Text
            if !post.text.isEmpty {
                Text(post.text).font(.body)
            }

            // Image (local or remote)
            if let img = post.image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipped()
                    .cornerRadius(12)
            } else if let urlStr = post.imageURLString, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Rectangle().fill(Color.gray.opacity(0.15))
                            .frame(height: 220)
                            .overlay(ProgressView())
                            .cornerRadius(12)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                            .clipped()
                            .cornerRadius(12)
                    case .failure:
                        Rectangle().fill(Color.gray.opacity(0.15))
                            .frame(height: 220)
                            .overlay(Image(systemName: "exclamationmark.triangle"))
                            .cornerRadius(12)
                    @unknown default:
                        EmptyView()
                    }
                }
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
        .alert("Delete Post", isPresented: $showDeleteAlert, actions: {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteAction?()
            }
        }, message: {
            Text("Are you sure you want to delete this post? This action cannot be undone.")
        })
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

import SwiftUI
import FirebaseAuth

struct CommentsSheet: View {
    let post: CommunityPost
    var onSend: (String) -> Void

    @State private var input: String = ""
    @State private var comments: [CommunityComment] = []

    @State private var showErrorAlert = false
    @State private var errorMessage = ""

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
                    ForEach(comments) { c in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(c.authorName).font(.subheadline).fontWeight(.semibold)
                                Text(c.createdAt, style: .relative)
                                    .foregroundColor(.secondary).font(.caption)
                                Spacer()

                                // Always show the menu; gate "Delete" by ownership
                                let isOwner = Auth.auth().currentUser?.uid == c.authorId
                                Menu {
                                    if isOwner {
                                        Button(role: .destructive) {
                                            // Optimistic UI
                                            if let idx = comments.firstIndex(where: { $0.backendId == c.backendId }) {
                                                comments.remove(at: idx)
                                            }
                                            // Firestore delete
                                            Task {
                                                guard let pid = post.backendId else { return }
                                                do {
                                                    try await CommunityService.shared.deleteComment(
                                                        postId: pid,
                                                        commentId: c.backendId
                                                    )
                                                } catch {
                                                    await MainActor.run {
                                                        errorMessage = "Couldn’t delete. \(error.localizedDescription)"
                                                        showErrorAlert = true
                                                        // put the comment back if delete failed
                                                        comments.insert(c, at: 0)
                                                    }
                                                }
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    } else {
                                        // Optional: a disabled item so you can see the menu is present
                                        Button {
                                        } label: {
                                            Label("Only author can delete", systemImage: "lock.fill")
                                        }.disabled(true)
                                    }
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .rotationEffect(.degrees(90))
                                        .padding(.horizontal, 4)
                                }
                            }
                            Text(c.text)
                        }
                        .padding(.horizontal)
                    }

                    if comments.isEmpty {
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
        .onAppear {
            // Live comments feed so we have backendId/authorId
            guard let pid = post.backendId else { return }
            CommunityService.shared.startComments(postId: pid) { items in
                self.comments = items
            }
        }
        .onDisappear {
            CommunityService.shared.stopComments()
        }
        .alert("Error", isPresented: $showErrorAlert, actions: {
            Button("OK", role: .cancel) {}
        }, message: {
            Text(errorMessage)
        })
    }
}
