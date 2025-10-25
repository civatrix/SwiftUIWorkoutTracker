//
//  WatchViewModel.swift
//  WorkoutTrackerWatch Watch App
//
//  Created by Daniel Johns on 2025-04-03.
//

import Combine
import Foundation
import WatchKit

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
    
    private var timerStart: Date?
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private var cancelBag: Set<AnyCancellable> = []
    
    @MainActor
    init() {
        timer.sink { [weak self] _ in
            guard let self, let timerStart else { return }
            self.elapsedTime = Int(Date().timeIntervalSince(timerStart))
        }.store(in: &cancelBag)
    }
    
    func startTimer(range: ClosedRange<Int>) {
        timerStart = Date()
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(range.upperBound)) {
            WKInterfaceDevice.current().play(.success)
            self.elapsedTime = range.upperBound
            self.timerStart = nil
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(range.lowerBound)) {
            WKInterfaceDevice.current().play(.failure)
            self.elapsedTime = range.lowerBound
        }
    }
    
    @MainActor
    func complete() {
        workoutData = []
        activeSet = -1
    }
}
