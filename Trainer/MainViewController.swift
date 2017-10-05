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
import CoreLocation
import UserNotifications

class ViewController: UIViewController, CLLocationManagerDelegate {

    var isGrantedNotificationAccess = false
    var workoutData:WorkoutData? // set by WorkoutsViewController before segway

    var workout:Workout?

    // outlets to display elements
    @IBOutlet weak var lblDuration: UILabel!
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var btnStart: UIBarButtonItem!
    @IBOutlet weak var btnEditStop: UIBarButtonItem!
    
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
        NotificationCenter.default.addObserver(self, selector: #selector(self.fillLabels),
                                               name: .UIApplicationDidBecomeActive, object: nil)
    }

    let locationManager = CLLocationManager()
    func enableLocationServices() {
        locationManager.delegate = self
        
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            // Request when-in-use authorization initially
            locationManager.requestAlwaysAuthorization()
            break
            
        case .restricted, .denied:
            // Disable location features
            locationManager.stopUpdatingLocation()
            break
            
        case .authorizedWhenInUse:
            // Enable basic location features
            setupLocationServices()
            break
            
        case .authorizedAlways:
            // Enable any of your app's location features
            setupLocationServices()
            break
        }
    }
    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted, .denied:
            // Disable your app's location features
            locationManager.stopUpdatingLocation()
            break
            
        case .authorizedWhenInUse:
            // Enable only your app's when-in-use features.
            setupLocationServices()
            break
            
        case .authorizedAlways:
            // Enable any of your app's location services.
            setupLocationServices()
            break
            
        case .notDetermined:
            break
            }
    }
    
    func setupLocationServices() {
        locationManager.activityType = .fitness
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }

    @objc func fillLabels() {
        if let data = workoutData {
            workout = Workout(data: data)
            if let remaining = workout?.endTime?.timeIntervalSinceNow {
                if remaining > 0.0 {
                    if !timer.isValid {
                        timer = Timer.scheduledTimer(timeInterval: 1, target: self,
                                                     selector: #selector(ViewController.processTimer),
                                                     userInfo: nil, repeats: true)
                        timer.fire()
                    }
                    btnStart.title = "Pause"
                    btnEditStop.title = "Stop"
                }
            }
        }
        else {
            btnStart.title = "Start"
            btnEditStop.title = "Edit"
        }
        lblDescription.text = workout?.description
        lblDuration.text = "\(Int((workout?.duration)!) / TimeInterval.secondsPerMinute)"
        updateLabels()
        if (workout?.calcDistance)! {
            enableLocationServices()
        }
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
            let interval = workout.phases[phaseNum - 1].endTime!.timeIntervalSinceNow
            if interval < 0 {
                continue
            }
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            addNotification(trigger: trigger, content: content, identifier: "Phase \(phaseNum)")
        }
        // Create complete notification
        let content = UNMutableNotificationContent()
        content.title = "Finished!"
        content.body = "Workout over"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: workout.endTime!.timeIntervalSinceNow, repeats: false)
        addNotification(trigger: trigger, content: content, identifier: "Complete")

        // Create start notification
        let content1 = UNMutableNotificationContent()
        content1.title = "Started!"
        content1.body = "Workout started"
        let trigger1 = UNTimeIntervalNotificationTrigger(timeInterval: 15.0, repeats: false)
        addNotification(trigger: trigger1, content: content1, identifier: "Started")
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
            btnEditStop.title = "Edit"
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
                }
                else {
                    workout.resume()
                }
                if isGrantedNotificationAccess {
                    createNotifications(workout)
                }
                timer = Timer.scheduledTimer(timeInterval: 1, target: self,
                                             selector: #selector(ViewController.processTimer),
                                             userInfo: nil, repeats: true)
                timer.fire()
                btnStart.title = "Pause"
                btnEditStop.title = "Stop"
            }
            else {
                btnStart.title = "Resume"
                timer.invalidate()
                workout.pause()
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
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
    @IBAction func pressedEdit(_ sender: Any) {
        // require a long press to stop the workout, so on short press,
        // segway to the edit page only if title is Edit
        if btnEditStop.title == "Edit" {
            performSegue(withIdentifier: "editWorkout", sender: self)
        }
        else {
            // if the workout is running, get verification from the user
            let alert = UIAlertController(title: "Stop?", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Stop", style: .default, handler: { (action) in
                self.timer.invalidate()
                self.workout?.stop()
                self.btnEditStop.title = "Edit"
                self.btnStart.title = "Start"
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    // Prepare to edit the workout
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let pvc = segue.destination as! PhasesViewController
        pvc.workout = workoutData
    }
}

