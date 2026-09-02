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
@Observable
class WatchViewModel {
    enum SortOrder {
        case name
        case lastUsed
        
        var symbol: String {
            switch self {
            case .name: return "character"
            case .lastUsed: return "clock"
            }
        }
    }
    
    nonisolated static let TemplateDataFileURL = URL.documentsDirectory.appending(path: "templates.json")
    static let preview = {
        let viewModel = WatchViewModel()
        return viewModel
    }()
    
    var workoutData: [WatchSetData] = []
    var templates: [WorkoutTemplate] = []
    var activeSet: Int = 0
    var elapsedTime: Int = 0
    var heartRate: Double {
        workoutManager.heartRate
    }
    var sortSymbol: String {
        sortOrder.symbol
    }
    
    var templateName: String?
    private let workoutManager: WorkoutManager = WorkoutManager()
    private var timerStart: Date?
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private var cancelBag: Set<AnyCancellable> = []
    private var unsortedTemplates: [WorkoutTemplate] = []
    private var sortOrder: SortOrder
    private var lastUsedDates: [String: Date] = [:]
    
    init() {
        sortOrder = UserDefaults.standard.bool(forKey: "sortByLastUsed") ? .lastUsed : .name
        timer.sink { [weak self] _ in
            guard let self, let timerStart else { return }
            self.elapsedTime = Int(Date().timeIntervalSince(timerStart))
        }.store(in: &cancelBag)
        guard let data = try? Data(contentsOf: Self.TemplateDataFileURL) else { return }
        unsortedTemplates = (try? JSONDecoder().decode([WorkoutTemplate].self, from: data)) ?? []
        for template in unsortedTemplates {
            lastUsedDates[template.name] = UserDefaults.standard.object(forKey: template.name) as? Date
        }
        sortTemplates()
    }
    
    func setTemplates(_ templates: [WorkoutTemplate]) {
        unsortedTemplates = templates
        sortTemplates()
    }
    
    func toggleSort() {
        switch sortOrder {
        case .lastUsed: sortOrder = .name
        case .name: sortOrder = .lastUsed
        }
        sortTemplates()
        
        UserDefaults.standard.set(sortOrder == .lastUsed, forKey: "sortByLastUsed")
    }
    
    func sortTemplates() {
        templates = switch sortOrder {
        case .name:
            unsortedTemplates.sorted(using: KeyPathComparator(\.name, order: .forward))
        case .lastUsed:
            unsortedTemplates.sorted(by: {
                switch (lastUsedDates[$0.name], lastUsedDates[$1.name]) {
                case let (.some(lhs), .some(rhs)): return lhs < rhs
                case (.some, .none): return false
                case (.none, .some): return true
                case (.none, .none): return $0.name < $1.name
                }
            })
        }
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
        workoutManager.completeWorkout()
    }
    
    func start(template: WorkoutTemplate) {
        UserDefaults.standard.set(Date(), forKey: template.name)
        workoutData = template.newWorkout().createWatchData()
        templateName = template.name
        activeSet = 0
        workoutManager.startWorkout()
    }
    
    func lastDate(for template: WorkoutTemplate) -> String {
        guard let date = lastUsedDates[template.name] else {
            return ""
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        return formatter.string(from: date)
    }
    
    func requestAuthorization() {
        workoutManager.requestAuthorization()
    }
}
