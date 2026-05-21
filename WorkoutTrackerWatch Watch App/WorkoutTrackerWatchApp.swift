//
//  WorkoutTrackerWatchApp.swift
//  WorkoutTrackerWatch Watch App
//
//  Created by Daniel Johns on 2025-03-22.
//

import SwiftUI

@main
struct WorkoutTrackerWatch_Watch_AppApp: App {
    @StateObject private var viewModel = WatchViewModel()
    @StateObject private var connectivityManager = WatchConnectivityManager()
        
    var body: some Scene {
        WindowGroup {
            SessionPagingView()
                .onAppear {
                    viewModel.requestAuthorization()
                    connectivityManager.viewModel = viewModel
                }
                .environmentObject(viewModel)
                .environmentObject(connectivityManager)
        }
    }
}
