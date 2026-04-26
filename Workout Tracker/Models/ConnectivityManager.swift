//
//  ConnectivityManager.swift
//  Workout Tracker
//
//  Created by Daniel Johns on 2025-03-23.
//

import SwiftData
import WatchConnectivity

#if os(iOS)
class PhoneConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = PhoneConnectivityManager(modelContainer: .sharedModelContainer)
    
    let modelContainer: ModelContainer
    var activeWorkoutIdentifier: PersistentIdentifier?
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        
        super.init()
        
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        if let error {
            Logger.shared.log("Error activating session: \(error)")
        }
        
        sendTemplates()
        let modelContext = ModelContext(modelContainer)
        if let activeWorkoutIdentifier, let activeWorkout = modelContext.model(for: activeWorkoutIdentifier) as? Workout {
            sendWorkout(activeWorkout)
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        Logger.shared.log("SessionDidBecomeInactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        Logger.shared.log("SessionDidDeactivate")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        Logger.shared.log("didReceiveMessage Begin")
        guard let messages = message["messages"] as? [[String: Int]] else { return }
        
        let modelContext = ModelContext(modelContainer)
        if activeWorkoutIdentifier == nil, let templateName = message["templateName"] as? String {
            Logger.shared.log("Creating new workout from Template: \(templateName)")
            if let template = try? modelContext.fetch(FetchDescriptor<WorkoutTemplate>(predicate: #Predicate { $0.name == templateName })).first {
                let workout = template.newWorkout()
                modelContext.insert(workout)
                try! modelContext.save()
                activeWorkoutIdentifier = workout.id
            }
        }
        
        for message in messages {
            guard let exerciseIndex = message["exerciseIndex"],
                  let setIndex = message["setIndex"],
                  let completedReps = message["completedReps"] else { continue }
            Logger.shared.log("didReceiveMessage exerciseIndex: \(exerciseIndex), setIndex: \(setIndex), completedReps: \(completedReps)")
            
            guard let activeWorkoutIdentifier, let activeWorkout = modelContext.model(for: activeWorkoutIdentifier) as? Workout else { return }
            activeWorkout.ingestWatchData(exerciseIndex: exerciseIndex, setIndex: setIndex, completedReps: completedReps)
            if activeWorkout.allComplete {
                Logger.shared.log("Clearing activeWorkoutIdentifier")
                self.activeWorkoutIdentifier = nil
            }
        }
        
        try! modelContext.save()
        Logger.shared.log("didReceiveMessage End")
        
        replyHandler(message)
    }
    
    func sendTemplates() {
        guard WCSession.default.activationState == .activated else { return }
        
        Logger.shared.log("Starting to send templates")
        let modelContext = ModelContext(modelContainer)
        guard let templates = try? modelContext.fetch(FetchDescriptor<WorkoutTemplate>(sortBy: [SortDescriptor(\.name)])) else {
            return
        }
        do {
            Logger.shared.log("Sending \(templates.count) templates")
            try WCSession.default.updateApplicationContext(["templates": try JSONEncoder().encode(templates)])
        } catch {
            Logger.shared.log("Error sending templates: \(error)")
        }
        Logger.shared.log("Finished sending templates")
    }
    
    func sendWorkout(_ workout: Workout) {
        self.activeWorkoutIdentifier = workout.persistentModelID
        guard WCSession.default.activationState == .activated else { return }
        
        do {
            try WCSession.default.updateApplicationContext(["data": try JSONEncoder().encode(workout.createWatchData())])
        } catch {
            Logger.shared.log("Error sending workout: \(error)")
        }
    }
    
    func sendActiveSet(_ exercise: Exercise, _ set: Int) {
        guard WCSession.default.activationState == .activated else { return }
        let modelContext = ModelContext(modelContainer)
        guard let activeWorkoutIdentifier, let activeWorkout = modelContext.model(for: activeWorkoutIdentifier) as? Workout else { return }
        let watchData = activeWorkout.createWatchData()
        let activeSet = (watchData.firstIndex(where: { $0.name == exercise.longName }) ?? 0) + set
        
        do {
            try WCSession.default.updateApplicationContext(["activeSet": activeSet])
        } catch {
            Logger.shared.log("Error sending workout: \(error)")
        }
    }
}
#elseif os(watchOS)
import WatchKit
class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    var viewModel: WatchViewModel?
    var cache: [[String: Int]] = []
    
    override init() {
        super.init()
        
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        if let error {
            Logger.shared.log("Error activating session: \(error)")
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        do {
            if let data = applicationContext["templates"] as? Data {
                let templates = try JSONDecoder().decode([WorkoutTemplate].self, from: data)
                try? data.write(to: WatchViewModel.TemplateDataFileURL)
                Task { @MainActor in
                    self.viewModel?.templates = templates
                }
            }
            if let data = applicationContext["data"] as? Data {
                let workoutData = try JSONDecoder().decode([WatchSetData].self, from: data)
                Task { @MainActor in
                    self.viewModel?.workoutData = workoutData
                    self.viewModel?.activeSet = workoutData.firstIndex { $0.completedReps == nil } ?? 0
                }
            } else if let activeSet = applicationContext["activeSet"] as? Int {
                Task { @MainActor in
                    self.viewModel?.activeSet = activeSet
                }
            }
        } catch {
            Logger.shared.log("Error decoding workout: \(error)")
        }
    }
    
    func sendWorkoutData(exercise: WatchSetData, completedReps: Int, templateName: String? = nil) {
        guard WCSession.default.activationState == .activated else { return }
        
        Logger.shared.log("sendWorkoutData exerciseIndex: \(exercise.exerciseIndex), setIndex: \(exercise.setIndex), completedReps: \(completedReps)")
        let message = [
            "exerciseIndex": exercise.exerciseIndex,
            "setIndex": exercise.setIndex,
            "completedReps": completedReps
        ]
        cache.append(message)
        var messages: [String: Any] = ["messages": cache]
        if let templateName {
            messages["templateName"] = templateName
        }
        WCSession.default.sendMessage(messages, replyHandler: { [weak self] reply in
            guard let self, let messages = reply["messages"] as? [[String: Int]] else { return }
            for message in messages {
                self.cache.removeAll { message == $0 }
            }
            Logger.shared.log("Send successful. \(self.cache.count) messages in cache")
        }, errorHandler: { error in
            Logger.shared.log("\(error.localizedDescription). \(self.cache.count) messages in cache")
        })
    }
    
    func flushCache(templateName: String?) {
        Logger.shared.log("Flushing \(cache.count) cached messages")
        var messages: [String: Any] = ["messages": cache]
        if let templateName {
            messages["templateName"] = templateName
        }
        WCSession.default.sendMessage(messages, replyHandler: { [weak self] reply in
            guard let self, let messages = reply["messages"] as? [[String: Int]] else { return }
            for message in messages {
                self.cache.removeAll { message == $0 }
            }
            if !messages.isEmpty {
                self.flushCache(templateName: templateName)
            }
        }, errorHandler: { error in
            Logger.shared.log(error.localizedDescription)
        })
    }
}
#endif
