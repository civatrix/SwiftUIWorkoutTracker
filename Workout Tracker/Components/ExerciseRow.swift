//
//  ExerciseRow.swift
//  Workout Tracker
//
//  Created by Daniel Johns on 2025-01-25.
//

import SwiftUI

struct ExerciseRow: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var exercise: Exercise
    let activeSet: Int?
    let onTapRow: (Int) -> ()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(exercise.name)
                .font(.headline)
            HStack {
                Grid {
                    GridRow {
                        Text("Set")
                        if exercise.unit.hasReps {
                            Text(exercise.unit.title)
                        }
                        Text("Target")
                        Text("Reps")
                    }
                    ForEach(exercise.repsCompleted.indices, id: \.self) { index in
                        HStack {
                            GridRow {
                                Text("\(index + 1)")
                                Text("\(exercise.weightDescription)")
                                if exercise.unit.hasReps {
                                    Text("\(exercise.repRange.lowerBound) - \(exercise.repRange.upperBound)")
                                }
                                if let reps = exercise.repsCompleted[index] {
                                    Text("\(reps)")
                                } else {
                                    Text("-")
                                }
                            }
                            .padding([.leading, .trailing])
                            .foregroundStyle(index == activeSet ? activeTextColor : inactiveTextColor)
                        }
                        .background(index == activeSet ? .purple : .clear)
                        .clipShape(Capsule())
                        .onTapGesture {
                            onTapRow(index)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(activeSet == nil ? .clear : .orange)
        .clipShape(RoundedRectangle(cornerRadius: 25.0))
    }
    
    var activeTextColor: Color {
        switch colorScheme {
        case .light:
                .white
        case .dark:
                .black
        @unknown default:
                .white
        }
    }
    
    var inactiveTextColor: Color {
        switch colorScheme {
        case .light:
                .black
        case .dark:
                .white
        @unknown default:
                .black
        }
    }
}

#Preview {
    @State @Previewable var workout = Workout.preview
    return VStack {
        ForEach($workout.exercises) { $exercise in
            ExerciseRow(exercise: $exercise, activeSet: nil) { _ in }
                .padding()
        }
    }
}
