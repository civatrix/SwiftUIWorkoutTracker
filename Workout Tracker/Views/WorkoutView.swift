//
//  WorkoutView.swift
//  Workout Tracker
//
//  Created by Daniel Johns on 2025-01-24.
//

import SwiftUI
import SwiftData
import ActivityKit

struct WorkoutView: View {
    init(template: WorkoutTemplate) {
        self.template = template
        self.workout = template.newWorkout()
    }
    
    init(workout: Workout) {
        self.workout = workout
        self.template = nil
    }
    
    @EnvironmentObject private var navigationManager: NavigationManager
    @Environment(\.modelContext) private var modelContext
    @State private var workout: Workout
    @State private var hasAppeared = false
    
    @State private var activeExercise: Exercise?
    @State private var activeSet: Int?
    
    let template: WorkoutTemplate?
    
    var body: some View {
        if hasAppeared {
            ScrollViewReader { value in
                ScrollView {
                    VStack {
                        Text(workout.name)
                            .font(.title)
                        
                        ForEach($workout.exercises) { $exercise in
                            ExerciseRow(exercise: $exercise, activeSet: activeExercise == exercise ? activeSet : nil) {
                                activeExercise = exercise
                                activeSet = $0
                            }
                            .id(exercise)
                        }
                    }
                    .padding()
                }
                .onChange(of: activeExercise) {
                    withAnimation {
                        value.scrollTo(activeExercise)
                    }
                    guard let activeExercise, let activeSet else {
                        return
                    }
                    PhoneConnectivityManager.shared.sendActiveSet(activeExercise, activeSet)
                }
                .onChange(of: activeSet) {
                    guard let activeExercise, let activeSet else {
                        return
                    }
                    PhoneConnectivityManager.shared.sendActiveSet(activeExercise, activeSet)
                }
            }
            
            if let activeExercise, let activeSet {
                let title = "\(activeExercise.longName) - Set \(activeSet + 1)"
                RepButtons(title: title, repRange: activeExercise.repRange) {
                    self.activeExercise?.repsCompleted[activeSet] = $0
                    self.activeSet = activeSet + 1
                    self.updateActives()
                }
                .padding([.leading, .trailing])
            }
            
            Button("Complete Workout", action: completeWorkout)
                .disabled(!workout.allComplete)
        } else {
            Color.clear
                .onAppear() {
                    guard !hasAppeared else { return }
                    
                    hasAppeared = true
                    modelContext.insert(workout)
                    try! modelContext.save()
                    activeExercise = workout.exercises.first { !$0.allComplete }
                    activeSet = activeExercise?.repsCompleted.firstIndex(of: nil)
                    
                    PhoneConnectivityManager.shared.sendWorkout(workout)
                }
        }
    }
    
    private func updateActives() {
        guard let activeExercise, let activeSet else {
            return
        }
        guard activeSet == activeExercise.repsCompleted.count else {
            return
        }
        
        self.activeSet = 0
        guard let currentIndex = workout.exercises.firstIndex(of: activeExercise),
              currentIndex + 1 < workout.exercises.count else {
            self.activeSet = nil
            self.activeExercise = nil
            return
        }
        
        self.activeExercise = workout.exercises[currentIndex + 1]
    }
    
    private func completeWorkout() {
        withAnimation {
            navigationManager.goHome()
        }
    }
}

#Preview {
    WorkoutView(template: .preview)
        .modelContainer(ModelContainer.preview)
        .tint(Color.purple)
}
