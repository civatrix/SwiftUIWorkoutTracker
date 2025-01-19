//
//  WatchExerciseRow.swift
//  WorkoutTrackerWatch Watch App
//
//  Created by Daniel Johns on 2025-03-22.
//

import SwiftUI

struct WatchExerciseRow: View {
    let title: String
    let setNumber: String
    let unit: Unit
    let range: ClosedRange<Int>
    @Binding var value: Int
    let onSubmit: (Int) -> Void
    
    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .truncationMode(.middle)
                Spacer()
                Text(setNumber)
                    .font(.fraction(.body))
            }
            
            switch unit {
            case .seconds:
                WorkoutTimer(range: range, value: $value)
            case .minutes:
                let modifiedRange = (range.lowerBound * 60)...(range.upperBound * 60)
                WorkoutTimer(range: modifiedRange, value: $value)
            case .bodyweight, .pounds:
                Stepper(value: $value, in: range) {
                    Text("\(value)")
                }
            }
            
            Button("Next") {
                onSubmit(unit == .minutes ? value / 60 : value)
            }
            .font(.title)
            .foregroundStyle(.black)
            .background(Color.purple)
            .clipShape(Capsule())
        }
    }
}

#Preview("Pounds") {
    @State @Previewable var value: Int = 12
    WatchExerciseRow(title: "Squat 30 lbs", setNumber: "1/3", unit: .pounds(30), range: 8...12, value: $value) { _ in }
        .tint(.purple)
        .environmentObject(WatchViewModel.preview)
}

#Preview("Minutes") {
    @State @Previewable var value: Int = 15
    WatchExerciseRow(title: "Bike", setNumber: "1/3", unit: .minutes, range: 10...15, value: $value) { _ in }
        .tint(.purple)
        .environmentObject(WatchViewModel.preview)
}

#Preview("Seconds") {
    @State @Previewable var value: Int = 45
    WatchExerciseRow(title: "Wall sit", setNumber: "1/3", unit: .seconds, range: 30...45, value: $value) { _ in }
        .tint(.purple)
        .environmentObject(WatchViewModel.preview)
}
