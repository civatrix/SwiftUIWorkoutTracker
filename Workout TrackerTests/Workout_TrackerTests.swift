//
//  Workout_TrackerTests.swift
//  Workout TrackerTests
//
//  Created by Daniel Johns on 2025-01-19.
//

import XCTest
@testable import Workout_Tracker

final class Workout_TrackerTests: XCTestCase {
    func testInterleaved() throws {
        let subject = [
            [1, 2, 3, 4, 12],
            [5, 6, 7],
            [8, 9, 10, 11]
        ]
        
        let expected = [1, 5, 8, 2, 6, 9, 3, 7, 10, 4, 11, 12]
        let result = subject.interleaved()
        XCTAssertEqual(result, expected)
    }
}
