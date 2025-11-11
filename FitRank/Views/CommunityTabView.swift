import SwiftUI

struct CommunityTabView: View {
    @State private var selectedView: ViewType = .feed
    
    enum ViewType {
        case feed // TikTok-style workout feed
        case posts // Social posts
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Segmented control at the very top
            VStack(spacing: 0) {
                Picker("View", selection: $selectedView) {
                    Text("Workout Feed").tag(ViewType.feed)
                    Text("Posts").tag(ViewType.posts)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider()
            }
            .background(Color(.systemBackground))
            
            // Content
            Group {
                if selectedView == .feed {
                    TikTokFeedView()
                        .ignoresSafeArea(edges: .bottom)
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
