//
//  TimerManager.swift
//  Workout Tracker
//
//  Created by Daniel Johns on 2025-09-01.
//

import Combine
import Foundation

class TimerManager: ObservableObject {
    var blocks: [(Int, (Int) -> Void)] = []
    var timer: AnyCancellable?
    
    init() {
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { _ in
            self.tick()
        }
    }
    
    func register(for seconds: Int, tickBlock: @escaping (Int) -> Void) {
        blocks.append((seconds, tickBlock))
    }
    
    @objc
    func tick() {
        blocks = blocks.compactMap { block in
            block.1(block.0 - 1)
            
            if block.0 > 0 {
                return (block.0 - 1, block.1)
            } else {
                return nil
            }
        }
    }
}
