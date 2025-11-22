//
//  SessionPagingView.swift
//  WorkoutTrackerWatch Watch App
//
//  Created by Daniel Johns on 2025-03-29.
//

import SwiftUI
import WatchKit

struct SessionPagingView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.isLuminanceReduced) var isLuminanceReduced
    @State private var selection: Tab = .workout

    enum Tab {
        case logs, workout, nowPlaying
    }

    var body: some View {
        TabView(selection: $selection) {
            LogsView()
                .tag(Tab.logs)
            TimelineView(MetricsTimelineSchedule(from: Date(), isPaused: false)) { context in
                WatchWorkoutView()
            }
            .tag(Tab.workout)
            NowPlayingView()
                .tag(Tab.nowPlaying)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(selection == .nowPlaying)
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: isLuminanceReduced ? .never : .automatic))
        .onChange(of: isLuminanceReduced) {
            displayMetricsView()
        }
    }

    private func displayMetricsView() {
        withAnimation {
            selection = .workout
        }
    }
}

private struct MetricsTimelineSchedule: TimelineSchedule {
    var startDate: Date
    var isPaused: Bool

    init(from startDate: Date, isPaused: Bool) {
        self.startDate = startDate
        self.isPaused = isPaused
    }

    func entries(from startDate: Date, mode: TimelineScheduleMode) -> AnyIterator<Date> {
        var baseSchedule = PeriodicTimelineSchedule(from: self.startDate,
                                                    by: (mode == .lowFrequency ? 1.0 : 1.0 / 30.0))
            .entries(from: startDate, mode: mode)
        
        return AnyIterator<Date> {
            guard !isPaused else { return nil }
            return baseSchedule.next()
        }
    }
}

#Preview {
    SessionPagingView()
}
