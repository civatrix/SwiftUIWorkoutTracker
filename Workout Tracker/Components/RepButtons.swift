//
//  RepButtons.swift
//  Workout Tracker
//
//  Created by Daniel Johns on 2025-02-19.
//

import SwiftUI

struct RepButtons: View {
    let title: String
    let buttonValues: [Int]
    let valueSelected: (Int) -> ()
    
    init(title: String, repRange: ClosedRange<Int>, valueSelected: @escaping (Int) -> ()) {
        self.title = title
        self.valueSelected = valueSelected
        var result = [0]
        
        if repRange.count > 5 {
            result.append(repRange.lowerBound)
            result.append(repRange.lowerBound + (repRange.count / 2))
            result.append(repRange.upperBound)
        } else {
            result.append(contentsOf: repRange)
        }
        
        self.buttonValues = result
    }
    
    var body: some View {
        VStack {
            Text("\(title):")
            HStack {
                ForEach(buttonValues, id: \.self) { value in
                    button(value)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.orange)
        .clipShape(Capsule())
    }
    
    func button(_ value: Int) -> some View {
        Button(value.description) {
            valueSelected(value)
        }
        .padding([.leading, .trailing])
        .foregroundStyle(.white)
        .background(.purple)
        .clipShape(Capsule())
    }
}

#Preview {
    return RepButtons(title: "Squat Set 1", repRange: 8...12) {_ in}.padding()
}
