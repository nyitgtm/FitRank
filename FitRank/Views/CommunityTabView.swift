import SwiftUI

struct CommunityTabView: View {
    @State private var selectedView: ViewType = .feed
    
    enum ViewType {
        case feed // TikTok-style workout feed
        case posts // Social posts
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Segmented control to switch views
            Picker("View", selection: $selectedView) {
                Text("Workout Feed").tag(ViewType.feed)
                Text("Posts").tag(ViewType.posts)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Content
            Group {
                if selectedView == .feed {
                    TikTokFeedView()
                } else {
                    CommunityView()
                }
            }
        }
        .navigationTitle("Community")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        CommunityTabView()
    }
}
