//
//  CameraRecorder.swift
//  FitRank
//
//  Camera recorder with 30 second limit
//

import SwiftUI
import AVFoundation

struct CameraRecorder: UIViewControllerRepresentable {
    @Binding var videoURL: URL?
    @Binding var showError: Bool
    @Binding var errorMessage: String
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CameraViewControllerDelegate {
        let parent: CameraRecorder
        
        init(_ parent: CameraRecorder) {
            self.parent = parent
        }
        
        func didFinishRecording(videoURL: URL) {
            parent.videoURL = videoURL
        }
        
        func didFailWithError(_ error: String) {
            parent.errorMessage = error
            parent.showError = true
        }
        
        func didCancel() {
            // Just dismiss, no action needed
        }
    }
}

protocol CameraViewControllerDelegate: AnyObject {
    func didFinishRecording(videoURL: URL)
    func didFailWithError(_ error: String)
    func didCancel()
}

class CameraViewController: UIViewController {
    weak var delegate: CameraViewControllerDelegate?
    
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureMovieFileOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var recordingTimer: Timer?
    private var recordingDuration: TimeInterval = 0
    private let maxDuration: TimeInterval = 30.0
    
    private let recordButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .systemRed
        button.layer.cornerRadius = 40
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let timerLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .monospacedDigitSystemFont(ofSize: 20, weight: .bold)
        label.text = "00:00"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        label.textAlignment = .center
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        return label
    }()
    
    private var isRecording = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
        setupUI()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopSession()
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .high
        
        guard let captureSession = captureSession else { return }
        
        // Add video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoInput) else {
            delegate?.didFailWithError("Camera not available")
            return
        }
        
        captureSession.addInput(videoInput)
        
        // Add audio input
        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           captureSession.canAddInput(audioInput) {
            captureSession.addInput(audioInput)
        }
        
        // Add video output
        videoOutput = AVCaptureMovieFileOutput()
        if let videoOutput = videoOutput, captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
            
            // Set max duration
            videoOutput.maxRecordedDuration = CMTime(seconds: maxDuration, preferredTimescale: 600)
        }
        
        // Setup preview
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.bounds
        
        if let previewLayer = previewLayer {
            view.layer.addSublayer(previewLayer)
        }
        
        // Start session
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
    }
    
    private func setupUI() {
        view.addSubview(recordButton)
        view.addSubview(cancelButton)
        view.addSubview(timerLabel)
        
        NSLayoutConstraint.activate([
            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            recordButton.widthAnchor.constraint(equalToConstant: 80),
            recordButton.heightAnchor.constraint(equalToConstant: 80),
            
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            
            timerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timerLabel.widthAnchor.constraint(equalToConstant: 80),
            timerLabel.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        recordButton.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    @objc private func recordButtonTapped() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    @objc private func cancelButtonTapped() {
        if isRecording {
            stopRecording()
        }
        delegate?.didCancel()
        dismiss(animated: true)
    }
    
    private func startRecording() {
        guard let videoOutput = videoOutput else { return }
        
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        
        videoOutput.startRecording(to: outputURL, recordingDelegate: self)
        
        isRecording = true
        recordButton.backgroundColor = .white
        recordingDuration = 0
        
        // Start timer
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.recordingDuration += 0.1
            self.updateTimerLabel()
            
            if self.recordingDuration >= self.maxDuration {
                self.stopRecording()
            }
        }
    }
    
    private func stopRecording() {
        videoOutput?.stopRecording()
        isRecording = false
        recordButton.backgroundColor = .systemRed
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    private func updateTimerLabel() {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
        
        // Change color when approaching limit
        if recordingDuration > maxDuration - 5 {
            timerLabel.textColor = .systemRed
        } else {
            timerLabel.textColor = .white
        }
    }
    
    private func stopSession() {
        captureSession?.stopRunning()
        captureSession = nil
    }
}

extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            delegate?.didFailWithError("Recording failed: \(error.localizedDescription)")
            return
        }
        
        // Validate video
        let asset = AVAsset(url: outputFileURL)
        let duration = CMTimeGetSeconds(asset.duration)
        
        if duration > maxDuration + 1 { // Allow 1 second buffer
            delegate?.didFailWithError("Video exceeds 30 second limit")
            try? FileManager.default.removeItem(at: outputFileURL)
            return
        }
        
        delegate?.didFinishRecording(videoURL: outputFileURL)
        dismiss(animated: true)
    }
}
