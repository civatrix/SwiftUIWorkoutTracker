//
//  ModelContainer.swift
//  Workout Tracker
//
//  Created by Daniel Johns on 2025-03-23.
//

import SwiftData

extension ModelContainer {
    
    static let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WorkoutTemplate.self,
            Workout.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}
