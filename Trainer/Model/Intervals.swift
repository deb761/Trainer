//
//  Intervals.swift
//  Trainer
//
//  Created by Deborah Engelmeyer on 11/3/17.
//  Copyright © 2017 The Inquisitive Introvert. All rights reserved.
//

import Foundation

extension Intervals {
    // Text description for intervals
    public override var description:String {
        get {
            var text:String = "Repeat "
            for object in self.phases! {
                if let phase = object as? Phase {
                    text += "\(phase.description), "
                }
            }
            text += "\(self.repeats) times"
            return text
        }
    }
    // Expected time for an interval or NaN if based only on
    // distance
    public override var time:TimeInterval {
        get {
            duration = 0.0
            for object in self.phases! {
                if let phase = object as? Phase {
                    duration += phase.duration
                }
            }
            duration *= Double(self.repeats)
            return TimeInterval(duration)
        }
    }
}
