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
    
    let timeSection = 0
    let activitySection = 1

    @IBOutlet weak var timePicker: UIDatePicker!
    
    var sections: [PhaseSection] = [
        PhaseSection(name: "Duration", activities: []),
        PhaseSection(name: "Activity", activities: ["Jog", "Run", "Walk"])
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        activities = DataAccess.getActivities()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == activitySection && !sections[activitySection].collapsed {
            return activities.count
        }
        else if section == timeSection && !sections[timeSection].collapsed {
            return 1
        }
        return 0
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == activitySection {
            let cell = tableView.dequeueReusableCell(withIdentifier: "activityCell", for: indexPath)

            let activity:String = activities[indexPath.row].name!
        
            cell.textLabel?.text = activity

            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "durationCell", for: indexPath) as! DurationPickerCell
        cell.timePicker.countDownDuration = (phase?.duration)!
        return cell
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 2
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == timeSection {
            return 82.0
        }
        return 40.0
    }

    // Update views for Section Headers
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header") as? CollapsibleTableViewHeader ??
            CollapsibleTableViewHeader(reuseIdentifier: "header")
        
        var value = phase?.duration.format()
        if section == activitySection {
            value = phase?.activity?.name
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
        return indexPath.section != timeSection
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
        if indexPath.section == activitySection {
            phase?.activity = activities[indexPath.row]
            tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
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
    
    @IBAction func addActivity(_ sender: Any) {
        let alert = UIAlertController(title: "Add Activity", message: "Name", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Enter Name"
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
