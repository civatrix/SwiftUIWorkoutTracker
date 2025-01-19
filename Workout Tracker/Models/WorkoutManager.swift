//
//  WorkoutManager.swift
//  Workout Tracker
//
//  Created by Daniel Johns on 2025-03-29.
//

import Foundation
import HealthKit
import WatchKit

class WorkoutManager: NSObject, ObservableObject {
    let healthStore = HKHealthStore()
    var builder: HKLiveWorkoutBuilder?
    var session = WKExtendedRuntimeSession()
    
    @Published var heartRate: Double = 0
    
    func startWorkout() {
        guard builder == nil else { return }
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .indoor
        
        let workoutSession = try? HKWorkoutSession(healthStore: healthStore, configuration: configuration)
        
        builder = workoutSession?.associatedWorkoutBuilder()
        builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
        builder?.delegate = self
        
        workoutSession?.startActivity(with: Date())
        builder?.beginCollection(withStart: Date()) { _, _ in }
        
        session.start()
    }
    
    func completeWorkout() {
        guard let builder = builder else { return }
        
        heartRate = 0
        builder.endCollection(withEnd: Date()) { _, _ in
            builder.finishWorkout() { _, _ in }
        }
        session.invalidate()
    }
    
    // Request authorization to access HealthKit.
    func requestAuthorization() {
        // The quantity type to write to the health store.
        let typesToShare: Set = [
            HKQuantityType.workoutType()
        ]

        // The quantity types to read from the health store.
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
        ]

        // Request authorization for those quantity types.
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            // Handle error.
        }
    }
}

extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) { }

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType,
                  let statistics = workoutBuilder.statistics(for: quantityType),
                  statistics.quantityType == HKQuantityType.quantityType(forIdentifier: .heartRate)
            else {
                return // Nothing to do.
            }

            DispatchQueue.main.async {
                let unit = HKUnit.count().unitDivided(by: .minute())
                self.heartRate = statistics.mostRecentQuantity()?.doubleValue(for: unit) ?? 0
            }
        }
    }
}
