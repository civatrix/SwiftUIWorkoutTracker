//
//  Workout_TrackerApp.swift
//  Workout Tracker
//
//  Created by Daniel Johns on 2025-01-19.
//

import SwiftUI
import SwiftData

@main
struct Workout_TrackerApp: App {    
    var body: some Scene {
        WindowGroup {
            WorkoutListView()
                .tint(Color.purple)
        }
        .modelContainer(.sharedModelContainer)
    }
}
