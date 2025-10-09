//
//  ThemeManager.swift
//  FitRank
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var isDarkMode: Bool = false {
        didSet {
            // Save to UserDefaults for immediate persistence
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
            // Sync to Firebase
            syncToFirebase()
        }
    }
    
    private let db = Firestore.firestore()
    
    private init() {
        // Load from UserDefaults first for immediate app launch
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        // Then load from Firebase to get synced value
        loadFromFirebase()
    }
    
    var colorScheme: ColorScheme {
        isDarkMode ? .dark : .light
    }
    
    // Load dark mode preference from Firebase
    func loadFromFirebase() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Error loading dark mode from Firebase: \(error.localizedDescription)")
                return
            }
            
            if let data = snapshot?.data(),
               let isDarkMode = data["isDarkMode"] as? Bool {
                DispatchQueue.main.async {
                    self.isDarkMode = isDarkMode
                    print("✅ Loaded dark mode from Firebase: \(isDarkMode)")
                }
            }
        }
    }
    
    // Save dark mode preference to Firebase
    private func syncToFirebase() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(uid).updateData([
            "isDarkMode": isDarkMode
        ]) { error in
            if let error = error {
                print("❌ Error syncing dark mode to Firebase: \(error.localizedDescription)")
            } else {
                print("✅ Dark mode synced to Firebase: \(self.isDarkMode)")
            }
        }
    }
}
