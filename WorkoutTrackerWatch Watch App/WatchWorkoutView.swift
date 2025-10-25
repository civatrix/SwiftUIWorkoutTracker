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
    @State private var restTime: Int?
    @State private var forceHide = false
    
    var body: some View {
        if viewModel.workoutData.isEmpty {
            Text("Waiting for phone to start workout...")
        } else {
            VStack(alignment: .leading) {
                HStack {
                    Text(workoutManager.heartRate.formatted(.number.precision(.fractionLength(0))) + " bpm")
                        .font(.title)
                        .foregroundStyle(Color.red)
                    
//                    if let restTime {
//                        Spacer()
//                        
//                        Text("\(restTime)")
//                            .foregroundStyle(Color.black)
//                            .padding()
//                            .background(Color.purple)
//                            .clipShape(Circle())
//                            .frame(width: 35, height: 35)
//                    }
                }
            
                if viewModel.workoutData.indices.contains(viewModel.activeSet) {
                    if !forceHide {
                        let exercise = viewModel.workoutData[viewModel.activeSet]
                        WatchExerciseRow(title: exercise.name, setNumber: exercise.setNumber, unit: exercise.unit, range: exercise.repRange, value: $initialReps) {
                            connectivityManager.sendWorkoutData(exercise: exercise, completedReps: $0)
                            viewModel.activeSet += 1
                        }
                        .onChange(of: viewModel.activeSet) {
                            let workout = viewModel.workoutData[viewModel.activeSet]
                            initialReps = workout.completedReps ?? workout.repRange.upperBound
                            restTime = 30
                            forceHide = true
                        }
//                        .onChange(of: viewModel.elapsedTime) {
//                            guard let restTime else { return }
//                            if restTime == 0 {
//                                self.restTime = nil
//                                WKInterfaceDevice.current().play(.success)
//                            } else {
//                                self.restTime = restTime - 1
//                            }
//                        }
                        .onAppear {
                            let workout = viewModel.workoutData[viewModel.activeSet]
                            initialReps = workout.completedReps ?? workout.repRange.upperBound
                            workoutManager.startWorkout()
                        }
                    } else {
                        Color.clear.onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.001) {
                                forceHide = false
                            }
                        }
                    }
                } else {
                    Text("All exercises complete!")
                        .lineLimit(nil)
                        .font(.largeTitle)
                    
                    Button("Complete") {
                        workoutManager.completeWorkout()
                        viewModel.complete()
                    }
                }
            }
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
