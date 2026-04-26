//
//  WatchViewModel.swift
//  WorkoutTrackerWatch Watch App
//
//  Created by Daniel Johns on 2025-04-03.
//

import Combine
import Foundation
import SwiftData
import WatchKit

@MainActor
class WatchViewModel: ObservableObject {
    nonisolated static let TemplateDataFileURL = URL.documentsDirectory.appending(path: "templates.json")
    static let preview = {
        let viewModel = WatchViewModel()
        return viewModel
    }()
    
    @Published
    var workoutData: [WatchSetData] = []
    
    @Published
    var templates: [WorkoutTemplate] = []
    
    @Published
    var activeSet: Int = 0
    
    @Published
    var elapsedTime: Int = 0
    
    var templateName: String?
    private var timerStart: Date?
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private var cancelBag: Set<AnyCancellable> = []
    
    init() {
        timer.sink { [weak self] _ in
            guard let self, let timerStart else { return }
            self.elapsedTime = Int(Date().timeIntervalSince(timerStart))
        }.store(in: &cancelBag)
        guard let data = try? Data(contentsOf: Self.TemplateDataFileURL) else { return }
        templates = (try? JSONDecoder().decode([WorkoutTemplate].self, from: data)) ?? []
    }
    
    func startTimer(range: ClosedRange<Int>) {
        timerStart = Date()
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(range.upperBound), qos: .userInteractive) { [weak self] in
            guard self?.timerStart != nil else { return }
            WKInterfaceDevice.current().play(.success)
            self?.elapsedTime = range.upperBound
            self?.timerStart = nil
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(range.lowerBound), qos: .userInteractive) { [weak self] in
            guard self?.timerStart != nil else { return }
            WKInterfaceDevice.current().play(.failure)
            self?.elapsedTime = range.lowerBound
        }
    }

    func cancelTimer() {
        timerStart = nil
    }

    func complete() {
        workoutData = []
        activeSet = -1
        templateName = nil
    }
    
    func start(template: WorkoutTemplate) {
        workoutData = template.newWorkout().createWatchData()
        templateName = template.name
        activeSet = 0
    }
}
