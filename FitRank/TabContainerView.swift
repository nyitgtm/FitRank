import SwiftUI

struct TabContainerView: View {
    @Binding var showSignInView: Bool
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var selectedTab: Tab = .home

    enum Tab: Hashable { case home, community, upload, nutrition, profile }
    
    init(showSignInView: Binding<Bool>) {
        self._showSignInView = showSignInView
        
        // Configure tab bar appearance to always have white background
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView { HomeView() }
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(Tab.home)

            NavigationView { CommunityTabView() }
                .tabItem { Label("Community", systemImage: "person.3.fill") }
                .tag(Tab.community)

            NavigationView { UploadView() }
                .tabItem { Label("Upload", systemImage: "plus.app.fill") }
                .tag(Tab.upload)

            NavigationView { NutritionMainView() }
                .tabItem { Label("Nutrition", systemImage: "takeoutbag.and.cup.and.straw.fill") }
                .tag(Tab.nutrition)

            NavigationView {
                ProfileView(showSignInView: $showSignInView)
            }
            .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
            .tag(Tab.profile)
        }
    }
}

#Preview {
    TabContainerView(showSignInView: .constant(false))
        .environmentObject(ThemeManager.shared)
}
