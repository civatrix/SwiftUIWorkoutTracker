//
//  LogsView.swift
//  Workout Tracker
//
//  Created by Daniel Johns on 2025-11-21.
//

import SwiftUI

struct LogsView: View {
    @StateObject var logger: Logger = .shared
    
    var body: some View {
        List(logger.messages, id: \.self) {
            Text($0)
        }
    }
}
