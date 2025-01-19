//
//  WorkoutTimer.swift
//  WorkoutTrackerWatch Watch App
//
//  Created by Daniel Johns on 2025-03-27.
//

import SwiftUI

struct WorkoutTimer: View {
    @EnvironmentObject var viewModel: WatchViewModel
    
    let range: ClosedRange<Int>
    @Binding var value: Int
    
    @State private var elapsedTime: Int = 0
    @State private var isPaused = true
    
    let timeFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        
        return formatter
    }()
    
    var body: some View {
        ZStack {
            let timeRemaining = range.upperBound - elapsedTime
            if timeRemaining > 0 {
                TimerFace(elapsedTime: elapsedTime, range: range)
            }
            HStack {
                if isPaused {
                    Image(systemName: "pause.circle")
                }
                Text(timeFormatter.string(from: TimeInterval(max(0, timeRemaining))) ?? "-:--")
            }
            .font(.largeTitle)
        }
        .onChange(of: viewModel.elapsedTime) {
            guard !isPaused else { return }
            elapsedTime += 1
            value = elapsedTime
            if elapsedTime == range.upperBound {
                WKInterfaceDevice.current().play(.success)
                isPaused = true
            } else if elapsedTime == range.lowerBound {
                WKInterfaceDevice.current().play(.failure)
            }
        }
        .onTapGesture {
            isPaused.toggle()
        }
    }
}

struct TimerFace: View {
    let elapsedTime: Int
    let range: ClosedRange<Int>
    
    var body: some View {
        ZStack {
            let start = CGFloat(elapsedTime) / CGFloat(range.upperBound)
            let redEnd = CGFloat(range.lowerBound) / CGFloat(range.upperBound)
            
            BarSegment(start: start, end: 1)
                .fill(Color.green)
            if elapsedTime < range.lowerBound {
                BarSegment(start: start, end: redEnd)
                    .fill(Color.red)
            }
        }
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.purple, lineWidth: 2))
    }
}

struct BarSegment: Shape {
    let start: Double
    let end: Double
    
    nonisolated func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.width * start, y: rect.height))
            path.addLine(to: CGPoint(x: rect.width * start, y: 0))
            path.addLine(to: CGPoint(x: rect.width * end, y: 0))
            path.addLine(to: CGPoint(x: rect.width * end, y: rect.height))
            path.closeSubpath()
        }
    }
}

#Preview {
    @State @Previewable var value: Int = 12
    WorkoutTimer(range: 5...10, value: $value)
        .environmentObject(WatchViewModel.preview)
}
