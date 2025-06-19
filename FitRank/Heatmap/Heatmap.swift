//
//  Heatmap.swift
//  FitRank
//
//  Created by Navraj Singh on 6/19/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct Heatmap: View {
    @State private var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.7282, longitude: -73.7949), // Queens, NY
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05) // Zoom level
        )
    )
    
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        Map(position: $cameraPosition) {
            // Custom pulsing dot if user location is available
            if let userLocation = locationManager.userLocation {
                Annotation("", coordinate: userLocation) {
                    PulsingDot()
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            locationManager.requestLocationPermission()
        }
    }
}

struct PulsingDot: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 40, height: 40)
                .scaleEffect(animate ? 1.5 : 1)
                .opacity(animate ? 0 : 0.3)
                .animation(Animation.easeOut(duration: 1).repeatForever(autoreverses: false), value: animate)

            Circle()
                .fill(Color.blue)
                .frame(width: 12, height: 12)
        }
        .onAppear {
            animate = true
        }
    }
}

// Location Manager to track user location
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var userLocation: CLLocationCoordinate2D?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.startUpdatingLocation()
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
}

#Preview {
    Heatmap()
}

