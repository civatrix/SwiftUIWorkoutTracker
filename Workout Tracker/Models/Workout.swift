//
//  Workout.swift
//  Workout Tracker
//
//  Created by Daniel Johns on 2025-01-19.
//

import Foundation
import SwiftData

@Model
final class Workout {
    internal init(name: String, date: Date, exercises: [Exercise]) {
        self.id = UUID()
        self.name = name
        self.date = date
        self.unorderedExercises = exercises
    }
    
    @Attribute(.unique) var id: UUID
    var name: String
    private(set) var date: Date
    @Relationship(deleteRule: .cascade) private var unorderedExercises: [Exercise]
    var exercises: [Exercise] {
        get {
            unorderedExercises.sorted { $0.order < $1.order }
        }
        set {
            unorderedExercises = newValue
        }
    }
    
    var displayName: String {
        "\(name) \(date.formatted(date: .abbreviated, time: .omitted))"
    }
    
    var allComplete: Bool {
        unorderedExercises.allSatisfy { !$0.repsCompleted.contains(nil) }
    }
    
    func createWatchData() -> [WatchSetData] {
        exercises.enumerated().flatMap { (exerciseIndex, exercise) in
            let repCount = exercise.repsCompleted.count
            return exercise.repsCompleted.enumerated().map { (setIndex, reps) in
                WatchSetData(name: exercise.longName, setNumber: "\(setIndex + 1)/\(repCount)", repRange: exercise.repRange, exerciseIndex: exerciseIndex, setIndex: setIndex, unit: exercise.unit, completedReps: reps)
            }
        }
    }
    
    func ingestWatchData(exerciseIndex: Int, setIndex: Int, completedReps: Int) {
        exercises[exerciseIndex].repsCompleted[setIndex] = completedReps
    }
    
    @MainActor
    static var preview: Workout {
        let container = ModelContainer.preview
        
        let workout = Workout(name: "Test Workout", date: Date(), exercises: [
            Exercise(name: "Squat", order: 0, unit: .bodyweight, repRange: 12...15, setCount: 3),
            Exercise(name: "Deadlift", order: 1, unit: .pounds(30), repRange: 8...12, setCount: 3),
            Exercise(name: "Wallsit", order: 2, unit: .seconds, repRange: 30...30, setCount: 2),
            Exercise(name: "Bike", order: 3, unit: .minutes, repRange: 10...15, setCount: 1),
        ])
        
        container.mainContext.insert(workout)
        try! container.mainContext.save()
        
        return workout
    }
}

struct WatchSetData: Codable, Equatable, Identifiable {
    var id: String {
        return "\(exerciseIndex)-\(setIndex)"
    }
    let name: String
    let setNumber: String
    let repRange: ClosedRange<Int>
    let exerciseIndex: Int
    let setIndex: Int
    let unit: Unit
    var completedReps: Int?
}

@Model
final class Exercise {
    internal init(name: String, order: Int, unit: Unit, repRange: ClosedRange<Int>, setCount: Int) {
        self.name = name
        self.order = order
        self.unit = unit
        self.repRange = repRange
        self.repsCompleted = [Int?](repeating: nil, count: setCount)
    }
    
    private(set) var name: String
    private(set) var order: Int
    private(set) var unit: Unit
    private(set) var repRange: ClosedRange<Int>
    var repsCompleted: [Int?]
    
    var longName: String {
        return switch unit {
        case .pounds:
            "\(name) \(weightDescription)"
        default:
            name
        }
    }
    
    var weightDescription: String {
        switch unit {
        case .pounds(let value):
            "\(value) lbs"
        case .bodyweight:
            "body"
        case .seconds:
            if repRange.lowerBound == repRange.upperBound {
                "\(repRange.lowerBound) sec"
            } else {
                "\(repRange.lowerBound)-\(repRange.upperBound) sec"
            }
        case .minutes:
            if repRange.lowerBound == repRange.upperBound {
                "\(repRange.lowerBound) min"
            } else {
                "\(repRange.lowerBound)-\(repRange.upperBound) min"
            }
        }
    }
    
    var allComplete: Bool {
        repsCompleted.allSatisfy { $0 != nil }
    }
}

@Model
final class WorkoutTemplate {
    init(name: String, exercises: [ExerciseTemplate]) {
        self.name = name
        self.unsortedExercises = exercises
    }
    
    private(set) var name: String
    @Relationship(deleteRule: .cascade) private var unsortedExercises: [ExerciseTemplate]
    var exercises: [ExerciseTemplate] {
        unsortedExercises.sorted { $0.order < $1.order }
    }
    
    func newWorkout() -> Workout {
        Workout(name: name, date: Date(), exercises: exercises.map { $0.newExercise() })
    }
    
    func prototype() -> WorkoutTemplatePrototype {
        let prototype = WorkoutTemplatePrototype()
        prototype.name = name
        prototype.exercises = exercises.map { $0.prototype() }
        
        return prototype
    }
    
    func update(from: WorkoutTemplatePrototype) throws {
        name = from.name
        unsortedExercises = try from.createTemplate().exercises
    }
    
    @MainActor
    static var preview: WorkoutTemplate {
        let container = ModelContainer.preview
        
        let workout = WorkoutTemplate(name: "Test Workout", exercises: [
            ExerciseTemplate(name: "Squat", order: 0, setCount: 3, unit: .bodyweight, repRange: 12...15),
            ExerciseTemplate(name: "Deadlift", order: 1, setCount: 3, unit: .pounds(30), repRange: 8...12),
            ExerciseTemplate(name: "Wallsit", order: 2, setCount: 2, unit: .seconds, repRange: 30...30),
            ExerciseTemplate(name: "Bike", order: 3, setCount: 1, unit: .minutes, repRange: 10...15),
        ])
        
        container.mainContext.insert(workout)
        try! container.mainContext.save()
        
        return workout
    }
}

@Model
final class ExerciseTemplate {
    internal init(name: String, order: Int, setCount: Int, unit: Unit, repRange: ClosedRange<Int>) {
        self.name = name
        self.order = order
        self.setCount = setCount
        self.unit = unit
        self.repRange = repRange
    }
    
    private(set) var name: String
    private(set) var order: Int
    private(set) var setCount: Int
    private(set) var unit: Unit
    private(set) var repRange: ClosedRange<Int>
    
    func newExercise() -> Exercise {
        Exercise(name: name, order: order, unit: unit, repRange: repRange, setCount: setCount)
    }
    
    func prototype() -> WorkoutTemplatePrototype.Exercise {
        WorkoutTemplatePrototype.Exercise(name: name, setCount: setCount, unitValue: unit.value, unit: unit, repRangeLower: repRange.lowerBound, repRangeUpper: repRange.upperBound)
    }
}

@Observable final class WorkoutTemplatePrototype: Equatable {
    static func == (lhs: WorkoutTemplatePrototype, rhs: WorkoutTemplatePrototype) -> Bool {
        lhs.name == rhs.name && lhs.exercises == rhs.exercises
    }
    
    enum CreateError: Error {
        case name
        case exerciseName(row: Int)
        case setCount(row: Int)
        case unit(row: Int)
        case repRangeLower(row: Int)
        case repRangeUpper(row: Int)
        case repRange(row: Int)
        
        var reason: String {
            switch self {
            case .name:
                "Missing name of workout"
            case .exerciseName(let row):
                "Missing name of exercise \(row + 1)"
            case .setCount(let row):
                "Missing set count for exercise \(row + 1)"
            case .unit(let row):
                "Missing unit value for exercise \(row + 1)"
            case .repRangeLower(let row):
                "Missing rep range lower bound for exercise \(row + 1)"
            case .repRangeUpper(let row):
                "Missing rep range upper bound for exercise \(row + 1)"
            case .repRange(let row):
                "Rep range lower bound must be smaller than upper bound for exercise \(row + 1)"
            }
        }
        
        var row: Int? {
            switch self {
            case .name:
                nil
            case .exerciseName(let row):
                row
            case .setCount(let row):
                row
            case .unit(let row):
                row
            case .repRangeLower(let row):
                row
            case .repRangeUpper(let row):
                row
            case .repRange(let row):
                row
            }
        }
    }
    
    var name = ""
    var exercises: [Exercise] = []
    
    final class Exercise: Identifiable, Equatable {
        static func == (lhs: WorkoutTemplatePrototype.Exercise, rhs: WorkoutTemplatePrototype.Exercise) -> Bool {
            lhs.id == rhs.id &&
            lhs.name == rhs.name &&
            lhs.setCount == rhs.setCount &&
            lhs.unit == rhs.unit &&
            lhs.repRangeLower == rhs.repRangeLower &&
            lhs.repRangeUpper == rhs.repRangeUpper
        }
        
        internal init(name: String = "", setCount: Int? = nil, unitValue: Int? = nil, unit: Unit? = nil, repRangeLower: Int? = nil, repRangeUpper: Int? = nil) {
            self.name = name
            self.setCount = setCount
            self.unitValue = unitValue
            self.unit = unit?.with(newValue: 1) ?? .pounds(1)
            self.repRangeLower = repRangeLower
            self.repRangeUpper = repRangeUpper
        }
        
        let id = UUID()
        var name = ""
        var setCount: Int? = nil
        var unitValue: Int? = nil
        var unit: Unit
        var repRangeLower: Int? = nil
        var repRangeUpper: Int? = nil
        
        func createTemplate(row: Int) throws -> ExerciseTemplate {
            guard !name.isEmpty else {
                throw CreateError.exerciseName(row: row)
            }
            
            guard let setCount else {
                throw CreateError.setCount(row: row)
            }
            
            guard let unit = unit.with(newValue: unitValue) else {
                throw CreateError.unit(row: row)
            }
            
            guard let repRangeLower else {
                throw CreateError.repRangeLower(row: row)
            }
            
            guard let repRangeUpper else {
                throw CreateError.repRangeUpper(row: row)
            }
            
            guard repRangeLower <= repRangeUpper else {
                throw CreateError.repRange(row: row)
            }
            
            return .init(name: name, order: row, setCount: setCount, unit: unit, repRange: repRangeLower...repRangeUpper)
        }
    }
    
    func createTemplate() throws -> WorkoutTemplate {
        guard !name.isEmpty else {
            throw CreateError.name
        }
        
        let exercises = try exercises.enumerated().map { try $0.1.createTemplate(row: $0.0) }
        return WorkoutTemplate(name: name, exercises: exercises)
    }
}

enum Unit: Codable, Equatable, Hashable, Identifiable, CaseIterable {
    static var allCases: [Unit] = [.pounds(1), .bodyweight, .seconds, .minutes]
    
    case pounds(Int)
    case bodyweight
    case seconds
    case minutes
    
    var id: Self { self }
    
    var description: String {
        switch self {
        case .pounds: "lbs"
        case .bodyweight: "body"
        case .seconds: "sec"
        case .minutes: "min"
        }
    }
    
    var title: String {
        switch self {
        case .pounds: "Weight"
        case .bodyweight: "Weight"
        case .seconds: "Time"
        case .minutes: "Time"
        }
    }
    
    var value: Int? {
        switch self {
        case .pounds(let int): int
        case .bodyweight: nil
        case .seconds: nil
        case .minutes: nil
        }
    }
    
    var hasReps: Bool {
        switch self {
        case .pounds: true
        case .bodyweight: true
        case .seconds: false
        case .minutes: false
        }
    }
    
    var hasValue: Bool {
        value != nil
    }
    
    func with(newValue: Int?) -> Unit? {
        guard let newValue else {
            return self
        }
        
        return switch self {
        case .pounds: .pounds(newValue)
        case .bodyweight: .bodyweight
        case .seconds: .seconds
        case .minutes: .minutes
        }
    }
}

extension ModelContainer {
    static let preview = try! ModelContainer(for: Workout.self, WorkoutTemplate.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
}
