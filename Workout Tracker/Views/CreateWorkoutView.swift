//
//  CreateWorkoutView.swift
//  Workout Tracker
//
//  Created by Daniel Johns on 2025-01-24.
//

import SwiftUI
import SwiftData

struct CreateWorkoutView: View {
    @EnvironmentObject private var navigationManager: NavigationManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.isPresented) private var isPresented
    @Query(sort: \WorkoutTemplate.name) private var templates: [WorkoutTemplate]
    
    var body: some View {
        List(templates) { template in
            NavigationLink(value: startWorkout(template)) {
                Text(template.name)
            }
            .swipeActions {
                Button("Delete", role: .destructive) {
                    modelContext.delete(template)
                }
                .tint(.red)
                Button("Edit") {
                    navigationManager.goToEditWorkoutTemplate(template)
                }
            }
            .tag(template)
        }
        .toolbar {
            ToolbarItem {
                Button(action: addItem) {
                    Label("Add Item", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Start New Workout")
    }
    
    private func startWorkout(_ template: WorkoutTemplate) -> NavigationManager.ViewDestination {
        return navigationManager.startWorkoutDestination(template)
    }
    
    private func addItem() {
        withAnimation {
            navigationManager.goToCreateWorkoutTemplate()
        }
    }
}

#Preview {
    CreateWorkoutView()
}
