//
//  ViewController.swift
//  Trainer
//
//  Created by Deborah Engelmeyer on 9/9/17.
//  Copyright © 2017 The Inquisitive Introvert. All rights reserved.
//

import UIKit
import AudioToolbox
import CoreData
import UserNotifications

class ViewController: UIViewController {

    var isGrantedNotificationAccess = false
    var workouts:[Workout] = []
    var currentWorkout:Workout?
    
    // outlets to display elements
    @IBOutlet weak var lblDuration: UILabel!
    @IBOutlet weak var lblWarmup: UILabel!
    @IBOutlet weak var lblInterval: UILabel!
    @IBOutlet weak var lblRepeats: UILabel!
    @IBOutlet weak var lblCooldown: UILabel!
    @IBOutlet weak var btnStart: UIButton!
    
    @IBOutlet weak var lblTimeElapsed: UILabel!
    @IBOutlet weak var lblIntervalTimeToGo: UILabel!
    @IBOutlet weak var lblActivity: UILabel!
    @IBOutlet weak var lblTimeToGo: UILabel!
    
    let defs = UserDefaults.standard

    // time tracking parameters
    var timer:Timer = Timer()
    
    var workoutNum:Int {
        get {
            return defs.integer(forKey: "workoutNum")
        }
        set {
            defs.set(newValue, forKey: "workoutNum")
        }
    }
    
    var completedWorkouts:[Int] {
        get {
            if let array = defs.array(forKey: "completedWorkouts") as? [Int] {
                return array
            }
            else {
                return []
            }
        }
        set {
            defs.set(newValue, forKey: "completedWorkouts")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.isToolbarHidden = false
        // Do any additional setup after loading the view, typically from a nib.
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {
            (granted, error) in
            self.isGrantedNotificationAccess = granted
            if !granted {
                // TODO add alert to complain to user
            }
        }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let newActivity = NSEntityDescription.insertNewObject(forEntityName: "Activity", into: context)
        newActivity.setValue("Jog", forKey: "name")
        do {
            try context.save()
            print("Saved")
        } catch {
            print("There was an error")
        }

        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Activity")
        request.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(request)
        } catch {
            print("Couldn't fetch results")
        }
        self.readPlist()
        currentWorkout = workouts[workoutNum]
        fillDescription(currentWorkout!)
        updateLabels()
    }
    // Read the plist for the workouts and fill in the settings
    func readPlist() {
        var workoutDefs:[[String:AnyObject]] = []
        var format = PropertyListSerialization.PropertyListFormat.xml //format of the property list
        let plistPath:String? = Bundle.main.path(forResource: "workouts", ofType: "plist")!
        let plistXML = FileManager.default.contents(atPath: plistPath!)!
        do {
            workoutDefs = try PropertyListSerialization.propertyList(from: plistXML, options: .mutableContainersAndLeaves, format: &format)
                as! [[String:AnyObject]]
            for def in workoutDefs {
                workouts.append(Workout(workout: def))
            }
        }
        catch {
            print("Error reading plist: \(error), format: \(format)")
        }
    }
    // Fill in the workout description
    func fillDescription(_ workout:Workout) {
        lblDuration.text = "\(Int(workout.duration) / Phase.secondsPerMinute)"
        lblWarmup.text = workout.description[0]
        lblInterval.text = workout.description[1]
        lblRepeats.text = workout.description[2]
        lblCooldown.text = workout.description[3]
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // Create notification content
    func createContent(step:Phase) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = step.activity
        content.body = step.duration.format()!
        return content
    }
    // Create the notifications for the workout
    func createNotifications(_ workout:Workout) {
        for phaseNum in 1...workout.phases.count - 1 {
            let phase = workout.phases[phaseNum]
            let content = createContent(step: phase)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: workout.phases[phaseNum - 1].endTime!.timeIntervalSinceNow, repeats: false)
            addNotification(trigger: trigger, content: content, identifier: "Phase \(phaseNum)")
        }
        let content = UNMutableNotificationContent()
        content.title = "Finished!"
        content.body = "Workout over"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: workout.endTime!.timeIntervalSinceNow, repeats: false)
        addNotification(trigger: trigger, content: content, identifier: "Test")

        let content1 = UNMutableNotificationContent()
        content1.title = "Started!"
        content1.body = "Workout started"
        let trigger1 = UNTimeIntervalNotificationTrigger(timeInterval: 15.0, repeats: false)
        addNotification(trigger: trigger1, content: content1, identifier: "Test")
    }
    // Add notifications for the app
    func addNotification(trigger:UNNotificationTrigger?, content:UNMutableNotificationContent, identifier:String) {
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) {
            (error) in
            if error != nil {
                print("error adding notification:\(String(describing: error?.localizedDescription))")
            }
        }
    }
    @IBAction func showNotice(_ sender: Any) {
        let nc = NotificationCenter.default
        nc.post(name:Notification.Name(rawValue:"MyNotification"),
                object: nil,
                userInfo: ["message":"Hello there!", "date":Date()])
    }
    // Update the display and play the alert when the timer fires
    @objc func processTimer() {
        let now = Date()
        if (now < currentWorkout!.endTime!) {
            currentWorkout!.update()
            updateLabels()
        } else {
            timer.invalidate()
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            AudioServicesPlayAlertSound(SystemSoundID(1005))
        }
    }
    // Update the labels
    func updateLabels() {
        lblTimeToGo.text = currentWorkout!.ttg.format()
        lblTimeElapsed.text = currentWorkout!.elapsed.format()
        lblActivity.text = currentWorkout!.currentPhase.activity
        lblIntervalTimeToGo.text = currentWorkout!.currentPhase.ttg.format()
    }
    // Start or pause the workout
    @IBAction func controlWorkout(_ sender: Any) {
        if let workout = currentWorkout {
            if !timer.isValid {
                if workout.startTime == nil {
                    workout.start()
                    if isGrantedNotificationAccess {
                        createNotifications(workout)
                    }
                }
                else {
                    workout.resume()
                }
                timer = Timer.scheduledTimer(timeInterval: 1, target: self,
                                             selector: #selector(ViewController.processTimer),
                                             userInfo: nil, repeats: true)
                timer.fire()
                btnStart.setTitle("Pause", for: .normal)
            }
            else {
                btnStart.setTitle("Resume", for: .normal)
                timer.invalidate()
                workout.pause()
            }
        }
    }
    // Restart the workout
    @IBAction func resetTime(_ sender: Any) {
        if let workout = currentWorkout {
            workout.start()
            createNotifications(workout)
        }
    }
}

