import SwiftUI
import AVFoundation

struct UploadView: View {
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @StateObject private var userViewModel = UserViewModel()
    @State private var weight = ""
    @State private var selectedLiftType = "Bench Press"
    @State private var selectedGym = "gIlZvXqqfaj3qdCfAUns"
    @State private var showingCamera = false
    @State private var showingImagePicker = false
    @State private var videoURL: URL?
    @State private var isRecording = false
    
    let liftTypes = ["Bench Press", "Squat", "Deadlift"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Video Section
                    VideoSectionView(
                        videoURL: $videoURL,
                        isRecording: $isRecording,
                        showingCamera: $showingCamera,
                        showingImagePicker: $showingImagePicker
                    )
                    
                    // Form Section
                    FormSectionView(
                        weight: $weight,
                        selectedLiftType: $selectedLiftType,
                        selectedGym: $selectedGym,
                        liftTypes: liftTypes
                    )
                    
                    // Upload Button
                    UploadButtonView(
                        weight: weight,
                        selectedLiftType: selectedLiftType,
                        selectedGym: selectedGym,
                        videoURL: videoURL,
                        isLoading: workoutViewModel.isLoading,
                        onUpload: uploadWorkout
                    )
                }
                .padding()
            }
            .navigationTitle("Upload Workout")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingCamera) {
                CameraView(videoURL: $videoURL)
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(videoURL: $videoURL)
            }
            .alert("Error", isPresented: .constant(workoutViewModel.errorMessage != nil)) {
                Button("OK") {
                    workoutViewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = workoutViewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    private func uploadWorkout() {
        guard let videoURL = videoURL,
              let weightInt = Int(weight),
              weightInt > 0 else { return }
        
        Task {
            await workoutViewModel.createWorkout(
                weight: weightInt,
                liftType: selectedLiftType,
                gymId: selectedGym,
                videoURL: videoURL
            )
        }
    }
}

struct VideoSectionView: View {
    @Binding var videoURL: URL?
    @Binding var isRecording: Bool
    @Binding var showingCamera: Bool
    @Binding var showingImagePicker: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Record Your Lift")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let videoURL = videoURL {
                // Video Preview
                VideoPlayerView(videoURL: videoURL)
                    .frame(height: 200)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            } else {
                // Camera Placeholder
                VStack(spacing: 12) {
                    Image(systemName: "video.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No video recorded")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            // Camera Controls
            HStack(spacing: 16) {
                Button {
                    showingCamera = true
                } label: {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Record")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                
                Button {
                    showingImagePicker = true
                } label: {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("Choose Video")
                    }
                    .foregroundColor(.blue)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

struct FormSectionView: View {
    @Binding var weight: String
    @Binding var selectedLiftType: String
    @Binding var selectedGym: String
    let liftTypes: [String]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Workout Details")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // Weight Input
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weight (lbs)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("Enter weight", text: $weight)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Lift Type Picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Lift Type")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("Lift Type", selection: $selectedLiftType) {
                        ForEach(liftTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                // Gym Picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gym")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    GymPickerView(selectedGym: $selectedGym)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

struct UploadButtonView: View {
    let weight: String
    let selectedLiftType: String
    let selectedGym: String
    let videoURL: URL?
    let isLoading: Bool
    let onUpload: () -> Void
    
    private var canUpload: Bool {
        !weight.isEmpty && 
        Int(weight) != nil && 
        Int(weight)! > 0 && 
        videoURL != nil && 
        !isLoading
    }
    
    var body: some View {
        Button(action: onUpload) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                }
                
                Text(isLoading ? "Uploading..." : "Upload Workout")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(canUpload ? Color.blue : Color.gray)
            .cornerRadius(12)
        }
        .disabled(!canUpload)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct VideoPlayerView: View {
    let videoURL: URL
    
    var body: some View {
        // For now, show a placeholder since we don't have actual video playback
        VStack {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("Video Ready")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGray6))
    }
}

struct CameraView: View {
    @Binding var videoURL: URL?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Camera View")
                    .font(.title)
                    .padding()
                
                Text("Video recording functionality would be implemented here")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button("Use Mock Video") {
                    // For development, create a mock video URL
                    videoURL = URL(string: "https://example.com/mock-video.mp4")
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .navigationTitle("Record Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ImagePicker: View {
    @Binding var videoURL: URL?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Video Picker")
                    .font(.title)
                    .padding()
                
                Text("Video selection functionality would be implemented here")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button("Use Mock Video") {
                    // For development, create a mock video URL
                    videoURL = URL(string: "https://example.com/mock-video.mp4")
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .navigationTitle("Choose Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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
