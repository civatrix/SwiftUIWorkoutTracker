//
//  WatchWorkoutView.swift
//  WorkoutTrackerWatch Watch App
//
//  Created by Daniel Johns on 2025-03-22.
//

import SwiftUI
import SwiftData

struct WatchWorkoutView: View {
    @EnvironmentObject private var viewModel: WatchViewModel
    @EnvironmentObject private var connectivityManager: WatchConnectivityManager
    @EnvironmentObject private var workoutManager: WorkoutManager
    @State private var initialReps = 0
    
    var body: some View {
        if !viewModel.workoutData.isEmpty {
            VStack(alignment: .leading) {
                HStack {
                    Text(workoutManager.heartRate.formatted(.number.precision(.fractionLength(0))) + " bpm")
                        .font(.title)
                        .foregroundStyle(Color.red)
                }
            
                if viewModel.workoutData.indices.contains(viewModel.activeSet) {
                    let exercise = viewModel.workoutData[viewModel.activeSet]
                    WatchExerciseRow(title: exercise.name, setNumber: exercise.setNumber, unit: exercise.unit, range: exercise.repRange, value: $initialReps) {
                        connectivityManager.sendWorkoutData(exercise: exercise, completedReps: $0, templateName: viewModel.templateName)
                        viewModel.activeSet += 1
                    }
                    .onChange(of: viewModel.activeSet) {
                        let workout = viewModel.workoutData[viewModel.activeSet]
                        initialReps = workout.completedReps ?? workout.repRange.upperBound
                    }
                    .onAppear {
                        let workout = viewModel.workoutData[viewModel.activeSet]
                        initialReps = workout.completedReps ?? workout.repRange.upperBound
                        workoutManager.startWorkout()
                    }
                    .id(exercise.id)
                } else {
                    Text("All exercises complete!")
                        .lineLimit(nil)
                        .font(.largeTitle)
                    
                    Button("Complete") {
                        connectivityManager.flushCache(templateName: viewModel.templateName)
                        workoutManager.completeWorkout()
                        viewModel.complete()
                    }
                }
            }
        } else if !viewModel.templates.isEmpty {
            List(viewModel.templates, id: \.self) { template in
                Button(template.name) {
                    viewModel.start(template: template)
                }
            }
        } else {
            Text("Waiting for phone to send templates or start workout...")
        }
    }
}

#Preview {
    WatchWorkoutView()
        .environmentObject(WatchViewModel.preview)
        .environmentObject(WatchConnectivityManager())
        .environmentObject(WorkoutManager())
        .tint(Color.purple)
}
