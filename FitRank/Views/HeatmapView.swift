import SwiftUI
import MapKit

struct HeatmapView: View {
    @StateObject private var gymRepository = GymRepository()
    @StateObject private var locationManager = LocationManager()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var currentZoomLevel: Double = 0.01
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomLeading) {
                // Map View
                Map(position: $cameraPosition) {
                    // Gym annotations
                    let _ = print("Debug: Rendering map with \(gymRepository.gyms.count) gyms")
                    ForEach(gymRepository.gyms, id: \.id) { gym in
                        let _ = print("Debug: Rendering gym: \(gym.name) at \(gym.location.lat), \(gym.location.lon)")
                        Annotation(gym.name, coordinate: CLLocationCoordinate2D(
                            latitude: gym.location.lat,
                            longitude: gym.location.lon
                        )) {
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(colorForTeam(teamId: gym.ownerTeamId))
                                    .frame(width: 20, height: 20)
                                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                                
                                // Show team ownership when zoomed in
                                if isZoomedIn,
                                   let teamId = gym.ownerTeamId,
                                   teamId != "0", // Exclude default/unowned
                                   let team = gymRepository.getTeam(for: teamId) {
                                    Text("Owned by \(team.name)")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(6)
                                        .opacity(0.9)
                                }
                            }
                        }
                    }
                    
                    // User location annotation
                    if let userLocation = locationManager.userLocation {
                        Annotation("You", coordinate: userLocation) {
                            PulsingDot()
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic, emphasis: .muted))
                .onMapCameraChange(frequency: .continuous) { context in
                    currentZoomLevel = max(context.region.span.latitudeDelta, context.region.span.longitudeDelta)
                }
                
                // Loading indicator
                if gymRepository.isLoading {
                    VStack {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading gyms...")
                                .font(.caption)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        Spacer()
                    }
                    .padding(.top, 60)
                }
                
                // Home button and debug controls
                VStack {
                    Spacer()
                    HStack {
                        homeButton
                        
                        // Debug button to manually fetch gyms
                        Button {
                            zoomToFitAllAnnotations()
                        } label: {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .medium))
                                .padding(12)
                                .background(Color.orange)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .padding(.leading, 10)
                        
                        // Manual refresh button
                        Button {
                            gymRepository.fetchGymsMock()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .medium))
                                .padding(12)
                                .background(Color.green)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .padding(.leading, 10)
                        
                        Spacer()
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)
            .navigationTitle("Heatmap")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                locationManager.requestLocationPermission()
                // Use mock data for development
                gymRepository.fetchGymsMock()
            }
            .onChange(of: gymRepository.gyms.count) {
                // Auto-zoom when gyms are loaded
                print("Debug: Gyms count changed to: \(gymRepository.gyms.count)")
                if !gymRepository.gyms.isEmpty {
                    print("Debug: Gyms loaded, auto-zooming in 0.5 seconds")
                    print("Debug: First gym: \(gymRepository.gyms[0])")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        zoomToFitAllAnnotations()
                    }
                }
            }
            .alert("Error", isPresented: .constant(gymRepository.errorMessage != nil)) {
                Button("OK") {
                    gymRepository.errorMessage = nil
                }
            } message: {
                if let errorMessage = gymRepository.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    // Computed property to check if map is zoomed in enough to show team labels
    private var isZoomedIn: Bool {
        return currentZoomLevel < 0.01
    }
    
    // Helper function to get team color
    func colorForTeam(teamId: String?) -> Color {
        guard let teamId = teamId,
              let team = gymRepository.getTeam(for: teamId) else {
            return .gray
        }
        
        // Convert team color string to SwiftUI Color
        switch team.color.lowercased() {
        case "green", "#00ff00", "#008000":
            return .green
        case "blue", "#0000ff", "#007bff":
            return .blue
        case "red", "#ff0000", "#dc3545":
            return .red
        case "yellow", "#ffff00", "#ffc107":
            return .yellow
        case "orange", "#ffa500", "#fd7e14":
            return .orange
        case "purple", "#800080", "#6f42c1":
            return .purple
        default:
            // Try to parse hex color if it's a hex string
            if team.color.hasPrefix("#") {
                return Color(hex: team.color) ?? .gray
            }
            return .gray
        }
    }
    
    // Helper to zoom map to fit gyms + user location
    func zoomToFitAllAnnotations() {
        var coordinates: [CLLocationCoordinate2D] = gymRepository.gyms.map { gym in
            CLLocationCoordinate2D(latitude: gym.location.lat, longitude: gym.location.lon)
        }
        
        if let userLoc = locationManager.userLocation {
            coordinates.append(userLoc)
        }

        guard !coordinates.isEmpty else { return }

        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }

        let minLat = latitudes.min()!
        let maxLat = latitudes.max()!
        let minLon = longitudes.min()!
        let maxLon = longitudes.max()!

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        // Add padding around the annotations
        let latDelta = max(0.01, (maxLat - minLat) * 1.2)
        let lonDelta = max(0.01, (maxLon - minLon) * 1.2)

        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        let region = MKCoordinateRegion(center: center, span: span)

        withAnimation(.easeInOut(duration: 1.0)) {
            cameraPosition = .region(region)
        }
    }
    
    var homeButton: some View {
        Button {
            zoomToFitAllAnnotations()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "house.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .medium))
                Text("Home")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .padding(12)
            .background(Color.blue)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .padding(.leading, 20)
        .padding(.bottom, 100)
    }
}

struct PulsingDot: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue)
                .frame(width: 20, height: 20)
            
            Circle()
                .stroke(Color.blue, lineWidth: 2)
                .frame(width: 20, height: 20)
                .scaleEffect(isAnimating ? 2 : 1)
                .opacity(isAnimating ? 0 : 1)
                .animation(
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    HeatmapView()
}
