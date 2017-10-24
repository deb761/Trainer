//
//  Phase.swift
//  Trainer
//
//  Created by Deborah Engelmeyer on 9/9/17.
//  Copyright © 2017 The Inquisitive Introvert. All rights reserved.
//

import Foundation

// Use an enum to define how a phase ends: Duration met, Distance met,
// either Duration or Distance met, or both Duration and Distance met
public enum EndType:Int {
    case Duration = 0, Distance, Either, Both
}
// Phase class to track the beginning, end, and progress of a phase
public class TrackPhase {
    // Database record for the phase
    var data:Phase!
    var endType:EndType = EndType.Duration
    var activity:String = ""
    var duration:TimeInterval = 0.0
    var distance:Double { // distance in meters
        get {
            return data.distance
        }
        set {
            data.distance = newValue
        }
    }
    var traveled:Double { // distance traveled in phase
        get {
            return data.traveled
        }
        set {
            data.traveled = newValue
        }
    }
    var elapsed:TimeInterval {
        get {
            return ttg - duration
        }
    }
    var endTime:Date? {
        get {
            return data.endTime
        }
        set {
            data.endTime = newValue
        }
    }
    var ttg:TimeInterval {
        get {
            if let remaining = endTime?.timeIntervalSinceNow {
                if remaining > 0.0 {
                    return remaining
                }
            }
            return duration
        }
    }
    let locale = Locale.current
    var remaining:String {
        get {
            var dist = Measurement(value: distance - traveled, unit: UnitLength.meters)
            if locale.usesMetricSystem {
                dist = dist.converted(to: UnitLength.kilometers)
            }
            else {
                dist = dist.converted(to: UnitLength.miles)
            }
            let formatter = MeasurementFormatter()
            formatter.numberFormatter.maximumFractionDigits = 1
            let distStr = formatter.string(from: dist)
            switch endType {
            case EndType.Duration:
                return ttg.format() ?? "0:00"
            case EndType.Distance:
                return distStr
            case EndType.Either:
                return "\(ttg.format() ?? "0:00") or \(distStr)"
            case EndType.Both:
                return "\(ttg.format() ?? "0:00") and \(distStr)"
            }
        }
    }
    var ended:Bool {
        get {
            var timePassed = false
            if let remaining = endTime?.timeIntervalSinceNow {
                timePassed = remaining <= 0.0
            }
            switch endType {
            case EndType.Duration:
                return timePassed
            case EndType.Distance:
                return traveled >= distance
            case EndType.Either:
                return timePassed || (traveled >= distance)
            case EndType.Both:
                return timePassed && (traveled >= distance)
            }
        }
    }
    // Use when the phase is paused
    private var timeRemaining:TimeInterval = 0.0
    
    public init(data:Phase, rep:Int16 = 0) {
        self.data = data
        endType = EndType(rawValue: Int(data.end)) ?? EndType.Duration
        if let name = data.activity?.name {
            activity = name
            if rep > 0 {
                activity += " \(rep)"
            }
        }
        duration = TimeInterval(data.duration)
    }
    // Set the phase endTime
    public func startAt(_ start:Date) {
        endTime = start + self.duration
        traveled = 0.0
    }
    // Start the phase
    public func start() {
        endTime = Date() + self.duration
    }
    // Resume the phase
    public func resume() {
        endTime = Date() + timeRemaining
        timeRemaining = 0.0
    }
    // Store the phase ttg
    public func pause() {
        if endType == EndType.Distance {
            timeRemaining = 42.0
        }
        else {
            timeRemaining = ttg
        }
    }
    // Update the distance traveled when the phase is not paused
    public func addDistance(distance:Double) {
        if timeRemaining == 0.0 {
            traveled += distance
        }
    }
}
