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
    let activeSet: ExerciseSet?
    let onTapRow: (ExerciseSet) -> ()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(exercise.name)
                .font(.headline)
            HStack {
                Grid {
                    GridRow {
                        Text("Set")
                        if exercise.sets[0].unit.hasReps {
                            Text(exercise.sets[0].unit.title)
                        }
                        Text("Target")
                        Text("Reps")
                    }
                    ForEach(exercise.sets, id: \.self) { set in
                        HStack {
                            GridRow {
                                Text("\(set.order)")
                                Text("\(set.weightDescription)")
                                if set.unit.hasReps {
                                    Text("\(set.repRange.lowerBound) - \(set.repRange.upperBound)")
                                }
                                if let reps = set.repsCompleted {
                                    Text("\(reps)")
                                } else {
                                    Text("-")
                                }
                            }
                            .padding([.leading, .trailing])
                            .foregroundStyle(set == activeSet ? activeTextColor : inactiveTextColor)
                        }
                        .background(set == activeSet ? .purple : .clear)
                        .clipShape(Capsule())
                        .onTapGesture {
                            onTapRow(set)
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
