//
//  WorkoutListView.swift
//  Workout Tracker
//
//  Created by Daniel Johns on 2025-01-19.
//

import SwiftUI
import SwiftData

struct WorkoutListView: View {
    @StateObject private var navigationManager = NavigationManager()
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]

    var body: some View {
        NavigationStack(path: $navigationManager.navigationStack) {
            List(workouts) { workout in
                let destination = if workout.allComplete {
                    navigationManager.completedWorkoutDestination(workout)
                } else {
                    navigationManager.resumeWorkoutDestination(workout)
                }
                NavigationLink(value: destination) {
                    if workout.allComplete {
                        Text(Image(systemName: "checkmark.circle"))
                    }
                    Text(workout.displayName)
                }
                .swipeActions {
                    Button("Delete", role: .destructive) {
                        modelContext.delete(workout)
                    }
                }
                .tag(workout)
            }
            .toolbar {
                ToolbarItem {
                    Button(action: viewLogs) {
                        Label("View Logs", systemImage: "list.bullet")
                    }
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .navigationDestination(for: NavigationManager.ViewDestination.self) { $0.newView() }
        }
        .environmentObject(navigationManager)
        .navigationTitle("Workouts")
    }
    
    private func viewLogs() {
        withAnimation {
            navigationManager.goToLogs()
        }
    }

    private func addItem() {
        withAnimation {
            navigationManager.goToCreateWorkout()
        }
    }
}

#Preview {
    WorkoutListView()
        .modelContainer(for: [Workout.self, WorkoutTemplate.self], inMemory: true)
}
