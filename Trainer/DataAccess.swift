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

