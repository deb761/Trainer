//
//  PhasesViewController.swift
//  Trainer
//
//  Created by Deborah Engelmeyer on 9/14/17.
//  Copyright © 2017 The Inquisitive Introvert. All rights reserved.
//

import UIKit

class PhasesViewController: UITableViewController {

    // This is set by the view seguing to this view
    var workout:Workout!
    
    enum Section: Int {
        case name = 0, warmup, workout, cooldown
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.isToolbarHidden = false
        self.hideKeyboardWhenTappedAround()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // return the number of sections
        return 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        switch Section(rawValue: section)! {
        case .workout:
            if let phases = workout?.phases {
                return phases.count
            }
        default:
            return 1
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: "phaseHeader") ?? UITableViewHeaderFooterView(reuseIdentifier: "phaseHeader")
        
        cell.textLabel?.text = "\(Section(rawValue: section) ?? Section.name)".capitalized
        return cell
    }
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30.0
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = Section(rawValue: indexPath.section)!
        var cell:UITableViewCell
        
        if section != .name {
            cell = tableView.dequeueReusableCell(withIdentifier: "phaseCell", for: indexPath)
        }
        else {
            cell = tableView.dequeueReusableCell(withIdentifier: "nameCell", for: indexPath)
        }

        // Configure the cell...
        cell.accessoryType = .disclosureIndicator
        var phase:Phase?
        
        switch section {
        case .name:
            cell.accessoryType = .none
        case .warmup:
            phase = workout?.warmup
        case .cooldown:
            phase = workout?.cooldown
        default:
            phase = workout?.phases?[indexPath.row] as? Phase
        }
        
        if let phase = phase {
            let duration = phase.time
            if !duration.isNaN {
                cell.detailTextLabel?.text = duration.format()
            }
            else {
                cell.detailTextLabel?.text = ""
            }

            cell.textLabel?.text = phase.description
        }
        else if let cell = cell as? WorkoutNameCell {
            cell.txtName.text = workout.name
            if let last = workout.last {
                cell.lblLast.text = last.format()
            }
            else {
                cell.lblLast.text = "Never"
            }
        }
        
        return cell
    }
    

    @IBAction func nameChanged(_ sender: Any) {
        if let field = sender as? UITextField {
            workout.name = field.text
        }
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return indexPath.section == Section.workout.rawValue
    }


    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            if let phase = workout.phases?[indexPath.row] as? Phase {
                if DataAccess.delete(phase) {
                    //tableView.reloadSections(IndexSet([phasesSection]), with: .automatic)
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
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = Section(rawValue: indexPath.section)!
        switch section {
        case .workout:
            if (workout.phases?[indexPath.row] as? Intervals) != nil {
                performSegue(withIdentifier: "editIntervals", sender: self)
            }
            else {
                performSegue(withIdentifier: "editPhase", sender: self)
            }
        case .name:
            break
        default:
            performSegue(withIdentifier: "editPhase", sender: self)
        }
    }
    // Ask the user if he/she wants to add an interval set or a phase
    @IBAction func addPhasePressed(_ sender: UIBarButtonItem) {
        // Create action view
        let alert = UIAlertController(title: "Add Phase", message: "Select Phase Type", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Phase", style: .default, handler: { (action) in
            self.performSegue(withIdentifier: "addPhase", sender: self)
        }))
        alert.addAction(UIAlertAction(title: "Intervals", style: .default, handler: { (action) in
            self.performSegue(withIdentifier: "addIntervals", sender: self)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Pass the selected object to the new view controller.
        switch segue.identifier! {
        case "addPhase":
            let vc = segue.destination as! PhaseViewController
            vc.phase = DataAccess.addPhase("Phase")
            vc.phase?.workout = self.workout

        case "addIntervals":
            let vc = segue.destination as! IntervalsViewController
            vc.intervals = DataAccess.addIntervals()
            vc.intervals?.workout = self.workout

        default:
            if let indexPath = tableView.indexPathForSelectedRow {
                if let vc = segue.destination as? PhaseViewController {
                    let section = Section(rawValue: indexPath.section)!
                    switch section {
                    case .warmup:
                        vc.phase = workout.warmup
                    case .cooldown:
                        vc.phase = workout.cooldown
                    default:
                        vc.phase = workout.phases?[indexPath.row] as? Phase
                    }
                }
                else if let vc = segue.destination as? IntervalsViewController{
                    vc.intervals = workout.phases?[indexPath.row] as? Intervals
                }
            }
        }
    }


}
