// Heatmap.swift
import SwiftUI
import MapKit
import CoreLocation

// Color extension to handle hex colors
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
        requestLocationPermission()
    }

    func requestLocationPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.userLocation = location.coordinate
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.startUpdatingLocation()
            case .denied, .restricted:
                print("Location access denied")
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            @unknown default:
                break
            }
        }
    }
}

// Pulsing animation for user location dot
struct PulsingDot: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 40, height: 40)
                .scaleEffect(animate ? 1.5 : 1)
                .opacity(animate ? 0 : 0.3)
                .animation(.easeOut(duration: 1).repeatForever(autoreverses: false), value: animate)

            Circle()
                .fill(Color.blue)
                .frame(width: 12, height: 12)
        }
        .onAppear {
            animate = true
        }
    }
}

struct Heatmap: View {
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.7282, longitude: -73.7949),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )

    @StateObject private var locationManager = LocationManager()
    @StateObject private var gymRepository = GymRepository()
    @State private var currentZoomLevel: Double = 0.05 // Track zoom level
    
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

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            mapView
            
            VStack {
                if gymRepository.isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading gyms...")
                            .font(.caption)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .padding(.top, 60)
                }
                
                Spacer()
                
                HStack {
                    homeButton
                    Spacer()
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
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
        .onMapCameraChange(frequency: .continuous) { context in
            // Update zoom level for conditional rendering
            currentZoomLevel = max(context.region.span.latitudeDelta, context.region.span.longitudeDelta)
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

    var mapView: some View {
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
                           teamId != "teams/0", // Exclude default/unowned
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

#Preview {
    Heatmap()
}
