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
    
    static func addPhase(_ name:String, to:NSManagedObject? = nil) -> PhaseData {
        let context = appDelegate.persistentContainer.viewContext
        let newPhase = NSEntityDescription.insertNewObject(forEntityName: "PhaseData", into: context) as! PhaseData
        newPhase.setValue(300.0, forKey: "duration")
        if let workout = to as? WorkoutData {
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
    static func delete(_ phase:PhaseData) -> Bool {
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

    static func addWorkout(_ name:String) -> WorkoutData {
        let context = appDelegate.persistentContainer.viewContext
        let newWorkout = NSEntityDescription.insertNewObject(forEntityName: "WorkoutData", into: context) as! WorkoutData
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

    static func deleteWorkout(_ workout:WorkoutData) -> Bool {
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

    static func getWorkouts() -> [WorkoutData] {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "WorkoutData")
        request.returnsObjectsAsFaults = false
        var workouts:[WorkoutData] = []
        
        do {
            workouts = try context.fetch(request) as! [WorkoutData]
        } catch let error as NSError {
            print("There was an error getting Workouts: \(error.userInfo)")
        }
        return workouts
    }
    // Create the description for a phase
    static func getDescription(_ phase:PhaseData) -> String {
        if let intervals = phase as? Intervals {
            return getDescription(intervals)
        }
        let duration = phase.duration.format() ?? "*"
        //User region setting
        let locale = Locale.current
        let dist = Measurement(value: phase.distance, unit: UnitLength.meters)
        var distance = ""
        let activity = phase.activity?.name ?? ""
        if locale.usesMetricSystem {
            distance = "\(dist.converted(to: UnitLength.kilometers))"
        }
        else {
            distance = "\(dist.converted(to: UnitLength.miles))"
        }
        switch EndType(rawValue: Int(phase.end))! {
        case EndType.Duration:
            return activity + " for \(duration)"
        case EndType.Distance:
            return activity + " for \(distance)"
        case EndType.Either:
            return activity + " for \(duration) or \(distance)"
        case EndType.Both:
            return activity + " for \(duration) and \(distance)"
        }
        
    }
    // Create the description for a set of intervals
    static func getDescription(_ intervals:Intervals) -> String {
        var description:String = "Repeat "
        for object in intervals.phases! {
            if let phase = object as? PhaseData {
                let duration = phase.duration.format() ?? "*"
                description += "\(phase.activity?.name ?? "") \(duration), "
            }
        }
        description += "\(intervals.repeats) times"
        return description
    }
    // Create the description for a workout
    static func getDescription(_ workout:WorkoutData) -> String {
        var description = "Warmup \(workout.warmup?.activity?.name ?? "") for \(workout.warmup?.duration.format() ?? ""), "
        for object in workout.phases! {
            if let intervals = object as? Intervals {
                description += getDescription(intervals) + ", "
            }
            else if let phase = object as? PhaseData {
                let duration = phase.duration.format() ?? "*"
                description += "\(phase.activity?.name ?? "Not set") \(duration), "
            }
        }
        description += "Cooldown \(workout.cooldown?.activity?.name ?? "") for \(workout.cooldown?.duration.format() ?? "")"
        return description
    }
    // Get the duration for a phase or set of intervals
    static func getDuration(_ phase:PhaseData) -> TimeInterval {
        if let intervals = phase as? Intervals {
            return getDuration(intervals)
        }
        return TimeInterval(phase.duration)
    }
    // Get the duration for a set of intervals
    static func getDuration(_ intervals:Intervals) -> TimeInterval {
        var duration:Double = 0.0
        for object in intervals.phases! {
            if let phase = object as? PhaseData {
                duration += phase.duration
            }
        }
        duration *= Double(intervals.repeats)
        return TimeInterval(duration)
    }
    // Get the duration for a workout
    static func getDuration(_ workout:WorkoutData) -> TimeInterval {
        var duration:TimeInterval = TimeInterval((workout.warmup?.duration)!)
        duration += TimeInterval((workout.cooldown?.duration) ?? 0.0)
        for object in workout.phases! {
            if let phase = object as? PhaseData {
                duration += DataAccess.getDuration(phase)
            }
        }
        return duration
    }
}
