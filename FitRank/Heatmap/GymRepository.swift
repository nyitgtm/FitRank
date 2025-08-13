import Foundation
import CoreLocation

@MainActor
class GymRepository: ObservableObject {
    @Published var gyms: [Gym] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Mock Data for Development
    
    private func generateMockGyms() -> [Gym] {
        return [
            Gym(
                id: "gIlZvXqqfaj3qdCfAUns",
                name: "Aneva",
                location: Location(
                    address: "24-09 41st Ave, Long Island City, NY 11101",
                    lat: 40.75266615909022,
                    lon: -73.93922240996022
                ),
                bestSquatId: "/workouts/0",
                bestBenchId: "/workouts/0",
                bestDeadliftId: "/workouts/0",
                ownerTeamId: "/teams/0"
            )
        ]
    }
    
    func fetchGyms() {
        isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.gyms = self.generateMockGyms()
            self.isLoading = false
        }
    }
}



