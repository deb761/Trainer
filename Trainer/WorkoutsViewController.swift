//
//  WorkoutsViewController.swift
//  Trainer
//
//  Created by Deborah Engelmeyer on 9/14/17.
//  Copyright © 2017 The Inquisitive Introvert. All rights reserved.
//

import UIKit
import CoreData

class WorkoutsViewController: UITableViewController {

    var workouts:[WorkoutData] = []
    // connect to core data
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        navigationController?.isToolbarHidden = false
        
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "WorkoutData")
        request.returnsObjectsAsFaults = false
        
        do {
            workouts = try context.fetch(request) as! [WorkoutData]
        } catch {
            print("Couldn't fetch results")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 4
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 96
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "workout cell", for: indexPath) as? WorkoutCell
        
        if let cell = cell {
            cell.lblTitle?.text = "Workout \(indexPath)"
            cell.lblDuration?.text = "45:00"
            cell.lblDescription?.text = "This is a great workout!"
            cell.lblLast?.text = "02/10/17"
            cell.accessoryType = .disclosureIndicator
        }
        return cell!
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

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
        // Get the new view controller using segue.destinationViewController.
        let pvc = segue.destination as! PhasesViewController
        // Pass the selected object to the new view controller.
        if segue.identifier == "add workout" {
            let context = appDelegate.persistentContainer.viewContext
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Activity")
            request.returnsObjectsAsFaults = false
            request.predicate = NSPredicate(format: "name == %@", "Walk")

            do {
                let results = try context.fetch(request) as! [Activity]
                let walk = results[0]
                pvc.workout = NSEntityDescription.insertNewObject(forEntityName: "WorkoutData", into: context) as! WorkoutData

                pvc.workout.warmup = easyPhase(context: context, walk: walk)
                pvc.workout.cooldown = easyPhase(context: context, walk: walk)
            } catch {
                print("Couldn't fetch results")
            }
        }
    }
    
    func easyPhase(context:NSManagedObjectContext, walk:Activity) -> PhaseData {
        let phase = NSEntityDescription.insertNewObject(forEntityName: "PhaseData", into: context) as! PhaseData
        phase.activity = walk
        phase.duration = 300.0
        return phase
    }

}
