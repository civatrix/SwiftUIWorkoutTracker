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
        
        let context = ModelContext(modelContainer)
        guard let activeWorkoutIdentifier, let activeWorkout = context.model(for: activeWorkoutIdentifier) as? Workout else { return }
        sendWorkout(activeWorkout)
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        Logger.shared.log("didReceiveMessage Begin")
        guard let exerciseIndex = message["exerciseIndex"] as? Int,
              let setIndex = message["setIndex"] as? Int,
              let completedReps = message["completedReps"] as? Int else { return }
        Logger.shared.log("didReceiveMessage exerciseIndex: \(exerciseIndex), setIndex: \(setIndex), completedReps: \(completedReps)")
        
        let context = ModelContext(modelContainer)
        guard let activeWorkoutIdentifier, let activeWorkout = context.model(for: activeWorkoutIdentifier) as? Workout else { return }
        activeWorkout.ingestWatchData(exerciseIndex: exerciseIndex, setIndex: setIndex, completedReps: completedReps)
        try! context.save()
        Logger.shared.log("didReceiveMessage End")
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
        let context = ModelContext(modelContainer)
        guard let activeWorkoutIdentifier, let activeWorkout = context.model(for: activeWorkoutIdentifier) as? Workout else { return }
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
            if let data = applicationContext["data"] as? Data {
                let workoutData = try JSONDecoder().decode([WatchSetData].self, from: data)
                Task {
                    await MainActor.run {
                        self.viewModel?.workoutData = workoutData
                        self.viewModel?.activeSet = workoutData.firstIndex { $0.completedReps == nil } ?? 0
                    }
                }
            } else if let activeSet = applicationContext["activeSet"] as? Int {
                Task {
                    await MainActor.run {
                        self.viewModel?.activeSet = activeSet
                    }
                }
            }
        } catch {
            Logger.shared.log("Error decoding workout: \(error)")
        }
    }
    
    func sendWorkoutData(exercise: WatchSetData, completedReps: Int) {
        guard WCSession.default.activationState == .activated else { return }
        
        Logger.shared.log("sendWorkoutData exerciseIndex: \(exercise.exerciseIndex), setIndex: \(exercise.setIndex), completedReps: \(completedReps)")
        let message = [
            "exerciseIndex": exercise.exerciseIndex,
            "setIndex": exercise.setIndex,
            "completedReps": completedReps
        ]
        WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: { error in
            Logger.shared.log(error.localizedDescription)
        })
    }
}
#endif
