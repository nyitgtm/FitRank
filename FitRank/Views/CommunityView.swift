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

// MARK: - Filter Types

enum CommunityFilterType: String, CaseIterable, Identifiable {
    case all = "All"
    case following = "Following"
    case teams = "Teams"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .all: return "globe"
        case .following: return "person.2.fill"
        case .teams: return "person.3.fill"
        }
    }
}

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Community View

struct CommunityView: View {
    // SWAP: we now use the Firebase-backed VM
    @StateObject private var vm = CommunityVM_Firebase()
    @StateObject private var friendsVM = FriendsListViewModel() // Add FriendsListViewModel
    @StateObject private var userRepository = UserRepository()
    @State private var commentingPost: CommunityPost?
    @State private var reportingPost: CommunityPost?
    @State private var showReportSheet = false
    
    // Filters
    @State private var selectedFilter: CommunityFilterType = .all
    @State private var selectedTeam: TeamFilter = .all
    @State private var showTeamFilter = false
    @State private var showFilters = false
    @State private var isCollapsed = false
    @State private var lastScrollOffset: CGFloat = 0
    
    @State private var searchText: String = ""
    @State private var blockedUserIds: Set<String> = []

    // Filtered posts based on team + search logic
    private var filteredPosts: [CommunityPost] {
        var items = vm.posts

        // 1. Top-level filter logic
        switch selectedFilter {
        case .all:
            break // Show everything
        case .following:
            // Filter by following list
            let friendIds = Set(friendsVM.friends.map { $0.userId })
            // Also include own posts? Usually yes, or maybe not. Let's include friends only for now.
            // If you want to include yourself: friendIds.insert(Auth.auth().currentUser?.uid ?? "")
            items = items.filter { friendIds.contains($0.authorId) }
        case .teams:
            // If "Teams" is selected, we apply the specific team filter
            if selectedTeam != .all {
                items = items.filter { $0.teamTag?.localizedCaseInsensitiveContains(selectedTeam.rawValue) == true }
            }
        }
        
        // Filter out blocked users using the cached blockedUserIds
        items = items.filter { !blockedUserIds.contains($0.authorId) }

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
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                
                // New Filter Bar (Collapsible)
                if showFilters {
                    CommunityFilterBar(
                        selectedFilter: $selectedFilter,
                        selectedTeam: $selectedTeam,
                        showTeamFilter: $showTeamFilter,
                        isCollapsed: $isCollapsed
                    )
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

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
                        Spacer()
                    } else {
                        ScrollView {
                            // Scroll Reader for offset
                            GeometryReader { geo in
                                Color.clear
                                    .preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .global).minY)
                            }
                            .frame(height: 0)
                            
                            LazyVStack(spacing: 16) {
                                ForEach(filteredPosts) { post in
                                    PostCardView(
                                        post: post,
                                        likeAction: { vm.toggleLike(post) },
                                        commentAction: { commentingPost = post },
                                        deleteAction: { vm.deletePost(post) },
                                        reportAction: {
                                            reportingPost = post
                                            showReportSheet = true
                                        },
                                        blockAction: {
                                            Task {
                                                await blockUser(userId: post.authorId)
                                            }
                                        }
                                    )
                                    .padding(.horizontal, 16)
                                }
                            }
                            .padding(.vertical, 16)
                            // Add extra padding at bottom for FAB
                            .padding(.bottom, 80)
                        }
                        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                            // Simple scroll direction detection
                            if value < lastScrollOffset - 10 {
                                // Scrolling down -> Collapse filter buttons and hide filter bar
                                withAnimation(.spring()) {
                                    isCollapsed = true
                                    showFilters = false
                                }
                            } else if value > lastScrollOffset + 10 {
                                // Scrolling up -> Expand filter buttons (but keep filter bar hidden)
                                withAnimation(.spring()) {
                                    isCollapsed = false
                                }
                            }
                            lastScrollOffset = value
                        }
                    }
                }
            }
            
            // Sticky FAB
            Button {
                vm.showComposer = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.blue)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button {
                    withAnimation(.spring()) {
                        showFilters.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("Community")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .rotationEffect(Angle(degrees: showFilters ? 180 : 0))
                    }
                }
            }
        }
        // Temporary upload success banner
        .overlay(alignment: .top) {
            if vm.postUploadSuccess {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                    Text("Post uploaded")
                        .foregroundColor(.white)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.green)
                .cornerRadius(12)
                .padding(.top, 8)
                .shadow(radius: 6)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }

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
        
        // Notifications Sheet (Removed from here, moved to HomeView)
        .onAppear {
            // Load friends when view appears so we have the list for filtering
            friendsVM.loadFriends()
            // Load blocked users
            Task {
                await loadBlockedUsers()
            }
        }
        .onChange(of: selectedFilter) { _, newFilter in
            // Auto-collapse filters when a non-teams filter is selected
            if newFilter != .teams {
                withAnimation(.spring()) {
                    showFilters = false
                }
            }
        }
        .sheet(isPresented: $showReportSheet) {
            if let post = reportingPost, let postId = post.backendId {
                ReportSheet(isPresented: $showReportSheet, workoutId: postId)
            }
        }
    }
    
    private func loadBlockedUsers() async {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              let currentUser = try? await userRepository.getUser(uid: currentUserId),
              let blockedUsers = currentUser.blockedUsers else {
            blockedUserIds = []
            return
        }
        blockedUserIds = Set(blockedUsers)
    }
    
    private func blockUser(userId: String) async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        do {
            try await userRepository.blockUser(currentUserId: currentUserId, blockedUserId: userId)
            print("✅ User blocked")
            // Update local blocked users list
            blockedUserIds.insert(userId)
        } catch {
            print("❌ Error blocking user: \(error)")
        }
    }
}

// MARK: - Community Filter Bar

struct CommunityFilterBar: View {
    @Binding var selectedFilter: CommunityFilterType
    @Binding var selectedTeam: TeamFilter
    @Binding var showTeamFilter: Bool
    @Binding var isCollapsed: Bool
    
    var body: some View {
        // Centered, equal-width buttons
        HStack(spacing: 10) {
            ForEach(CommunityFilterType.allCases) { filter in
                Button {
                    withAnimation(.spring()) {
                        selectedFilter = filter
                        
                        if filter == .teams {
                            showTeamFilter.toggle()
                        } else {
                            showTeamFilter = false
                        }
                    }
                } label: {
                    HStack(spacing: isCollapsed ? 0 : 6) {
                        // Icons for specific filters
                        Image(systemName: filter.icon)
                            .font(isCollapsed ? .body : .subheadline)
                        
                        if !isCollapsed {
                            Text(filter.rawValue)
                                .font(.subheadline)
                                .transition(.opacity.combined(with: .move(edge: .trailing)))
                        }
                        
                        // Chevron for teams if selected
                        if filter == .teams && selectedFilter == .teams && !isCollapsed {
                            Image(systemName: showTeamFilter ? "chevron.up" : "chevron.down")
                                .font(.caption)
                        }
                    }
                    .fontWeight(selectedFilter == filter ? .semibold : .medium)
                    .padding(.vertical, 8)
                    .padding(.horizontal, isCollapsed ? 16 : 0)
                    .frame(maxWidth: isCollapsed ? nil : .infinity)
                    .background(
                        Capsule()
                            .fill(selectedFilter == filter ? Color.blue : Color(.secondarySystemBackground))
                    )
                    .foregroundColor(selectedFilter == filter ? .white : .primary)
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .center)
        
        // Expanded Team Filter (only if Teams is selected and expanded)
        if selectedFilter == .teams && showTeamFilter {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(TeamFilter.allCases) { team in
                        Button {
                            withAnimation {
                                selectedTeam = team
                                showTeamFilter = false
                            }
                        } label: {
                            Text(team.rawValue)
                                .font(.caption)
                                .fontWeight(selectedTeam == team ? .semibold : .regular)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(selectedTeam == team ? team.color : Color.clear)
                                        .overlay(
                                            Capsule()
                                                .stroke(team.accent, lineWidth: selectedTeam == team ? 1 : 0)
                                        )
                                )
                                .foregroundColor(selectedTeam == team ? team.accent : .primary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

// MARK: - Filter Popover


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
    var reportAction: (() -> Void)? = nil
    var blockAction: (() -> Void)? = nil
    
    @State private var showDeleteAlert = false
    @State private var extractedImageURLs: [URL] = []

    // Limit images so they don't exceed the visible screen width
    private let maxImageWidth: CGFloat = min(UIScreen.main.bounds.width - 40, 400)

    private var teamColor: Color {
        let tag = post.teamTag?.lowercased() ?? ""
        if tag.contains("killa gorilla") { return .green }
        if tag.contains("dark sharks")   { return .blue }
        if tag.contains("regal eagle")   { return .yellow }
        return .orange
    }
    
    // Extract image URLs from text
    private func extractImageURLs(from text: String) -> [URL] {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "webp", "bmp"]
        
        var urls: [URL] = []
        for match in matches ?? [] {
            if let range = Range(match.range, in: text),
               let url = URL(string: String(text[range])) {
                // Check if URL points to an image
                let pathExtension = url.pathExtension.lowercased()
                if imageExtensions.contains(pathExtension) || url.absoluteString.contains("media-amazon") || url.absoluteString.contains("imgur") {
                    urls.append(url)
                }
            }
        }
        return urls
    }
    
    // Remove image URLs from display text
    private func textWithoutImageURLs(_ text: String) -> String {
        var cleanedText = text
        for url in extractedImageURLs {
            cleanedText = cleanedText.replacingOccurrences(of: url.absoluteString, with: "")
        }
        return cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Helper function to format timestamps in a user-friendly way
    private func formatTimestamp(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        // Less than a minute (60 seconds)
        if timeInterval < 60 {
            return "Just now"
        }
        
        // Less than an hour (60 minutes)
        if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        }
        
        // Today - less than 24 hours AND same calendar day
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return "Today at \(formatter.string(from: date))"
        }
        
        // Yesterday
        if calendar.isDateInYesterday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return "Yesterday at \(formatter.string(from: date))"
        }
        
        // Within the past week (7 days)
        if timeInterval < 604800 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE 'at' h:mm a"
            return formatter.string(from: date)
        }
        
        // Older posts - show date
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d 'at' h:mm a"
        return formatter.string(from: date)
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
                        Text(formatTimestamp(post.createdAt))
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
                        Button(role: .destructive) {
                            reportAction?()
                        } label: {
                            Label("Report Post", systemImage: "exclamationmark.bubble")
                        }
                        
                        Button(role: .destructive) {
                            blockAction?()
                        } label: {
                            Label("Block User", systemImage: "hand.raised.slash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .padding(.horizontal, 4)
                }
            }

            // Text
            if !post.text.isEmpty {
                let cleanText = textWithoutImageURLs(post.text)
                if !cleanText.isEmpty {
                    Text(cleanText).font(.body)
                }
            }
            
            // Images extracted from text URLs
            if !extractedImageURLs.isEmpty {
                ForEach(extractedImageURLs, id: \.self) { imageURL in
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .empty:
                            Rectangle().fill(Color.gray.opacity(0.15))
                                .frame(maxWidth: maxImageWidth)
                                .frame(height: 220)
                                .overlay(ProgressView())
                                .cornerRadius(12)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: maxImageWidth)
                                .cornerRadius(12)
                        case .failure:
                            Rectangle().fill(Color.gray.opacity(0.15))
                                .frame(maxWidth: maxImageWidth)
                                .frame(height: 220)
                                .overlay(
                                    VStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle")
                                            .font(.title2)
                                        Text("Failed to load image")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.secondary)
                                )
                                .cornerRadius(12)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            }

            // Image (local or remote)
            if let img = post.image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: maxImageWidth)
                    .cornerRadius(12)
            } else if let urlStr = post.imageURLString, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Rectangle().fill(Color.gray.opacity(0.15))
                            .frame(maxWidth: maxImageWidth)
                            .frame(height: 220)
                            .overlay(ProgressView())
                            .cornerRadius(12)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: maxImageWidth)
                            .cornerRadius(12)
                    case .failure:
                        Rectangle().fill(Color.gray.opacity(0.15))
                            .frame(maxWidth: maxImageWidth)
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
        .onAppear {
            extractedImageURLs = extractImageURLs(from: post.text)
        }
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
                                                        errorMessage = "Couldn't delete. \(error.localizedDescription)"
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
