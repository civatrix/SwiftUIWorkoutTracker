//
//  WorkoutTrackerWatchApp.swift
//  WorkoutTrackerWatch Watch App
//
//  Created by Daniel Johns on 2025-03-22.
//

import SwiftUI

@main
struct WorkoutTrackerWatch_Watch_AppApp: App {
    @State private var viewModel = WatchViewModel()
    @State private var connectivityManager = WatchConnectivityManager()
        
    var body: some Scene {
        WindowGroup {
            SessionPagingView()
                .onAppear {
                    viewModel.requestAuthorization()
                    connectivityManager.viewModel = viewModel
                }
                .environment(viewModel)
                .environment(connectivityManager)
        }
    }
}
