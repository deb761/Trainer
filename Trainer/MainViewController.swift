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
/* Control the user interface for a workout.  Once a workout is started,
   another workout cannot be started until the running workout is stopped
   or completes.
 */

class ViewController: UIViewController, CLLocationManagerDelegate, WorkoutDelegate {
    

    var isGrantedNotificationAccess = false
    var workoutData:Workout? // set by WorkoutsViewController before segway

    static var workout:TrackWorkout?

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
        
        enableLocationServices()
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
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
    }
    // Let the user know that a new phase is beginning
    func processPhaseChange() {
        if let phase = ViewController.workout?.currentPhase {
            let content = createContent(step: phase)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            addNotification(trigger: trigger, content: content, identifier: "Phase \(ViewController.workout?.phaseNum ?? 0)")
        }
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        AudioServicesPlayAlertSound(SystemSoundID(1005))
    }
    // Let the user know the workout is complete
    func processComplete() {
        // Create complete notification
        let content = UNMutableNotificationContent()
        content.title = "Finished!"
        content.body = "Workout over"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        addNotification(trigger: trigger, content: content, identifier: "Complete")
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        AudioServicesPlayAlertSound(SystemSoundID(1005))
        btnStart.title = "Start"
    }
    // Create the workout tracker if this is a different workout, then fill in the labels
    // for the workout
    @objc func fillLabels() {
        if workoutData != ViewController.workout?.data || ViewController.workout == nil {
            if let data = workoutData {
                ViewController.workout = TrackWorkout(data: data, delegate: self)
            }
        }
        if !(ViewController.workout?.ended)! {
            if !timer.isValid {
                timer = Timer.scheduledTimer(timeInterval: 1, target: self,
                                             selector: #selector(ViewController.processTimer),
                                             userInfo: nil, repeats: true)
                timer.fire()
            }
            btnStart.title = "Pause"
            btnEditStop.title = "Stop"
        }
        else {
            btnStart.title = "Start"
            btnEditStop.title = "Edit"
        }
        lblDescription.text = ViewController.workout?.description
        if let duration = ViewController.workout?.duration {
            if duration.isNaN {
                lblDuration.text = "--"
            }
            else {
                lblDuration.text = "\(Int(duration) / TimeInterval.secondsPerMinute)"
            }
        }
        updateLabels()
        if (ViewController.workout?.calcDistance)! {
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
    func createContent(step:TrackPhase) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = step.activity
        content.body = step.data.description
        //content.sound = UNNotificationSound.default()
        content.sound = UNNotificationSound(named: "clong.caf")
        return content
    }
    // Create the notifications for the workout
    func createNotifications(_ workout:TrackWorkout) {
        for phaseNum in 1...workout.phases.count - 1 {
            let phase = workout.phases[phaseNum]
            if phase.endType != EndType.Duration {
                break
            }
            let interval = workout.phases[phaseNum - 1].endTime!.timeIntervalSinceNow
            if interval <= 0 {
                continue
            }
            let content = createContent(step: phase)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            addNotification(trigger: trigger, content: content, identifier: "Phase \(phaseNum)")
        }
        // Create complete notification
        let ttg = workout.endTime!.timeIntervalSinceNow
        if ttg > 0 {
            let content = UNMutableNotificationContent()
            content.title = "Finished!"
            content.body = "Workout over"
            content.sound = UNNotificationSound(named: "clong.caf")
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: workout.endTime!.timeIntervalSinceNow, repeats: false)
            addNotification(trigger: trigger, content: content, identifier: "Complete")
        }

        // Create start notification
        let content1 = UNMutableNotificationContent()
        content1.title = "Started!"
        content1.body = "Workout started"
        let trigger1 = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
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
    // Update the display and play the alert when the timer fires
    @objc func processTimer() {
        
        if (!ViewController.workout!.ended) {
            ViewController.workout!.update(distance: 0.0)
            updateLabels()
        } else {
            timer.invalidate()
            btnEditStop.title = "Edit"
        }
    }
    // Update the labels
    func updateLabels() {
        if let workout = ViewController.workout {
            if !workout.ttg.isNaN {
                lblTimeToGo.text = workout.ttg.format()
            }
            else {
                lblTimeToGo.text = "--"
            }
            lblTimeElapsed.text = workout.elapsed.format()
            lblActivity.text = workout.currentPhase?.activity
            lblIntervalTimeToGo.text = workout.currentPhase?.remaining
        }
    }
    // Start or pause the workout
    @IBAction func controlWorkout(_ sender: Any) {
        if let workout = ViewController.workout {
            if !timer.isValid {
                if !workout.running {
                    workout.start()
                    workoutData?.last = workout.endTime
                }
                else {
                    workout.resume()
                }
                if isGrantedNotificationAccess && CLLocationManager.authorizationStatus() != .authorizedAlways {
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
        if let workout = ViewController.workout {
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
                ViewController.workout?.stop()
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
    var lastLocation:CLLocation?
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if !(ViewController.workout?.running ?? false) {
            return
        }
        var distance:CLLocationDistance = 0.0
        if let last = lastLocation {
            distance = locations[0].distance(from: last)
        }
        if locations.count > 1 {
            for idx in 1 ... locations.count - 1 {
                distance += locations[idx - 1].distance(from: locations[idx])
            }
        }
        lastLocation = locations.last
        ViewController.workout?.update(distance: distance)
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let alert = UIAlertController(title: "Location Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
enum WorkoutError : Error {
    case workoutRunning
}
