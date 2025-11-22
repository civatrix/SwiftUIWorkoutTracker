//
//  Logger.swift
//  Workout Tracker
//
//  Created by Daniel Johns on 2025-11-21.
//

import SwiftUI

class Logger: ObservableObject {
    static let shared = Logger()
    
    @Published var messages: [String] = []
    
    func log(_ message: String) {
        messages.append("\(Date().formatted(Date.FormatStyle(date: .omitted, time: .standard))): \(message)")
    }
}
