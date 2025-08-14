import SwiftUI

struct GymPickerView: View {
    @Binding var selectedGym: String
    
    // Mock gyms for development
    private let gyms = [
        ("gIlZvXqqfaj3qdCfAUns", "Aneva"),
        ("gym2", "Gold's Gym"),
        ("gym3", "Planet Fitness"),
        ("gym4", "LA Fitness")
    ]
    
    var body: some View {
        Menu {
            ForEach(gyms, id: \.0) { gym in
                Button(gym.1) {
                    selectedGym = gym.0
                }
            }
        } label: {
            HStack {
                Text(gyms.first { $0.0 == selectedGym }?.1 ?? "Select Gym")
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

#Preview {
    GymPickerView(selectedGym: .constant("gIlZvXqqfaj3qdCfAUns"))
}

