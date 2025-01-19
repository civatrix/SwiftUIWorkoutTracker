//
//  WatchViewModel.swift
//  WorkoutTrackerWatch Watch App
//
//  Created by Daniel Johns on 2025-04-03.
//

import Foundation
import Combine

class WatchViewModel: ObservableObject {
    @MainActor
    static let preview = {
        let viewModel = WatchViewModel()
        viewModel.workoutData = [
            .init(name: "Test Set", setNumber: "1/3", repRange: 1...10, exerciseIndex: 0, setIndex: 0, unit: .seconds)
        ]
        return viewModel
    }()
    
    @MainActor @Published
    var workoutData: [WatchSetData] = []
    
    @MainActor @Published
    var activeSet: Int = 0
    
    @MainActor @Published
    var elapsedTime: Int = 0
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private var cancelBag: Set<AnyCancellable> = []
    
    @MainActor
    init() {
        timer.sink { _ in
            self.elapsedTime += 1
        }.store(in: &cancelBag)
    }
    
    @MainActor
    func complete() {
        workoutData = []
        activeSet = -1
    }
}
