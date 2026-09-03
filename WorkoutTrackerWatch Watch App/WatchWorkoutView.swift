//
//  WatchWorkoutView.swift
//  WorkoutTrackerWatch Watch App
//
//  Created by Daniel Johns on 2025-03-22.
//

import SwiftUI
import SwiftData

struct WatchWorkoutView: View {
    @Environment(WatchViewModel.self) private var viewModel
    @Environment(WatchConnectivityManager.self) private var connectivityManager
    
    @State private var initialReps = 0
    @State private var showSalute = false
    
    var body: some View {
        if !viewModel.workoutData.isEmpty {
            VStack(alignment: .leading) {
                if viewModel.workoutData.indices.contains(viewModel.activeSet) {
                    let exercise = viewModel.workoutData[viewModel.activeSet]
                    HStack {
                        Text(viewModel.heartRate.formatted(.number.precision(.fractionLength(0))) + " bpm")
                            .font(.title)
                            .foregroundStyle(Color.red)
                        Spacer()
                        Text(exercise.setNumber)
                            .font(.fraction(.title3))
                    }
                    
                    WatchExerciseRow(title: exercise.name, unit: exercise.unit, range: exercise.repRange, value: $initialReps) {
                        showSalute = true
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
                    }
                    .overlay {
                        if showSalute {
                            Image(systemName: "checkmark.seal.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundStyle(Color.green)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .onAppear {
                                    withAnimation(Animation.spring.delay(0.25)) {
                                        self.showSalute = false
                                    }
                                }
                        }
                    }
                    .id(exercise.id)
                } else {
                    Text("Workout complete!")
                        .lineLimit(nil)
                        .font(.largeTitle)
                    
                    Button("Complete") {
                        showSalute = false
                        viewModel.complete()
                    }
                }
            }
        } else if !viewModel.templates.isEmpty {
            WatchWorkoutListView(viewModel: viewModel)
        } else {
            Text("Waiting for phone to send templates or start workout...")
        }
    }
}

#Preview {
    WatchWorkoutView()
        .environment(WatchViewModel.preview)
        .environment(WatchConnectivityManager())
        .tint(Color.purple)
}
