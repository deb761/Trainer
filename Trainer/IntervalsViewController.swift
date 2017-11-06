//
//  PhasesViewController.swift
//  Trainer
//
//  Created by Deborah Engelmeyer on 9/14/17.
//  Copyright © 2017 The Inquisitive Introvert. All rights reserved.
//

import UIKit

class IntervalsViewController: UITableViewController {

    // This is set by the view seguing to this view
    var intervals:Intervals!
    
    let segments:[String] = ["Repeats", "Phases"]
    let repeatSection = 0
    let phaseSection = 1

    @IBOutlet weak var lblRepeats: UILabel!
    @IBOutlet weak var stepRepeat: UIStepper!

    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.isToolbarHidden = false
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // return the number of sections
        return segments.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        switch (section) {
        case phaseSection:
            if let phases = intervals?.phases {
                return phases.count
            }
        default:
            return 1
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: "intervalHeader") ?? UITableViewHeaderFooterView(reuseIdentifier: "intervalHeader")
        
        cell.textLabel?.text = segments[section]
        return cell
    }
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30.0
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        var cell:UITableViewCell
        // Configure the cell...
        if indexPath.section == repeatSection {
            cell = tableView.dequeueReusableCell(withIdentifier: "repeatCell", for: indexPath)
            if let cell = cell as? RepeatCell {
                cell.lblRepeats.text = "\(intervals.repeats)"
            }
            return cell
        }
        cell = tableView.dequeueReusableCell(withIdentifier: "phaseCell", for: indexPath)
        if let cell = cell as? PhaseCell {
            cell.accessoryType = .disclosureIndicator
            if let phase = intervals?.phases?[indexPath.row] as? Phase {
                cell.detailTextLabel?.text = (phase.duration as TimeInterval).format()
                cell.textLabel?.text = phase.activity?.name
            }
            else {
                cell.detailTextLabel?.text = "5:00"
                cell.textLabel?.text = "Brisk Walk \(indexPath.section), \(indexPath.row)"
            }
        }
        return cell
    }
    // Increment or decrement the number of repeats
    @IBAction func changeRepeats(_ sender: Any) {
        if let stepper = sender as? UIStepper {
            intervals.repeats = Int16(Int(stepper.value))
            tableView.reloadSections(IndexSet([0]), with: .automatic)
        }
    }
    
    // Allow editing of the table view for the phase section only
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return indexPath.section == phaseSection
    }


    // Delete phases from the intervals
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            if let phase = intervals.phases?[indexPath.row] as? Phase {
                if DataAccess.delete(phase) {
                    tableView.deleteRows(at: [indexPath], with: .fade)
                }
            }
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
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


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Pass the selected object to the new view controller.
        let vc = segue.destination as! PhaseViewController
        if segue.identifier == "addPhase" {
            vc.phase = DataAccess.addPhase("Phase", to:intervals)
        }
        else if let indexPath = tableView.indexPathForSelectedRow {
            vc.phase = intervals.phases?[indexPath.row] as? Phase
        }
    }


}
