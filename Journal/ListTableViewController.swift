//
//  ListTableViewController.swift
//  Journal
//
//  Created by Morgan Davison on 3/11/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

import UIKit
import CoreData

let EntryWasDeletedNotificationKey = "com.morgandavison.entryWasDeletedNotificationKey"

class ListTableViewController: UITableViewController {

    var coreDataStack: CoreDataStack!
    //var managedObjectContext: NSManagedObjectContext? = nil
    
    struct Storyboard {
        static var AddEntrySegueIdentifier = "AddEntry"
        static var ShowDetailSegueIdentifier = "ShowDetail"
        static var SignInSegueIdentifier = "SignIn"
    }


    override func viewDidLoad() {
        super.viewDidLoad()
                                        
        self.navigationController?.isNavigationBarHidden = true
        tabBarController?.navigationItem.leftBarButtonItem = self.editButtonItem
        tabBarController?.title = "List"
        //tabBarController?.tabBar.alpha = 0.9 // Can make tab bar translucent
        
        // Theme
        Theme.setup(withNavigationController: tabBarController?.navigationController)

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(ListTableViewController.insertNewEntry(_:)))
        tabBarController?.navigationItem.rightBarButtonItem = addButton
        
        if let split = self.splitViewController {
            split.view.backgroundColor = UIColor.white
        }
        
        NotificationCenter.default.addObserver(self,
                                                         selector: #selector(ListTableViewController.preferredContentSizeChanged(_:)),
                                                         name: NSNotification.Name.UIContentSizeCategoryDidChange,
                                                         object: nil)
        
        NotificationCenter.default.addObserver(self,
                                                         selector: #selector(ListTableViewController.persistentStoreCoordinatorStoresDidChange(_:)),
                                                         name: NSNotification.Name.NSPersistentStoreCoordinatorStoresDidChange,
                                                         object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.isCollapsed
        super.viewWillAppear(animated)
        
        tabBarController?.navigationController?.isNavigationBarHidden = false
        
        if JournalVariables.userIsAuthenticated {
            tableView.isHidden = false
        }
        
        // Check for changes in iCloud
        coreDataStack.updateContextWithUbiquitousContentUpdates = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        tableView.reloadData()
        
        // Reset to get latest results
        _fetchedResultsController = nil 
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Actions
    
    @IBAction func insertNewEntry(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: Storyboard.AddEntrySegueIdentifier, sender: sender)
    }

    

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier != Storyboard.SignInSegueIdentifier {
            let controller = (segue.destination as! UINavigationController).topViewController as! EntryViewController
            
            if segue.identifier == Storyboard.AddEntrySegueIdentifier {                
                controller.title = "New Entry"
                controller.addEntry = true
                controller.coreDataStack = coreDataStack
            } else if segue.identifier == Storyboard.ShowDetailSegueIdentifier {
                controller.coreDataStack = coreDataStack
                
                if let indexPath = tableView.indexPathForSelectedRow {
                    if let entry = fetchedResultsController.object(at: indexPath) as? Entry {
                        controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
                        controller.navigationItem.leftItemsSupplementBackButton = true
                        controller.entry = entry
                    }
                }
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ListTableViewCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            let entry = fetchedResultsController.object(at: indexPath) as? Entry
            if let entry = entry {
                coreDataStack.managedObjectContext.delete(entry)
                coreDataStack.saveContext()
                
                // Send notification
                NotificationCenter.default.post(name: Notification.Name(rawValue: EntryWasDeletedNotificationKey), object: entry)
            }
        }
    }


    // MARK: - Fetched results controller

    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchedResultsController = Entry.getFetchedResultsController(coreDataStack)
        fetchedResultsController.delegate = self
        _fetchedResultsController = fetchedResultsController
        
        return _fetchedResultsController!
    }    
    var _fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?

    
    
    // MARK: - Notification Handling 
    
    // Not working on simulator - http://www.openradar.me/radar?id=6083508816576512 
    @objc fileprivate func preferredContentSizeChanged(_ notification: Notification) {
        print("preferredContentSizeChanged")
        tableView.reloadData()
    }
    
    @objc fileprivate func persistentStoreCoordinatorStoresDidChange(_ notification: Notification) {
        _fetchedResultsController = nil
        tableView.reloadData()
    }
    
    
    // MARK: - Helper Methods
    
    fileprivate func configureCell(_ cell: ListTableViewCell, atIndexPath indexPath: IndexPath) {
        if let entry = fetchedResultsController.object(at: indexPath) as? Entry {
            if let entryText = entry.attributed_text {
                cell.entryTextLabel.text = entryText.string
            }
            
            if let entryDate = entry.created_at {
                let formatter = DateFormatter()
                formatter.dateFormat = "dd"
                cell.dayLabel.text = formatter.string(from: entryDate as Date)
                formatter.dateFormat = "MMM yyyy"
                cell.monthYearLabel.text = formatter.string(from: entryDate as Date)
            }
        }
    }
    
}


extension ListTableViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            self.tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            self.tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            if let indexPath = indexPath, let cell =  tableView.cellForRow(at: indexPath) as? ListTableViewCell {
                self.configureCell(cell, atIndexPath: indexPath)
            }
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .fade)
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }
    
    /*
    // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
    // In the simplest, most efficient, case, reload the table view.
    self.tableView.reloadData()
    }
    */

    
}
