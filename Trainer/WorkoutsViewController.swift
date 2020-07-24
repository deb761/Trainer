//
//  WorkoutsViewController.swift
//  Trainer
//
//  Created by Deborah Engelmeyer on 9/14/17.
//  Copyright © 2017 The Inquisitive Introvert. All rights reserved.
//

import UIKit
import UIKit

class WorkoutsViewController: UIViewController {
    
    let reuseIdentifier = "reuse-id"
    
    typealias ItemType = Workout

    // Subclassing our data source to supply various UITableViewDataSource methods

class DataSource: UITableViewDiffableDataSource<SectionType, ItemType> {
    
    // MARK: header/footer titles support
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionKind = Section(rawValue: section)
        return sectionKind?.description()
    }
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let sectionKind = Section(rawValue: section)
        return sectionKind?.secondaryDescription()
    }
    
    // MARK: reordering support
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard let sourceIdentifier = itemIdentifier(for: sourceIndexPath) else { return }
        guard sourceIndexPath != destinationIndexPath else { return }
        let destinationIdentifier = itemIdentifier(for: destinationIndexPath)
        
        var snapshot = self.snapshot()

        if let destinationIdentifier = destinationIdentifier {
            if let sourceIndex = snapshot.indexOfItem(sourceIdentifier),
               let destinationIndex = snapshot.indexOfItem(destinationIdentifier) {
                let isAfter = destinationIndex > sourceIndex &&
                    snapshot.sectionIdentifier(containingItem: sourceIdentifier) ==
                    snapshot.sectionIdentifier(containingItem: destinationIdentifier)
                snapshot.deleteItems([sourceIdentifier])
                if isAfter {
                    snapshot.insertItems([sourceIdentifier], afterItem: destinationIdentifier)
                } else {
                    snapshot.insertItems([sourceIdentifier], beforeItem: destinationIdentifier)
                }
            }
        } else {
            let destinationSectionIdentifier = snapshot.sectionIdentifiers[destinationIndexPath.section]
            snapshot.deleteItems([sourceIdentifier])
            snapshot.appendItems([sourceIdentifier], toSection: destinationSectionIdentifier)
        }
        apply(snapshot, animatingDifferences: false)
    }
    
    // MARK: editing support

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let identifierToDelete = itemIdentifier(for: indexPath) {
                var snapshot = self.snapshot()
                snapshot.deleteItems([identifierToDelete])
                apply(snapshot)
            }
        }
    }
}

var dataSource: DataSource!
var tableView: UITableView!

override func viewDidLoad() {
    super.viewDidLoad()
    configureHierarchy()
    configureDataSource()
    configureNavigationItem()
}
}

extension TableViewEditingViewController {

func configureHierarchy() {
    tableView = UITableView(frame: .zero, style: .insetGrouped)
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
        tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
        tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
    ])
}

func configureDataSource() {
    let formatter = NumberFormatter()
    formatter.groupingSize = 3
    formatter.usesGroupingSeparator = true
    
    // data source
    
    dataSource = DataSource(tableView: tableView) { (tableView, indexPath, mountain) -> UITableViewCell? in
        let cell = tableView.dequeueReusableCell(withIdentifier: self.reuseIdentifier, for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = mountain.name
        if let formattedHeight = formatter.string(from: NSNumber(value: mountain.height)) {
            content.secondaryText = "\(formattedHeight)M"
        }
        cell.contentConfiguration = content
        return cell
    }
    
    // initial data
    
    let snapshot = initialSnapshot()
    dataSource.apply(snapshot, animatingDifferences: false)
}

func initialSnapshot() -> NSDiffableDataSourceSnapshot<SectionType, ItemType> {
    let mountainsController = MountainsController()
    let limit = 8
    let mountains = mountainsController.filteredMountains(limit: limit)
    let bucketList = Array(mountains[0..<limit / 2])
    let visited = Array(mountains[limit / 2..<limit])

    var snapshot = NSDiffableDataSourceSnapshot<SectionType, ItemType>()
    snapshot.appendSections([.visited])
    snapshot.appendItems(visited)
    snapshot.appendSections([.bucketList])
    snapshot.appendItems(bucketList)
    return snapshot
}

func configureNavigationItem() {
    navigationItem.title = "UITableView: Editing"
    let editingItem = UIBarButtonItem(title: tableView.isEditing ? "Done" : "Edit", style: .plain, target: self, action: #selector(toggleEditing))
    navigationItem.rightBarButtonItems = [editingItem]
}

@objc
func toggleEditing() {
    tableView.setEditing(!tableView.isEditing, animated: true)
    configureNavigationItem()
}

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "workout cell", for: indexPath) as? WorkoutCell
        
        if let cell = cell {
            let workout = workouts[indexPath.row]
            cell.lblTitle?.text = "Workout \(indexPath.row)"
            if let name = workout.name {
                cell.lblTitle?.text = name
            }
            let duration = workout.time
            if duration.isNaN {
                cell.lblDuration?.text = "--"
            }
            else {
                cell.lblDuration?.text = duration.format() ?? "--"
            }
            cell.lblDescription?.text = workout.description
            cell.lblLast?.text = "Never"
            if let last = workout.last {
                cell.lblLast?.text = last.format()
            }
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


    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            if DataAccess.deleteWorkout(workouts[indexPath.row]) {
                workouts.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                tableView.reloadData()
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
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "addWorkout" {
            let workout = DataAccess.addWorkout("")
            workouts.append(workout)
            let pvc = segue.destination as! PhasesViewController
            pvc.workout = workout
        }
        else if segue.identifier == "showWorkout" {
            // go to main workout view
            let mvc = segue.destination as! ViewController
            mvc.workoutData = workouts[(tableView.indexPathForSelectedRow?.row)!]
        }
        else {
            let pvc = segue.destination as! PhasesViewController
            pvc.workout = workouts[(longPressIndex?.row)!]
        }
    }
    // index position for long press gesture
    var longPressIndex:IndexPath?
    // Send user to WorkoutPhases page on long press
    @IBAction func handleLongPress(_ sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizer.State.began {
            let p = sender.location(in: self.tableView)
            longPressIndex = self.tableView.indexPathForRow(at: p)
            performSegue(withIdentifier: "editWorkout", sender: self)
        }
    }

}
