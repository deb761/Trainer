//
//  ControlData.swift
//  Trainer
//
//  Created by Deborah Engelmeyer on 9/15/17.
//  Copyright © 2017 The Inquisitive Introvert. All rights reserved.
//

import UIKit
import CoreData

class DataAccess {
    static let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    static func save() {
        let context = appDelegate.persistentContainer.viewContext
        do {
            try context.save()
            print("Saved data")
        } catch let error as NSError {
            print("There was an error saving data: \(error.userInfo)")
        }
    }
    static func addActivity(_ name:String) -> Activity? {
        let context = appDelegate.persistentContainer.viewContext
        let newActivity = NSEntityDescription.insertNewObject(forEntityName: "Activity", into: context)
        newActivity.setValue(name, forKey: "name")
        do {
            try context.save()
            print("Saved")
        } catch let error as NSError {
            print("There was an error adding Activity: \(error.userInfo)")
        }
        return newActivity as? Activity
    }

    static func deleteActivity(_ activity:Activity) -> Bool {
        let context = appDelegate.persistentContainer.viewContext
        context.delete(activity)
        do {
            try context.save()
            return true
        } catch let error as NSError {
            print("Error deleting Activity: \(error.userInfo)")
        }
        return false
    }
    
    static func getActivities() -> [Activity] {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Activity")
        request.returnsObjectsAsFaults = false
        var activities:[Activity] = []
        
        do {
            activities = try context.fetch(request) as! [Activity]
        } catch let error as NSError {
            print("There was an error getting activities: \(error.userInfo)")
        }
        return activities
    }
    
    static func addPhase(_ name:String, to:NSManagedObject? = nil) -> Phase {
        let context = appDelegate.persistentContainer.viewContext
        let newPhase = NSEntityDescription.insertNewObject(forEntityName: "Phase", into: context) as! Phase
        newPhase.setValue(300.0, forKey: "duration")
        if let workout = to as? Workout {
            newPhase.workout = workout
        } else if let intervals = to as? Intervals {
            newPhase.intervals = intervals
        }
        do {
            try context.save()
            print("Saved")
        } catch let error as NSError {
            print("There was an error saving a Phase: \(error.userInfo)")
        }
        return newPhase
    }
    static func delete(_ phase:Phase) -> Bool {
        let context = appDelegate.persistentContainer.viewContext
        context.delete(phase)
        do {
            try context.save()
            return true
        } catch let error as NSError {
            print("Error deleting Phase: \(error.userInfo)")
        }
        return false
    }

    static func addIntervals() -> Intervals {
        let context = appDelegate.persistentContainer.viewContext
        let intervals = NSEntityDescription.insertNewObject(forEntityName: "Intervals", into: context)
        intervals.setValue(2, forKey: "repeats")
        do {
            try context.save()
            print("Interval saved")
        } catch let error as NSError {
            print("There was an error saving Intervals: \(error.userInfo)")
        }
        return intervals as! Intervals
    }

    static func addWorkout(_ name:String) -> Workout {
        let context = appDelegate.persistentContainer.viewContext
        let newWorkout = NSEntityDescription.insertNewObject(forEntityName: "Workout", into: context) as! Workout
        newWorkout.setValue(name, forKey: "name")
        newWorkout.warmup = DataAccess.addPhase("Warmup")
        newWorkout.cooldown = DataAccess.addPhase("Cooldown")
        do {
            try context.save()
            print("Saved")
        } catch let error as NSError {
            print("There was an error adding a Workout: \(error.userInfo)")
        }
        return newWorkout
    }

    static func deleteWorkout(_ workout:Workout) -> Bool {
        let context = appDelegate.persistentContainer.viewContext
        context.delete(workout)
        do {
            try context.save()
            return true
        } catch let error as NSError {
            print("Error While Deleting Workout: \(error.userInfo)")
        }
        return false
    }

    static func getWorkouts() -> [Workout] {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Workout")
        request.returnsObjectsAsFaults = false
        var workouts:[Workout] = []
        
        do {
            workouts = try context.fetch(request) as! [Workout]
        } catch let error as NSError {
            print("There was an error getting Workouts: \(error.userInfo)")
        }
        return workouts
    }
}
extension Phase {
    // Text description for a phase
    public override var description:String {
        get {
            let time = self.duration.format() ?? "*"
            //User region setting
            let locale = Locale.current
            let dist = Measurement(value: self.distance, unit: UnitLength.meters)
            var distance = ""
            let activity = self.activity?.name ?? ""
            if locale.usesMetricSystem {
                distance = "\(dist.converted(to: UnitLength.kilometers))"
            }
            else {
                distance = "\(dist.converted(to: UnitLength.miles))"
            }
            switch EndType(rawValue: Int(self.end))! {
            case EndType.Duration:
                return activity + " for \(time)"
            case EndType.Distance:
                return activity + " for \(distance)"
            case EndType.Either:
                return activity + " for \(time) or \(distance)"
            case EndType.Both:
                return activity + " for \(time) and \(distance)"
            }
        }
    }
    // Expected time for a phase or NaN if based only on
    // distance
    @objc public var time:TimeInterval {
        get {
            if self.end == Int32(EndType.Distance.rawValue) {
                return Double.nan
            }
            return TimeInterval(duration)
        }
    }
}
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
