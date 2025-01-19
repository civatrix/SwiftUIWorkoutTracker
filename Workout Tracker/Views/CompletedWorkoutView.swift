//
//  CompletedWorkoutView.swift
//  Workout Tracker
//
//  Created by Daniel Johns on 2025-01-19.
//

import SwiftUI

struct CompletedWorkoutView: View {
    @State var workout: Workout
    
    var body: some View {
        Text(workout.name)
    }
}

#Preview {
    return CompletedWorkoutView(workout: Workout(name: "Workout", date: Date(), exercises: []))
}
