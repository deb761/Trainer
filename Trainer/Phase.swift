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
    var elapsed:TimeInterval = TimeInterval(0)
    var endTime:Date?
    var ttg:TimeInterval
    static let secondsPerMinute = 60
    
    public init(definition:[String:Any]) {
        activity = definition["activity"] as! String
        duration = TimeInterval(definition["duration"] as! Int * Phase.secondsPerMinute)
        ttg = duration
    }
    // Start the phase
    public func Start() {
        ttg = duration
        elapsed = TimeInterval(0)
        endTime = Date() + ttg
    }
    // Resume the phase
    public func Resume() {
        endTime = Date() + ttg
    }
    // Update the phase ttg
    public func Update() {
        ttg = endTime!.timeIntervalSinceNow
        elapsed = duration - ttg
    }
}
