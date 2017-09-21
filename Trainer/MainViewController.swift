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
    var workoutData:WorkoutData? // set by WorkoutsViewController before segway

    var workout:Workout?

    // outlets to display elements
    @IBOutlet weak var lblDuration: UILabel!
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var btnStart: UIBarButtonItem!
    
    @IBOutlet weak var lblTimeElapsed: UILabel!
    @IBOutlet weak var lblIntervalTimeToGo: UILabel!
    @IBOutlet weak var lblActivity: UILabel!
    @IBOutlet weak var lblTimeToGo: UILabel!
    
    let defs = UserDefaults.standard

    // time tracking parameters
    var timer:Timer = Timer()
    
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
        if workout == nil && workoutData != nil {
            workout = Workout(data: workoutData!)
            if let remaining = workout?.endTime?.timeIntervalSinceNow {
                if remaining > 0.0 {
                    timer = Timer.scheduledTimer(timeInterval: 1, target: self,
                                                 selector: #selector(ViewController.processTimer),
                                                 userInfo: nil, repeats: true)
                    timer.fire()
                    btnStart.title = "Pause"
                }
            }
        }
        fillLabels()
    }

    func fillLabels() {
        lblDescription.text = workout?.description
        lblDuration.text = "\(Int((workout?.duration)!) / TimeInterval.secondsPerMinute)"
        updateLabels()

    }
    override func viewWillAppear(_ animated: Bool) {
        fillLabels()
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
        //content.sound = UNNotificationSound.default()
        content.sound = UNNotificationSound(named: "clong.caf")
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
        if (now < workout!.endTime!) {
            workout!.update()
            updateLabels()
        } else {
            timer.invalidate()
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            AudioServicesPlayAlertSound(SystemSoundID(1005))
        }
    }
    // Update the labels
    func updateLabels() {
        lblTimeToGo.text = workout!.ttg.format()
        lblTimeElapsed.text = workout!.elapsed.format()
        lblActivity.text = workout!.currentPhase.activity
        lblIntervalTimeToGo.text = workout!.currentPhase.ttg.format()
    }
    // Start or pause the workout
    @IBAction func controlWorkout(_ sender: Any) {
        if let workout = workout {
            if !timer.isValid {
                if workout.startTime == nil {
                    workout.start()
                    workoutData?.last = workout.endTime
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
                btnStart.title = "Pause"
            }
            else {
                btnStart.title = "Resume"
                timer.invalidate()
                workout.pause()
            }
        }
    }
    // Restart the workout
    @IBAction func resetTime(_ sender: Any) {
        if let workout = workout {
            workout.start()
            createNotifications(workout)
        }
    }
    // Prepare to edit the workout
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let pvc = segue.destination as! PhasesViewController
        pvc.workout = workoutData
    }
}

