//
//  Workout.swift
//  Trainer
//
//  Created by Deborah Engelmeyer on 9/11/17.
//  Copyright © 2017 The Inquisitive Introvert. All rights reserved.
//

import Foundation
import AudioToolbox

class Workout {
    var description:[String] = []
    var duration:TimeInterval = TimeInterval(0)
    var startTime:Date?
    var endTime:Date?
    var phaseNum:Int = 0
    var phases:[Phase] = []
    var currentPhase:Phase

    // Read the plist for this project and fill in the settings
    public init(workout:[String:AnyObject]) {
        phases.append(Phase(definition: workout["warmup"] as! [String:Any]))
        duration = phases[0].duration
        for _ in 1 ... (workout["intervals"]!["repeats"] as! Int) {
            for phase in workout["intervals"]!["phases"] as! [[String : Any]] {
                let interval = Phase(definition: phase)
                phases.append(interval)
                duration += interval.duration
            }
        }
        let cooldown = Phase(definition: workout["cooldown"] as! [String : Any])
        phases.append(cooldown)
        duration += cooldown.duration
        description = workout["description"] as! [String]
        currentPhase = phases[0]
    }
    // Start the workout
    public func start() {
        phaseNum = 0
        currentPhase = phases[phaseNum]

        startTime = Date()
        var interval:TimeInterval = 0.0
        for phase in phases {
            phase.startAt(startTime! + interval)
            interval += phase.duration
        }
        currentPhase.start()
        endTime = startTime! + ttg
    }
    // Update the workout status
    public func update() {
        let now = Date()
        var playAlert = false
        currentPhase = phases[phaseNum]
        while now >= currentPhase.endTime! {
            playAlert = (currentPhase.endTime?.timeIntervalSinceNow)! < TimeInterval(1.0)
            phaseNum += 1
            currentPhase = phases[phaseNum]
        }
        if playAlert {
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            AudioServicesPlayAlertSound(SystemSoundID(1005))
        }
    }
    // TTG stored when the workout is paused
    var timeRemaining:TimeInterval = 0
    public func pause() {
        timeRemaining = ttg
        currentPhase.pause()
    }
    public func resume() {
        endTime = Date() + timeRemaining
        currentPhase.resume()
        for num in phaseNum + 1 ... phases.count - 1 {
            phases[num].startAt(phases[num - 1].endTime!)
        }
    }
    public var ttg:TimeInterval {
        get {
            if let end = endTime {
                return end.timeIntervalSinceNow
            }
            else {
                return duration
            }
        }
    }
    public var elapsed:TimeInterval {
        get {
            return duration - ttg
        }
    }
}
