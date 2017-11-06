//
//  Workout.swift
//  Trainer
//
//  Created by Deborah Engelmeyer on 9/11/17.
//  Copyright © 2017 The Inquisitive Introvert. All rights reserved.
//

import Foundation
import AudioToolbox
import CoreLocation

protocol WorkoutDelegate {
    func processPhaseChange()
    func processComplete()
}
extension Workout {
    // Text description for a workout
    public override var description:String {
        get {
            var text = "Warmup \(warmup?.activity?.name ?? "") for \(warmup?.duration.format() ?? ""), "
            for object in phases! {
                if let intervals = object as? Intervals {
                    text += intervals.description + ", "
                }
                else if let phase = object as? Phase {
                    text += "\(phase.description), "
                }
            }
            text += "Cooldown \(cooldown?.description ?? "")"
            return text
        }
    }
    // Expected time for a workout or NaN if based only on
    // distance
    public var time:TimeInterval {
        get {
            var duration:TimeInterval = TimeInterval((warmup?.duration)!)
            duration += TimeInterval((cooldown?.duration) ?? 0.0)
            for object in phases! {
                if let phase = object as? Phase {
                    duration += phase.time
                    if duration.isNaN {
                        break
                    }
                }
            }
            return duration
        }
    }
}
// Workout class to track the progress of a workout
class TrackWorkout {
    public var description:String {
        get {
            return data.description
        }
    }
    public var duration:TimeInterval {
        get {
            return data.time
        }
    }
    var startTime:Date?
    private var time:TimeInterval = 0.0// time spent in the workout, available as elapsed
    private var timeStamp:Date? // last update time
    // calculate distance if the user specifies a distance for one or more phases
    var calcDistance:Bool = false
    public var endTime:Date? {
        get {
            return data.endTime
        }
        set {
            data.endTime = newValue
        }
    }
    var phaseNum:Int {
        get {
            return Int(data.phaseNum)
        }
        set {
            data.phaseNum = Int32(newValue)
        }
    }
    var phases:[TrackPhase] = []
    var currentPhase:TrackPhase?
    var data:Workout
    var delegate:WorkoutDelegate
    var running:Bool = false

    /* Read the record for this project and fill in the settings.
       This object will always be created when the workout is not running.
       The main view controller will not allow the user to start another workout
       while one is in progress.
     */
    fileprivate func createPhases(_ data: Workout) {
        phases = []
        let warmup = TrackPhase(data: (data.warmup)!)
        phases.append(warmup)
        for object in data.phases! {
            if let interval = object as? Intervals {
                if let iphases = interval.phases {
                    for rep in 1 ... (interval.repeats) {
                        for phaseData in iphases {
                            let phase = TrackPhase(data: phaseData as! Phase, rep: rep)
                            phases.append(phase)
                        }
                    }
                }
            }
            else if let phaseData = object as? Phase {
                let phase = TrackPhase(data: phaseData)
                phases.append(phase)
            }
        }
        let cooldown = TrackPhase(data: data.cooldown!)
        phases.append(cooldown)
        currentPhase = phases[0]
    }
    
    public init(data:Workout, delegate:WorkoutDelegate) {
        self.data = data
        self.delegate = delegate
    }
    // Start the workout
    public func start(at:Date? = nil) {
        createPhases(data)
        running = true
        phaseNum = 0
        currentPhase = phases[phaseNum]

        if let time = at {
            startTime = time
        }
        else {
            startTime = Date()
        }
        var interval:TimeInterval = 0.0
        for phase in phases {
            phase.startAt(startTime! + interval)
            interval += phase.duration
        }
        currentPhase!.start()
        endTime = startTime! + duration
        data.last = endTime
        timeStamp = Date()
        if let remaining = endTime?.timeIntervalSinceNow {
            if remaining > 0.0 {
                update(distance: 0.0)
            }
        }
    }
    // Calculate a new end time
    func updateEndTime() {
        endTime = currentPhase?.endTime
        if phaseNum + 1 < phases.count {
            for idx in phaseNum + 1 ... phases.count - 1 {
                endTime! += phases[idx].duration
            }
        }
    }
    // Update the workout status
    public func update(distance:Double) {
        // update time
        let now = Date()
        time += now.timeIntervalSince(timeStamp!)
        timeStamp = now
        currentPhase = phases[phaseNum]
        var phaseChanged:Bool = false
        while running {
            currentPhase!.addDistance(distance: distance)
            if !currentPhase!.ended {
                break
            }
            if phaseNum + 1 < phases.count {
                phaseNum += 1
                currentPhase = phases[phaseNum]
                if let endTime = currentPhase!.endTime {
                    if endTime.timeIntervalSinceNow > 0.0 {
                        currentPhase!.startAt(Date())
                        updateEndTime()
                    }
                }
                else {
                    currentPhase!.start()
                }
                phaseChanged = true
            }
            else {
                // workout is over
                running = false
                delegate.processComplete()
                break
            }
        }
        if phaseChanged {
            delegate.processPhaseChange()
        }
    }
    // TTG stored when the workout is paused
    var timeRemaining:TimeInterval = 0
    public func pause() {
        timeRemaining = ttg
        currentPhase?.pause()
    }
    public func resume() {
        timeStamp = Date()
        endTime = timeStamp! + timeRemaining
        currentPhase?.resume()
        if phaseNum + 1 < phases.count {
            for num in phaseNum + 1 ... phases.count - 1 {
                phases[num].startAt(phases[num - 1].endTime!)
            }
        }
    }
    // stop the workout
    public func stop() {
        endTime = nil
        running = false
    }
    public var ttg:TimeInterval {
        get {
            if let remaining = endTime?.timeIntervalSinceNow {
                if remaining > 0.0 {
                    return remaining
                }
            }
            return duration
        }
    }
    // time spent in the workout
    public var elapsed:TimeInterval {
        get {
            return time
        }
    }
    public var ended:Bool {
        get {
            return !running
        }
    }
}
