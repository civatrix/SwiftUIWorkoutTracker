//
//  CreateWorkoutTemplateView.swift
//  Workout Tracker
//
//  Created by Daniel Johns on 2025-01-24.
//

import SwiftUI

struct CreateWorkoutTemplateView: View {
    init(template: WorkoutTemplate? = nil) {
        if let template {
            self.existingTemplate = template
            self.template = template.prototype()
        } else {
            self.template = WorkoutTemplatePrototype()
        }
    }
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var navigationManager: NavigationManager
    
    @State private var existingTemplate: WorkoutTemplate?
    @State private var template: WorkoutTemplatePrototype
    @State private var isDirty = false
    @State private var showSaveAlert = false
    @State private var errorRow: Int?
    @State private var errorReason: String?
    
    @FocusState private var focus: String?
    
    var body: some View {
        ScrollView {
            if let errorReason {
                Text(errorReason)
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.red)
                    .clipShape(Capsule())
            }
            VStack(spacing: 0) {
                TextField("Template Name", text: $template.name)
                    .onChange(of: template.name) {
                        isDirty = true
                    }
                    .padding()
                    .border(.red, width: errorRow == nil && errorReason != nil ? 2 : 0)
                
                ForEach($template.exercises) { $exercise in
                    let index = template.exercises.firstIndex { $0 == $exercise.wrappedValue }
                    Row(exercise: $exercise, isDirty: $isDirty) {
                        guard let index = template.exercises.firstIndex(of: exercise) else { return }
                        template.exercises.remove(at: index)
                        isDirty = true
                    }
                    .padding()
                    .border(.red, width: index == errorRow ? 2 : 0)
                }
                
                Button("Add exercise") {
                    let lastExercise = template.exercises.last
                    template.exercises.append(.init(setCount: lastExercise?.setCount,
                                                    unitValue: lastExercise?.unitValue,
                                                    unit: lastExercise?.unit,
                                                    repRangeLower: lastExercise?.repRangeLower,
                                                    repRangeUpper: lastExercise?.repRangeUpper))
                    isDirty = true
                }
            }
            .padding()
        }
        .alert("You have unsaved changes", isPresented: $showSaveAlert) {
            Button("Keep Editing", role: .cancel) { showSaveAlert = false }
            Button("Save Changes") { save() }
            Button("Discard Changes", role: .destructive) { navigationManager.goBack() }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: attemptToGoBack) {
                    Label("Back", systemImage: "chevron.left")
                }
            }
        }
        .navigationTitle(existingTemplate?.name ?? "New Template")
        .navigationBarBackButtonHidden(true)
    }
    
    func attemptToGoBack() {
        errorRow = nil
        errorReason = nil
        
        guard isDirty else {
            navigationManager.goBack()
            return
        }
        
        showSaveAlert = true
    }
    
    func save() {
        do {
            if let existingTemplate {
                try existingTemplate.update(from: template)
            } else {
                modelContext.insert(try template.createTemplate())
            }
            isDirty = false
            navigationManager.goBack()
        } catch let error as WorkoutTemplatePrototype.CreateError {
            errorReason = error.reason
            errorRow = error.row
        } catch {
            errorReason = error.localizedDescription
        }
    }
    
    struct Row: View {
        enum FocusedField {
            case name, sets, unit, repsLower, repsUpper
            
            var next: FocusedField? {
                switch self {
                case .name: .sets
                case .sets: .unit
                case .unit: .repsLower
                case .repsLower: .repsUpper
                case .repsUpper: nil
                }
            }
        }
        
        @Binding var exercise: WorkoutTemplatePrototype.Exercise
        @Binding var isDirty: Bool
        let onDelete: () -> Void
        
        @FocusState private var focus: FocusedField?
        @State private var confirmDelete = false
        
        var body: some View {
            VStack {
                HStack {
                    TextField("Exercise Name", text: $exercise.name)
                        .submitLabel(.next)
                        .focused($focus, equals: .name)
                        .onChange(of: exercise.name) {
                            isDirty = true
                        }
                    Button(confirmDelete ? "Delete" : "", systemImage: "minus.circle", role: .destructive) {
                        if confirmDelete {
                            onDelete()
                        } else {
                            confirmDelete = true
                        }
                    }
                }
                Grid {
                    GridRow {
                        Text("Sets")
                        if exercise.unit != .bodyweight {
                            Text(exercise.unit.title)
                        }
                        Text("Unit")
                        if exercise.unit.hasReps {
                            Text("Reps")
                        }
                    }
                    GridRow {
                        NumericTextField(value: $exercise.setCount, isDirty: $isDirty)
                            .submitLabel(.next)
                            .focused($focus, equals: .sets)
                        if exercise.unit.hasValue {
                            NumericTextField(value: $exercise.unitValue, isDirty: $isDirty)
                                .submitLabel(.next)
                                .focused($focus, equals: .unit)
                        } else if !exercise.unit.hasReps {
                            repRow
                        }
                        Picker("", selection: $exercise.unit) {
                            ForEach(Unit.allCases) { unit in
                                Text(unit.description)
                            }
                        }
                        .pickerStyle(.menu)
                        if exercise.unit.hasReps {
                            repRow
                        }
                    }
                }
                Spacer()
            }
            .onSubmit {
                focus = focus?.next
            }
            .onAppear {
                focus = exercise.name.isEmpty ? .name : nil
            }
            .onChange(of: focus) {
                confirmDelete = false
            }
        }
        
        var repRow: some View {
            HStack {
                NumericTextField(value: $exercise.repRangeLower, isDirty: $isDirty)
                    .focused($focus, equals: .repsLower)
                    .submitLabel(.next)
                Text("-")
                NumericTextField(value: $exercise.repRangeUpper, isDirty: $isDirty)
                    .submitLabel(.done)
                    .focused($focus, equals: .repsUpper)
            }
        }
    }
}

#Preview {
    CreateWorkoutTemplateView(template: WorkoutTemplate.preview)
        .tint(Color.purple)
}
