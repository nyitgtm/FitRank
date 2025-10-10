import SwiftUI
import AVFoundation
import FirebaseAuth

struct UploadView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @StateObject private var userViewModel = UserViewModel()
    @StateObject private var gymRepository = GymRepository()
    
    @State private var videoURL: URL?
    @State private var selectedLiftType: LiftType = .bench
    @State private var selectedGym: String?
    @State private var showingCamera = false
    @State private var showingVideoPicker = false
    @State private var showingGymPicker = false
    @State private var showingSuccessAlert = false
    @State private var motivationalTip = ""
    
    // Plate counter state
    @State private var plate45Count = 0
    @State private var plate25Count = 0
    @State private var plate10Count = 0
    @State private var plate5Count = 0
    @State private var plate2_5Count = 0
    
    let motivationalTips = [
        "Don't hurt yourself! Safety first always 💪",
        "Practice proper form before adding weight 🎯",
        "Remember: form > ego every single time 🏋️",
        "Progressive overload is key to gains 📈",
        "Rest days are just as important as training days 😴",
        "Consistency beats intensity in the long run 🔥",
        "Hydrate! Your muscles will thank you 💧",
        "Focus on the mind-muscle connection 🧠",
        "Every rep counts - make them quality reps ✨"
    ]
    
    private var totalWeight: Int {
        let barbellWeight = 45
        let platesPerSide = (plate45Count * 45) + (plate25Count * 25) + (plate10Count * 10) + (plate5Count * 5) + (plate2_5Count * 2)
        return barbellWeight + (platesPerSide * 2) // Both sides
    }
    
    private var canUpload: Bool {
        videoURL != nil && totalWeight > 0 && selectedGym != nil && !workoutViewModel.isLoading
    }
    
    private var closestGym: (name: String, id: String)? {
        // For now, return first gym. You can implement distance calculation here
        if let firstGym = gymRepository.gyms.first {
            return (name: firstGym.name, id: firstGym.id ?? "")
        }
        return nil
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Video Upload Section
                    VideoUploadSection(
                        videoURL: $videoURL,
                        showingCamera: $showingCamera,
                        showingVideoPicker: $showingVideoPicker
                    )
                    
                    // Weight Plate Calculator
                    WeightPlateCalculator(
                        plate45: $plate45Count,
                        plate25: $plate25Count,
                        plate10: $plate10Count,
                        plate5: $plate5Count,
                        plate2_5: $plate2_5Count,
                        totalWeight: totalWeight
                    )
                    
                    // Lift Type Selector
                    LiftTypeSelector(selectedLiftType: $selectedLiftType)
                    
                    // Gym Selector
                    GymSelector(
                        selectedGym: $selectedGym,
                        closestGym: closestGym,
                        showingGymPicker: $showingGymPicker
                    )
                    
                    // Upload Button
                    ModernUploadButton(
                        canUpload: canUpload,
                        isLoading: workoutViewModel.isLoading,
                        onUpload: uploadWorkout
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Upload Workout")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(videoURL: $videoURL)
        }
        .sheet(isPresented: $showingVideoPicker) {
            VideoPickerView(videoURL: $videoURL)
        }
        .sheet(isPresented: $showingGymPicker) {
            GymPickerSheet(
                gyms: gymRepository.gyms,
                selectedGym: $selectedGym
            )
        }
        .alert("Workout Posted! 🎉", isPresented: $showingSuccessAlert) {
            Button("Awesome!") {
                dismiss()
            }
        } message: {
            Text(motivationalTip)
        }
        .task {
            await gymRepository.fetchGyms()
            // Set closest gym as default
            if let closest = closestGym {
                selectedGym = closest.id
            }
        }
    }
    
    private func uploadWorkout() {
        guard let videoURL = videoURL,
              let gymId = selectedGym,
              let userId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            await workoutViewModel.createWorkout(
                weight: totalWeight,
                liftType: selectedLiftType.displayName,
                gymId: gymId,
                videoURL: videoURL
            )
            
            // Show success with random tip
            motivationalTip = motivationalTips.randomElement() ?? motivationalTips[0]
            showingSuccessAlert = true
        }
    }
}

// MARK: - Video Upload Section
struct VideoUploadSection: View {
    @Binding var videoURL: URL?
    @Binding var showingCamera: Bool
    @Binding var showingVideoPicker: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            if let videoURL = videoURL {
                // Video preview
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemGray6))
                    
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        
                        Text("Video Ready!")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text(videoURL.lastPathComponent)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(height: 180)
            } else {
                // Upload options
                VStack(spacing: 16) {
                    Text("Choose Video Source")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 16) {
                        // Record button
                        Button {
                            showingCamera = true
                        } label: {
                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(
                                            colors: [.red, .pink],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .frame(width: 70, height: 70)
                                    
                                    Image(systemName: "video.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                }
                                
                                Text("Record")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        // Choose from library button
                        Button {
                            showingVideoPicker = true
                        } label: {
                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .frame(width: 70, height: 70)
                                    
                                    Image(systemName: "photo.on.rectangle")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                }
                                
                                Text("Camera Roll")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
                .frame(height: 180)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }
}

// MARK: - Weight Plate Calculator
struct WeightPlateCalculator: View {
    @Binding var plate45: Int
    @Binding var plate25: Int
    @Binding var plate10: Int
    @Binding var plate5: Int
    @Binding var plate2_5: Int
    let totalWeight: Int
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with total weight
            HStack {
                Text("Weight")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(totalWeight) lbs")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            
            // Barbell visualization
            BarbellVisualization(
                plate45: plate45,
                plate25: plate25,
                plate10: plate10,
                plate5: plate5,
                plate2_5: plate2_5
            )
            
            Divider()
            
            // Plate selectors
            VStack(spacing: 12) {
                PlateRow(weight: 45, count: $plate45, color: .red)
                PlateRow(weight: 25, count: $plate25, color: .green)
                PlateRow(weight: 10, count: $plate10, color: .blue)
                PlateRow(weight: 5, count: $plate5, color: .orange)
                PlateRow(weight: 2.5, count: $plate2_5, color: .gray)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }
}

struct BarbellVisualization: View {
    let plate45: Int
    let plate25: Int
    let plate10: Int
    let plate5: Int
    let plate2_5: Int
    
    var body: some View {
        HStack(spacing: 2) {
            // Left side plates
            PlateStack(
                plate45: plate45,
                plate25: plate25,
                plate10: plate10,
                plate5: plate5,
                plate2_5: plate2_5
            )
            
            // Barbell
            Rectangle()
                .fill(Color.gray)
                .frame(height: 8)
            
            // Right side plates (mirrored)
            PlateStack(
                plate45: plate45,
                plate25: plate25,
                plate10: plate10,
                plate5: plate5,
                plate2_5: plate2_5
            )
            .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        }
        .frame(height: 60)
    }
}

struct PlateStack: View {
    let plate45: Int
    let plate25: Int
    let plate10: Int
    let plate5: Int
    let plate2_5: Int
    
    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<plate45, id: \.self) { _ in
                PlateShape(color: .red, height: 55)
            }
            ForEach(0..<plate25, id: \.self) { _ in
                PlateShape(color: .green, height: 50)
            }
            ForEach(0..<plate10, id: \.self) { _ in
                PlateShape(color: .blue, height: 45)
            }
            ForEach(0..<plate5, id: \.self) { _ in
                PlateShape(color: .orange, height: 40)
            }
            ForEach(0..<plate2_5, id: \.self) { _ in
                PlateShape(color: .gray, height: 35)
            }
        }
    }
}

struct PlateShape: View {
    let color: Color
    let height: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(color)
            .frame(width: 8, height: height)
    }
}

struct PlateRow: View {
    let weight: Double
    @Binding var count: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // Plate icon
            Circle()
                .fill(color)
                .frame(width: 40, height: 40)
                .overlay(
                    Text("\(Int(weight))")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            Text("\(Int(weight)) lb plate")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            // Counter controls
            HStack(spacing: 16) {
                Button {
                    if count > 0 {
                        count -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(count > 0 ? color : .gray)
                }
                .disabled(count == 0)
                
                Text("\(count)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .frame(minWidth: 30)
                
                Button {
                    count += 1
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(color)
                }
            }
        }
    }
}

// MARK: - Lift Type Selector
struct LiftTypeSelector: View {
    @Binding var selectedLiftType: LiftType
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Exercise Type")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                ForEach([LiftType.bench, LiftType.squat, LiftType.deadlift], id: \.self) { liftType in
                    LiftTypeButton(
                        liftType: liftType,
                        isSelected: selectedLiftType == liftType
                    ) {
                        selectedLiftType = liftType
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }
}

struct LiftTypeButton: View {
    let liftType: LiftType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue : Color(.systemGray6))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: liftType.icon)
                        .font(.system(size: 30))
                        .foregroundColor(isSelected ? .white : .gray)
                }
                
                Text(liftType.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Gym Selector
struct GymSelector: View {
    @Binding var selectedGym: String?
    let closestGym: (name: String, id: String)?
    @Binding var showingGymPicker: Bool
    
    var body: some View {
        Button {
            showingGymPicker = true
        } label: {
            VStack(spacing: 12) {
                HStack {
                    Text("Gym Location")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if let gym = closestGym {
                            Text(gym.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("Closest to you")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Select a gym")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
            }
            .padding(20)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
        }
    }
}

// MARK: - Modern Upload Button
struct ModernUploadButton: View {
    let canUpload: Bool
    let isLoading: Bool
    let onUpload: () -> Void
    
    var body: some View {
        Button(action: onUpload) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: canUpload ? "arrow.up.circle.fill" : "lock.fill")
                        .font(.title3)
                }
                
                Text(isLoading ? "Posting..." : canUpload ? "Post Workout" : "Complete All Fields")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: canUpload ? [.blue, .purple] : [.gray, .gray],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: canUpload ? .blue.opacity(0.3) : .clear, radius: 15, y: 8)
        }
        .disabled(!canUpload || isLoading)
        .animation(.easeInOut(duration: 0.2), value: canUpload)
    }
}

// MARK: - Gym Picker Sheet
struct GymPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let gyms: [Gym]
    @Binding var selectedGym: String?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(gyms) { gym in
                    Button {
                        selectedGym = gym.id
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(gym.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                if let address = gym.location.address {
                                    Text(address)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if selectedGym == gym.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Gym")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Camera & Video Picker (Mock)
struct CameraView: View {
    @Binding var videoURL: URL?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                Image(systemName: "video.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.red)
                
                Text("Camera Recording")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("In production, this would open the camera to record your workout")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                Button {
                    videoURL = URL(string: "https://example.com/mock-video.mp4")
                    dismiss()
                } label: {
                    Text("Use Mock Video")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
            .navigationTitle("Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct VideoPickerView: View {
    @Binding var videoURL: URL?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Choose Video")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("In production, this would open your camera roll to select a video")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                Button {
                    videoURL = URL(string: "https://example.com/mock-video.mp4")
                    dismiss()
                } label: {
                    Text("Use Mock Video")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
            .navigationTitle("Camera Roll")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    UploadView()
}
