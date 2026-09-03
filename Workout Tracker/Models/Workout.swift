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
        unorderedExercises.allSatisfy { $0.allComplete }
    }
    
    func createWatchData() -> [WatchSetData] {
        var seenGroups: Set<Int> = []
        var watchData: [WatchSetData] = []
        for exercise in exercises {
            if let group = exercise.supersetGroup {
                guard !seenGroups.contains(group) else { continue }
                let data = exercises
                    .filter { $0.supersetGroup == group }
                    .map { $0.createWatchData() }
                watchData.append(contentsOf: data.interleaved().flatMap { $0 })
                seenGroups.insert(group)
            } else {
                watchData.append(contentsOf: exercise.createWatchData().flatMap { $0 })
            }
        }
        
        return watchData
    }
    
    func ingestWatchData(exerciseName: String, setIndex: Int, completedReps: Int) {
        exercises.first { $0.name == exerciseName }?.sets[setIndex].repsCompleted = completedReps
    }
    
    @MainActor
    static var preview: Workout {
        let container = ModelContainer.preview
        
        let workout = Workout(name: "Test Workout", date: Date(), exercises: [
            Exercise(name: "Squat", order: 0, unit: .bodyweight, repRange: 12...15, setCount: 3, supersetGroup: 0, seperateLimbs: false),
            Exercise(name: "Deadlift", order: 1, unit: .pounds(30), repRange: 8...12, setCount: 3, supersetGroup: 0, seperateLimbs: true),
            Exercise(name: "Wallsit", order: 2, unit: .seconds, repRange: 30...30, setCount: 2, supersetGroup: 1, seperateLimbs: false),
            Exercise(name: "Bike", order: 3, unit: .minutes, repRange: 10...15, setCount: 1, supersetGroup: 1, seperateLimbs: false),
        ])
        
        container.mainContext.insert(workout)
        try! container.mainContext.save()
        
        return workout
    }
}

struct WatchSetData: Codable, Equatable, Identifiable {
    var id: String {
        return "\(exerciseName)-\(setIndex)"
    }
    let name: String
    let setNumber: String
    let repRange: ClosedRange<Int>
    let exerciseName: String
    let setIndex: Int
    let unit: Unit
    var completedReps: Int?
}

@Model
final class Exercise {
    internal convenience init(name: String, order: Int, unit: Unit, repRange: ClosedRange<Int>, setCount: Int, supersetGroup: Int?, seperateLimbs: Bool) {
        let sets: [ExerciseSet] = (0..<setCount).map {
            .init(name: name, order: $0, repRange: repRange, unit: unit)
        }
        self.init(name: name, order: order, supersetGroup: supersetGroup, sets: sets, seperateLimbs: seperateLimbs)
    }
    
    internal init(name: String, order: Int, supersetGroup: Int?, sets: [ExerciseSet], seperateLimbs: Bool) {
        self.name = name
        self.order = order
        self.supersetGroup = supersetGroup
        self.unorderedSets = sets
        self.seperateLimbs = seperateLimbs
    }
    
    private(set) var name: String
    private(set) var order: Int
    private(set) var supersetGroup: Int?
    @Relationship(deleteRule: .cascade) private var unorderedSets: [ExerciseSet]
    private(set) var seperateLimbs: Bool = false
    
    var sets: [ExerciseSet] {
        get {
            unorderedSets.sorted { $0.order < $1.order }
        }
        set {
            unorderedSets = newValue
        }
    }
    
    var allComplete: Bool {
        sets.allSatisfy { $0.repsCompleted != nil }
    }
    
    func createWatchData() -> [[WatchSetData]] {
        let setCount = sets.count
        return sets.map { set in
            if seperateLimbs {
                [WatchSetData(name: set.longName + " (L)", setNumber: "\(set.order + 1)/\(setCount)", repRange: set.repRange, exerciseName: name, setIndex: set.order, unit: set.unit, completedReps: set.repsCompleted),
                WatchSetData(name: set.longName + " (R)", setNumber: "\(set.order + 1)/\(setCount)", repRange: set.repRange, exerciseName: name, setIndex: set.order, unit: set.unit, completedReps: set.repsCompleted)]
            } else {
                [WatchSetData(name: set.longName, setNumber: "\(set.order + 1)/\(setCount)", repRange: set.repRange, exerciseName: name, setIndex: set.order, unit: set.unit, completedReps: set.repsCompleted)]
            }
        }
    }
}

@Model
final class ExerciseSet {
    internal init(name: String, order: Int, repRange: ClosedRange<Int>, unit: Unit, repsCompleted: Int? = nil) {
        self.name = name
        self.order = order
        self.repRange = repRange
        self.unit = unit
        self.repsCompleted = repsCompleted
    }
    
    private(set) var name: String
    private(set) var order: Int
    private(set) var repRange: ClosedRange<Int>
    private(set) var unit: Unit
    var repsCompleted: Int?
    
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
}

@Model
final class WorkoutTemplate: Codable {
    enum CodingKeys: String, CodingKey {
        case name, unsortedExercises
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        unsortedExercises = try container.decode([ExerciseTemplate].self, forKey: .unsortedExercises)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(unsortedExercises, forKey: .unsortedExercises)
    }
    
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
    
    @MainActor
    static var defaults: [WorkoutTemplate] {        
        let workouts = [
            WorkoutTemplate(name: "Legs Day 1", exercises: [
                ExerciseTemplate(name: "Step ups", order: 0, setCount: 3, unit: .bodyweight, repRange: 8...15, supersetGroup: 0, seperateLimbs: true),
                ExerciseTemplate(name: "Deadlift", order: 1, setCount: 2, unit: .pounds(90), repRange: 10...10, supersetGroup: 0, seperateLimbs: false),
                ExerciseTemplate(name: "Squats", order: 2, setCount: 3, unit: .pounds(20), repRange: 8...8, supersetGroup: 1, seperateLimbs: false),
                ExerciseTemplate(name: "Hamstring Curl", order: 3, setCount: 3, unit: .pounds(35), repRange: 12...12, supersetGroup: 1, seperateLimbs: true),
                ExerciseTemplate(name: "Bench Bridge", order: 4, setCount: 3, unit: .pounds(10), repRange: 8...8, supersetGroup: 2, seperateLimbs: true),
                ExerciseTemplate(name: "Plank", order: 5, setCount: 3, unit: .seconds, repRange: 12...15, supersetGroup: 2, seperateLimbs: false),
                ExerciseTemplate(name: "Double Leg Hopping", order: 6, setCount: 2, unit: .seconds, repRange: 15...15, supersetGroup: 3, seperateLimbs: false),
                ExerciseTemplate(name: "Single Leg Hopping", order: 7, setCount: 1, unit: .seconds, repRange: 15...15, supersetGroup: 3, seperateLimbs: true),
            ]),
            WorkoutTemplate(name: "Legs Day 2", exercises: [
                ExerciseTemplate(name: "Leg Lifts", order: 0, setCount: 3, unit: .bodyweight, repRange: 10...10, supersetGroup: nil, seperateLimbs: true),
                ExerciseTemplate(name: "Evelated Split Squats", order: 1, setCount: 3, unit: .bodyweight, repRange: 6...8, supersetGroup: 0, seperateLimbs: true),
                ExerciseTemplate(name: "Split Deadlift", order: 2, setCount: 2, unit: .pounds(35), repRange: 10...10, supersetGroup: 0, seperateLimbs: true),
                ExerciseTemplate(name: "Knee Extension", order: 3, setCount: 3, unit: .pounds(15), repRange: 12...12, supersetGroup: nil, seperateLimbs: true),
                ExerciseTemplate(name: "Plank", order: 4, setCount: 3, unit: .seconds, repRange: 12...15, supersetGroup: 1, seperateLimbs: false),
                ExerciseTemplate(name: "Elevated Bridge", order: 5, setCount: 2, unit: .bodyweight, repRange: 8...8, supersetGroup: 1, seperateLimbs: false),
                ExerciseTemplate(name: "Calf Raises", order: 6, setCount: 3, unit: .bodyweight, repRange: 10...12, supersetGroup: 2, seperateLimbs: false),
                ExerciseTemplate(name: "Single Leg Squats", order: 7, setCount: 3, unit: .bodyweight, repRange: 3...6, supersetGroup: 2, seperateLimbs: true),
            ]),
            WorkoutTemplate(name: "Arms", exercises: [
                ExerciseTemplate(name: "Shoulder Press", order: 0, setCount: 3, unit: .pounds(25), repRange: 8...10, supersetGroup: 0, seperateLimbs: false),
                ExerciseTemplate(name: "Hammer Curl", order: 1, setCount: 3, unit: .pounds(15), repRange: 8...10, supersetGroup: 0, seperateLimbs: false),
                ExerciseTemplate(name: "Tricep Extension", order: 2, setCount: 3, unit: .pounds(35), repRange: 8...10, supersetGroup: 1, seperateLimbs: false),
                ExerciseTemplate(name: "Lateral Raise", order: 3, setCount: 3, unit: .pounds(8), repRange: 8...10, supersetGroup: 1, seperateLimbs: false),
                ExerciseTemplate(name: "Tricep Pushdown", order: 4, setCount: 3, unit: .pounds(60), repRange: 8...10, supersetGroup: 2, seperateLimbs: false),
                ExerciseTemplate(name: "Lat Pulldown", order: 5, setCount: 3, unit: .pounds(70), repRange: 8...10, supersetGroup: 2, seperateLimbs: false),
                ExerciseTemplate(name: "Side Plank", order: 6, setCount: 3, unit: .seconds, repRange: 12...15, supersetGroup: 3, seperateLimbs: true),
                ExerciseTemplate(name: "Child's Pose", order: 7, setCount: 2, unit: .bodyweight, repRange: 5...5, supersetGroup: 3, seperateLimbs: false),
            ])
        ]
        
        return workouts
    }
    
    @MainActor
    static var preview: WorkoutTemplate {
        let container = ModelContainer.preview
        
        let workout = WorkoutTemplate(name: "Test Workout", exercises: [
            ExerciseTemplate(name: "Squat", order: 0, setCount: 3, unit: .bodyweight, repRange: 12...15, supersetGroup: 0, seperateLimbs: false),
            ExerciseTemplate(name: "Deadlift", order: 1, setCount: 3, unit: .pounds(30), repRange: 8...12, supersetGroup: 0, seperateLimbs: true),
            ExerciseTemplate(name: "Wallsit", order: 2, setCount: 2, unit: .seconds, repRange: 30...30, supersetGroup: nil, seperateLimbs: false),
            ExerciseTemplate(name: "Bike", order: 3, setCount: 1, unit: .minutes, repRange: 10...15, supersetGroup: nil, seperateLimbs: false),
        ])
        
        container.mainContext.insert(workout)
        try! container.mainContext.save()
        
        return workout
    }
}

@Model
final class ExerciseTemplate: Codable {
    enum CodingKeys: String, CodingKey {
        case name, order, setCount, unit, repRange, supersetGroup, seperateLimbs
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try container.decode(String.self, forKey: .name)
        order = try container.decode(Int.self, forKey: .order)
        setCount = try container.decode(Int.self, forKey: .setCount)
        unit = try container.decode(Unit.self, forKey: .unit)
        repRange = try container.decode(ClosedRange<Int>.self, forKey: .repRange)
        supersetGroup = try container.decode(Int?.self, forKey: .supersetGroup)
        seperateLimbs = try container.decode(Bool.self, forKey: .seperateLimbs)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(order, forKey: .order)
        try container.encode(setCount, forKey: .setCount)
        try container.encode(unit, forKey: .unit)
        try container.encode(repRange, forKey: .repRange)
        try container.encode(supersetGroup, forKey: .supersetGroup)
        try container.encode(seperateLimbs, forKey: .seperateLimbs)
    }
    
    internal init(name: String, order: Int, setCount: Int, unit: Unit, repRange: ClosedRange<Int>, supersetGroup: Int?, seperateLimbs: Bool) {
        self.name = name
        self.order = order
        self.setCount = setCount
        self.unit = unit
        self.repRange = repRange
        self.supersetGroup = supersetGroup
        self.seperateLimbs = seperateLimbs
    }
    
    private(set) var name: String
    private(set) var order: Int
    private(set) var setCount: Int
    private(set) var unit: Unit
    private(set) var repRange: ClosedRange<Int>
    private(set) var supersetGroup: Int?
    private(set) var seperateLimbs: Bool = false
    
    func newExercise() -> Exercise {
        Exercise(name: name, order: order, unit: unit, repRange: repRange, setCount: setCount, supersetGroup: supersetGroup, seperateLimbs: seperateLimbs)
    }
    
    func prototype() -> WorkoutTemplatePrototype.Exercise {
        WorkoutTemplatePrototype.Exercise(name: name, setCount: setCount, unitValue: unit.value, unit: unit, repRangeLower: repRange.lowerBound, repRangeUpper: repRange.upperBound, supersetGroup: supersetGroup, seperateLimbs: seperateLimbs)
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
    
    @Observable final class Exercise: Identifiable, Equatable {
        static func == (lhs: WorkoutTemplatePrototype.Exercise, rhs: WorkoutTemplatePrototype.Exercise) -> Bool {
            lhs.id == rhs.id &&
            lhs.name == rhs.name &&
            lhs.setCount == rhs.setCount &&
            lhs.unit == rhs.unit &&
            lhs.repRangeLower == rhs.repRangeLower &&
            lhs.repRangeUpper == rhs.repRangeUpper &&
            lhs.supersetGroup == rhs.supersetGroup &&
            lhs.seperateLimbs == rhs.seperateLimbs
        }
        
        internal init(name: String = "", setCount: Int? = nil, unitValue: Int? = nil, unit: Unit? = nil, repRangeLower: Int? = nil, repRangeUpper: Int? = nil, supersetGroup: Int?, seperateLimbs: Bool?) {
            self.name = name
            self.setCount = setCount
            self.unitValue = unitValue
            self.unit = unit?.with(newValue: 1) ?? .pounds(1)
            self.repRangeLower = repRangeLower
            self.repRangeUpper = repRangeUpper
            self.supersetGroup = supersetGroup
            self.seperateLimbs = seperateLimbs ?? false
        }
        
        let id = UUID()
        var name = ""
        var setCount: Int? = nil
        var unitValue: Int? = nil
        var unit: Unit
        var repRangeLower: Int? = nil
        var repRangeUpper: Int? = nil
        var supersetGroup: Int? = nil
        var seperateLimbs: Bool = false
        
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
            
            return .init(name: name, order: row, setCount: setCount, unit: unit, repRange: repRangeLower...repRangeUpper, supersetGroup: supersetGroup, seperateLimbs: seperateLimbs)
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
