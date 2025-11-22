//
//  NavigationManager.swift
//  Workout Tracker
//
//  Created by Daniel Johns on 2025-01-24.
//

import Foundation
import SwiftUI

class NavigationManager: ObservableObject {
    enum ViewDestination: Hashable {
        case logs
        case completedWorkout(workout: Workout)
        case createWorkout
        case createWorkoutTemplate
        case editWorkoutTemplate(template: WorkoutTemplate)
        case startWorkout(template: WorkoutTemplate)
        case resumeWorkout(workout: Workout)
        func newView() -> some View {
            switch self {
            case .logs:
                AnyView(LogsView())
            case .completedWorkout(workout: let workout):
                AnyView(CompletedWorkoutView(workout: workout))
            case .createWorkout:
                AnyView(CreateWorkoutView())
            case .createWorkoutTemplate:
                AnyView(CreateWorkoutTemplateView())
            case .editWorkoutTemplate(template: let template):
                AnyView(CreateWorkoutTemplateView(template: template))
            case .startWorkout(template: let template):
                AnyView(WorkoutView(template: template))
            case .resumeWorkout(workout: let workout):
                AnyView(WorkoutView(workout: workout))
            }
        }
    }
    
    @Published var navigationStack = [ViewDestination]()
    func logsDestionation() -> ViewDestination {
        .logs
    }
    
    func goToLogs() {
        navigationStack.append(logsDestionation())
    }
    
    func completedWorkoutDestination(_ workout: Workout) -> ViewDestination {
        .completedWorkout(workout: workout)
    }
    
    func goToCompletedWorkout(_ workout: Workout) {
        navigationStack.append(completedWorkoutDestination(workout))
    }
    
    func createWorkoutDestination() -> ViewDestination {
        .createWorkout
    }
    
    func goToCreateWorkout() {
        navigationStack.append(createWorkoutDestination())
    }
    
    func createWorkoutTemplateDestination() -> ViewDestination {
        .createWorkoutTemplate
    }
    
    func goToCreateWorkoutTemplate() {
        navigationStack.append(createWorkoutTemplateDestination())
    }
    
    func editWorkoutTemplateDestination(_ template: WorkoutTemplate) -> ViewDestination {
        .editWorkoutTemplate(template: template)
    }
    
    func goToEditWorkoutTemplate(_ template: WorkoutTemplate) {
        navigationStack.append(editWorkoutTemplateDestination(template))
    }
    
    func startWorkoutDestination(_ template: WorkoutTemplate) -> ViewDestination {
        .startWorkout(template: template)
    }
    
    func goToStartWorkout(template: WorkoutTemplate) {
        navigationStack.append(startWorkoutDestination(template))
    }
    
    func resumeWorkoutDestination(_ workout: Workout) -> ViewDestination {
        .resumeWorkout(workout: workout)
    }
    
    func goToResumeWorkout(workout: Workout) {
        navigationStack.append(resumeWorkoutDestination(workout))
    }
    
    func goBack() {
        guard !navigationStack.isEmpty else {
            return
        }
        navigationStack.removeLast()
    }
    
    func goHome() {
        navigationStack.removeAll()
    }
}
