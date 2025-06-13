//
//  HomePage.swift
//  FitRank
//
//  Created by Navraj Singh on 6/8/25.
//

import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    func logOut() throws {
        try AuthenticationManager.shared.signOut()
    }
}

struct IconBarView: View {
    //search up the icons here https://hotpot.ai/free-icons
    // I put random placeholders for now, but we can change it
    // also lets switch the order and stuff just in case idk
    let icons = ["house.fill", "map.fill", "plus.circle.fill", "camera.fill", "person.fill"]

    var body: some View {
        HStack {
            ForEach(icons, id: \.self) { icon in
                Spacer() // Pushes icons apart evenly
                
                Image(systemName: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30) // frontend team adjust size here
                    .foregroundColor(.black) // style the icons idk
                    .onTapGesture {
                        //idk maybe we can incorperate something here / just throwing ideas
                    }
                
                Spacer() // Pushes icons apart evenly
            }
        }
        .padding(.vertical, 10) // Adds some vertical breathing room
        .background(Color.gray.opacity(0.1)) // Optional: Add background color
    }
}


struct HomePage: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Binding var showSignInView: Bool
    var body: some View {
        Text("HOMEPAGE")
        .padding()
        
        Image(systemName: "gear")
            .frame(width: 30, height: 30)
            .onTapGesture {
                //send to settings page
            }
        
        List {
            //This button is just for test env / we will make settings page soon
            Button("Log Out") {
                Task {
                    do {
                        try viewModel.logOut()
                        showSignInView = true
                    } catch {
                        print(error)
                        //Handle this in the future thanks nav
                    }
                }
            }
        }
        
        Spacer()
        
        
        IconBarView() // keeping things modular for future merge conflicts
    }
}

#Preview {
    HomePage(showSignInView: .constant(false))
}
