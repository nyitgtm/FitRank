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
                    ForEach(gymRepository.gyms, id: \.id) { gym in
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
                                   teamId != "/teams/0", // Exclude default/unowned
                                   let team = Team.allCases.first(where: { "/teams/\($0.rawValue)" == teamId }) {
                                    Text("Owned by \(team.displayName)")
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
                
                // Home button
                VStack {
                    Spacer()
                    HStack {
                        homeButton
                        Spacer()
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)
            .navigationTitle("Heatmap")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                locationManager.requestLocationPermission()
                gymRepository.fetchGyms()
            }
            .onChange(of: gymRepository.gyms.count) {
                // Auto-zoom when gyms are loaded
                if !gymRepository.gyms.isEmpty {
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
        guard let teamId = teamId else { return .gray }
        
        // Use the Team enum from User.swift to get team colors
        if let team = Team.allCases.first(where: { "/teams/\($0.rawValue)" == teamId }) {
            return Color(hex: team.color) ?? .gray
        }
        
        return .gray
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
            Image(systemName: "house.fill")
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .medium))
                .padding(12)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .padding(.leading, 20)
        .padding(.bottom, 40)
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
