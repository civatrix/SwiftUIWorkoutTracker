//
//  WatchWorkoutListView.swift
//  Workout Tracker
//
//  Created by Daniel Johns on 2026-09-01.
//

import SwiftUI

struct WatchWorkoutListView: View {
    let viewModel: WatchViewModel
    
    var body: some View {
        HStack {
            Text("Workouts")
            Spacer()
            Button {
                viewModel.toggleSort()
            } label: {
                Image(systemName: viewModel.sortSymbol)
            }
            .buttonStyle(.borderless)
        }
        .font(.title3)

        List(viewModel.templates, id: \.self) { template in
            Button {
                viewModel.start(template: template)
            }
            label: {
                HStack {
                    Text(template.name)
                    Spacer()
                    Text(viewModel.lastDate(for: template))
                        .font(.footnote)
                }
            }
        }
    }
}

#Preview {
    WatchWorkoutListView(viewModel: .preview)
}
