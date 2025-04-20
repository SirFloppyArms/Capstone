//
//  CapstoneApp.swift
//  Capstone
//
//  Created by Nolan Law on 2025-04-11.
//

import SwiftUI
import Firebase

@main
struct CapstoneApp: App {
    
    // Initialize Firebase when the app launches
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            AuthView() // Start with the auth view
        }
    }
}
