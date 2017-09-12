//
//  Phase.swift
//  Trainer
//
//  Created by Deborah Engelmeyer on 9/9/17.
//  Copyright © 2017 The Inquisitive Introvert. All rights reserved.
//

import Foundation

public class Phase {
    var activity:String
    var duration:TimeInterval
    var elapsed:TimeInterval {
        get {
            return ttg - duration
        }
    }
    var endTime:Date?
    var ttg:TimeInterval {
        get {
            if let end = endTime {
                return end.timeIntervalSinceNow
            }
            else {
                return duration
            }
        }
    }
    // Use when the phase is paused
    var timeRemaining:TimeInterval = 0.0
    static let secondsPerMinute = 60
    
    public init(definition:[String:Any]) {
        activity = definition["activity"] as! String
        duration = TimeInterval(definition["duration"] as! Int * Phase.secondsPerMinute)
    }
    // Set the phase endTime
    public func startAt(_ start:Date) {
        endTime = start + self.duration
    }
    // Start the phase
    public func start() {

    }
    // Resume the phase
    public func resume() {
        endTime = Date() + timeRemaining
    }
    // Update the phase ttg
    public func pause() {
        timeRemaining = ttg
    }
}
