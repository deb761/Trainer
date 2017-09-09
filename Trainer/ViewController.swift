//
//  ViewController.swift
//  Trainer
//
//  Created by Deborah Engelmeyer on 9/9/17.
//  Copyright © 2017 The Inquisitive Introvert. All rights reserved.
//

import UIKit
import AudioToolbox

class ViewController: UIViewController {

    var workout:[String:AnyObject] = [:]
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
    
    // time tracking parameters
    var timer:Timer = Timer()
    var duration:TimeInterval = TimeInterval(0)
    var startTime:Date?
    var endTime:Date?
    var elapsed:TimeInterval = TimeInterval(0)
    var ttg:TimeInterval = TimeInterval(0)
    var phaseNum:Int = 0
    var phases:[Phase] = []
    var phase:Phase?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.readPlist()
        initWorkout()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // Read the plist for this project and fill in the settings
    func readPlist() {
        var format = PropertyListSerialization.PropertyListFormat.xml //format of the property list
        let plistPath:String? = Bundle.main.path(forResource: "workout", ofType: "plist")!
        let plistXML = FileManager.default.contents(atPath: plistPath!)!
        do {
            workout = try PropertyListSerialization.propertyList(from: plistXML, options: .mutableContainersAndLeaves, format: &format)
                as! [String:AnyObject]
            phases.append(Phase(definition: workout["warmup"] as! [String : Any]))
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
            let description = workout["description"] as! [String]
            lblWarmup.text = description[0]
            lblInterval.text = description[1]
            lblRepeats.text = description[2]
            lblCooldown.text = description[3]
            lblDuration.text = "\(Int(duration / 60.0))"
        }
        catch {
            print("Error reading plist: \(error), format: \(format)")
        }
    }
    // Initialize the workout
    func initWorkout() {
        phaseNum = 0
        phase = phases[phaseNum]
        ttg = duration
        elapsed = TimeInterval(0)
        updateLabels()
    }
    @objc func processTimer() {
        let now = Date()
        if (now < endTime!) {
            phase = phases[phaseNum]
            if now >= phase!.endTime! {
                phaseNum += 1
                phase = phases[phaseNum]
                phase!.Start()
                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                AudioServicesPlayAlertSound(SystemSoundID(1005))
            }
            else {
                phase!.Update()
            }
            ttg = endTime!.timeIntervalSinceNow
            elapsed = duration - ttg
            updateLabels()
        } else {
            timer.invalidate()
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            AudioServicesPlayAlertSound(SystemSoundID(1005))
        }
    }
    // Update the labels
    func updateLabels() {
        lblTimeToGo.text = ttg.format()
        lblTimeElapsed.text = elapsed.format()
        lblActivity.text = phase!.activity
        lblIntervalTimeToGo.text = phase!.ttg.format()
    }
    // Start or pause the workout
    @IBAction func controlWorkout(_ sender: Any) {
        if !timer.isValid {
            if startTime == nil {
                startTime = Date()
                phase!.Start()
            }
            else {
                phase!.Resume()
            }
            endTime = Date() + ttg
            timer = Timer.scheduledTimer(timeInterval: 1, target: self,
                                         selector: #selector(ViewController.processTimer),
                                         userInfo: nil, repeats: true)
            timer.fire()
            btnStart.setTitle("Pause", for: .normal)
        }
        else {
            btnStart.setTitle("Resume", for: .normal)
            timer.invalidate()
        }
        
    }
    // Restart the workout
    @IBAction func resetTime(_ sender: Any) {
        initWorkout()
        phases[0].Start()
        endTime = Date() + ttg
        phase!.Start()
    }
}

