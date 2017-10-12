//
//  PhaseViewController.swift
//  Trainer
//
//  Created by Deborah Engelmeyer on 9/14/17.
//  Copyright © 2017 The Inquisitive Introvert. All rights reserved.
//

import UIKit

class PhaseViewController: UITableViewController {
        
    var activities:[Activity] = []
    var phase:PhaseData?
    var distance:Measurement<UnitLength>?
    
    //User region setting
    let locale = Locale.current

    enum SectionEnum:Int {
        case End = 0, Activity, Duration, Distance
    }

    var sections: [PhaseSection] = [
        PhaseSection(name: "End Type"),
        PhaseSection(name: "Activity"),
        PhaseSection(name: "Duration"),
        PhaseSection(name: "Distance")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        activities = DataAccess.getActivities()
        self.hideKeyboardWhenTappedAround()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let dist = phase?.distance {
            distance = Measurement(value: dist, unit: UnitLength.meters)
                
            if locale.usesMetricSystem {
                distance = distance!.converted(to: .kilometers)
            }
            else {
                distance = distance!.converted(to: .miles)
            }
        }
        if phase?.activity == nil {
            sections[SectionEnum.Activity.rawValue].collapsed = false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        /*if (phase?.end)! < 2 {
            return 3
        }*/
        return 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch SectionEnum(rawValue: section)! {
        
        case SectionEnum.Activity:
            if !sections[section].collapsed {
                return activities.count
            }
        
        default:
            if !sections[section].collapsed {
                return 1
            }
        }
        return 0
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch SectionEnum(rawValue: indexPath.section)! {
        case SectionEnum.End:
            let cell = tableView.dequeueReusableCell(withIdentifier: "phaseEnd") as! PhaseEndCell
            cell.endTypes.selectedSegmentIndex = Int(phase?.end ?? 0)
            return cell
            
        case SectionEnum.Activity:
            let cell = tableView.dequeueReusableCell(withIdentifier: "activityCell", for: indexPath)

            let activity:String = activities[indexPath.row].name!
        
            cell.textLabel?.text = activity

            return cell
       
        case SectionEnum.Duration:
            let cell = tableView.dequeueReusableCell(withIdentifier: "durationCell", for: indexPath) as! DurationPickerCell
            cell.timePicker.countDownDuration = (phase?.duration)!
            return cell
            
        case SectionEnum.Distance:
            let cell = tableView.dequeueReusableCell(withIdentifier: "distanceCell", for: indexPath) as! DistanceCell
            if EndType(rawValue: Int(phase?.end ?? 0)) == EndType.Duration {
                cell.txtDistance.text = ""
            }
            else if let dist = distance {
                cell.txtDistance.text = "\(dist.value)"
            }
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 2
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == SectionEnum.Duration.rawValue {
            return 216.0
        }
        return 40.0
    }

    // Update views for Section Headers
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header") as? CollapsibleTableViewHeader ??
            CollapsibleTableViewHeader(reuseIdentifier: "header")
        
        var value:String?

        switch SectionEnum(rawValue: section)! {
        
        case .End:
            value = "\(EndType(rawValue: Int(phase?.end ?? 0)) ?? EndType.Duration)"
 
        case .Activity:
            value = phase?.activity?.name
            
        case .Duration:
            if EndType(rawValue: Int(phase?.end ?? 0)) == EndType.Distance {
                value = "Not used"
            }
            else {
                value = phase?.duration.format()
            }
            
        case .Distance:
            if EndType(rawValue: Int(phase?.end ?? 0)) == EndType.Duration {
                value = "Not used"
            }
            else if let dist = distance {
                value = "\(dist)"
            }
            else {
                value = "Not set"
            }
        }
        header.textLabel?.text = "\(sections[section].name): \(value ?? "")"
        header.arrowLabel.text = ">"
        header.setCollapsed(sections[section].collapsed)
        
        header.section = section
        header.delegate = self
        
        return header
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44.0
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1.0
    }
    @IBAction func timeChanged(_ sender: Any) {
        if let tp = sender as? UIDatePicker {
            phase?.duration = tp.countDownDuration
            tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        }
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return indexPath.section == SectionEnum.Activity.rawValue
    }


    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            if DataAccess.deleteActivity(activities[indexPath.row]) {
                activities.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == SectionEnum.Activity.rawValue {
            phase?.activity = activities[indexPath.row]
            tableView.reloadSections(IndexSet(integer: indexPath.section), with: .automatic)
        }
    }
    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    @IBAction func endTypeChanged(_ sender: UISegmentedControl) {
        phase?.end = Int32(sender.selectedSegmentIndex)
        tableView.reloadData()
    }
    
    @IBAction func changeDistance(_ sender: UITextField) {
        if let distance = Double(sender.text ?? "") {
            if locale.usesMetricSystem {
                self.distance = Measurement(value: distance, unit: UnitLength.kilometers)
            }
            else {
                self.distance = Measurement(value: distance, unit: UnitLength.miles)
            }
            phase?.distance = (self.distance?.converted(to: .meters).value)!
            print(phase?.distance ?? 0)
            tableView.reloadSections(IndexSet(integer: SectionEnum.Distance.rawValue), with: .automatic)
        }
    }
    
    @IBAction func addActivity(_ sender: Any) {
        let alert = UIAlertController(title: "Add Activity", message: "Name", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Enter Name"
            textField.textContentType = UITextContentType.name
            textField.autocapitalizationType = .words
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            let textField = alert.textFields![0]

            if let newActivity = DataAccess.addActivity(textField.text!) {
                self.activities.append(newActivity)
                self.tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
            }
            self.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
}
//
// MARK: - Section Header Delegate
//
extension PhaseViewController: CollapsibleTableViewHeaderDelegate {
    
    func toggleSection(_ header: CollapsibleTableViewHeader, section: Int) {
        let collapsed = !sections[section].collapsed
        
        // Toggle collapse
        sections[section].collapsed = collapsed
        header.setCollapsed(collapsed)
        
        tableView.reloadSections(NSIndexSet(index: section) as IndexSet, with: .automatic)
    }
    
}
