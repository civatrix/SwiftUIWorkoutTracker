//
//  NumericTextField.swift
//  Workout Tracker
//
//  Created by Daniel Johns on 2025-01-25.
//

import SwiftUI

struct NumericTextField: View {
    @Binding var value: Int?
    @Binding var isDirty: Bool
    
    var body: some View {
        TextField("", value: $value, format: .number)
            .keyboardType(.numbersAndPunctuation)
            .onChange(of: value) {
                isDirty = true
            }
            .multilineTextAlignment(.center)
            .tint(.white)
            .foregroundStyle(.white)
            .background(.tint)
            .clipShape(Capsule())
    }
}

#Preview {
    @State @Previewable var value: Int? = 10
    @State @Previewable var isDirty = false
    return NumericTextField(value: $value, isDirty: $isDirty)
        .tint(Color.purple)
}
