import SwiftUI
import MapKit
import CoreLocation

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





//WHY DOESNT IT ANIMATE :(
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
        //i just made it spawn in middle of queens but idk if this is subject to change
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.7282, longitude: -73.7949),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.1)
        )
    )

    @StateObject private var locationManager = LocationManager()

    let queensBounds = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7282, longitude: -73.7949),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    
    
    
    //just hardcoded for now but we have to integrate api or pull from database all gyms lat/long
    var gymMapItems: [MKMapItem] {
        let gymCoordinatesAndNames: [(CLLocationCoordinate2D, String)] = [
            (CLLocationCoordinate2D(latitude: 40.7282, longitude: -73.7949), "Blink"),
            (CLLocationCoordinate2D(latitude: 40.7412, longitude: -73.8203), "LA Fitness"),
            (CLLocationCoordinate2D(latitude: 40.7058, longitude: -73.8151), "Crunch"),
            (CLLocationCoordinate2D(latitude: 40.7498, longitude: -73.7976), "Gold's Gym")
        ]

        return gymCoordinatesAndNames.map { coord, name in
            let item = MKMapItem(placemark: MKPlacemark(coordinate: coord))
            item.name = name
            return item
        }
    }

    
    //Dont know why the user's location aint popping up?
    var userMapItem: MKMapItem? {
        guard let userLoc = locationManager.userLocation else { return nil }
        return MKMapItem(placemark: MKPlacemark(coordinate: userLoc))
    }

    
    
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            mapView
            homeButton
        }
        .edgesIgnoringSafeArea(.all)
        .onChange(of: cameraPosition) {
            enforceQueensBounds()
        }
        .onAppear {
            locationManager.requestLocationPermission() //maybe location doesnt pop up bc its simulation?
        }
    }
    
    

    var mapView: some View {
        Map(position: $cameraPosition) {
            ForEach(gymMapItems, id: \.self) { mapItem in
                Annotation(item: mapItem) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .shadow(color: .red, radius: 8)
                }
            }

            if let userItem = userMapItem {
                Annotation(item: userItem) {
                    PulsingDot()
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic, emphasis: .muted))
    }

    
    
    
    

    // Dont know why the homebutton not working????
    var homeButton: some View {
        Button {
            if let userLoc = locationManager.userLocation {
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: userLoc,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )
                )
            }
        } label: {
            Image(systemName: "house.fill")
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(radius: 4)
        }
        .padding(.leading, 20)
        .padding(.bottom, 40)
    }

    
    
    
    // We gotta fix this so maybe have to hardcode it. bc i tried to make it a mathematical formula but i forgot the earth is round so dont really work.. :\
    private func enforceQueensBounds() {
        guard let region = cameraPosition.region else { return }

        let lat = region.center.latitude
        let lon = region.center.longitude

        let minLat = queensBounds.center.latitude - queensBounds.span.latitudeDelta / 2
        let maxLat = queensBounds.center.latitude + queensBounds.span.latitudeDelta / 2
        let minLon = queensBounds.center.longitude - queensBounds.span.longitudeDelta / 2
        let maxLon = queensBounds.center.longitude + queensBounds.span.longitudeDelta / 2

        if !(minLat...maxLat).contains(lat) || !(minLon...maxLon).contains(lon) {
            cameraPosition = .region(queensBounds)
        }
    }



}

#Preview {
    Heatmap()
}
