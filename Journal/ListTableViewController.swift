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
                                        
        self.navigationController?.navigationBarHidden = true
        tabBarController?.navigationItem.leftBarButtonItem = self.editButtonItem()
        tabBarController?.title = "List"
        //tabBarController?.tabBar.alpha = 0.9 // Can make tab bar translucent
        
        // Theme
        Theme.setup(withNavigationController: tabBarController?.navigationController)

        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(ListTableViewController.insertNewEntry(_:)))
        tabBarController?.navigationItem.rightBarButtonItem = addButton
        
        if let split = self.splitViewController {
            split.view.backgroundColor = UIColor.whiteColor()
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(ListTableViewController.preferredContentSizeChanged(_:)),
                                                         name: UIContentSizeCategoryDidChangeNotification,
                                                         object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(ListTableViewController.persistentStoreCoordinatorStoresDidChange(_:)),
                                                         name: NSPersistentStoreCoordinatorStoresDidChangeNotification,
                                                         object: nil)
    }

    override func viewWillAppear(animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
        super.viewWillAppear(animated)
        
        tabBarController?.navigationController?.navigationBarHidden = false
        
        if JournalVariables.userIsAuthenticated {
            tableView.hidden = false
        }
        
        // Check for changes in iCloud
        coreDataStack.updateContextWithUbiquitousContentUpdates = true
    }
    
    override func viewDidAppear(animated: Bool) {
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
    
    @IBAction func insertNewEntry(sender: UIBarButtonItem) {
        performSegueWithIdentifier(Storyboard.AddEntrySegueIdentifier, sender: sender)
    }

    

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier != Storyboard.SignInSegueIdentifier {
            let controller = (segue.destinationViewController as! UINavigationController).topViewController as! EntryViewController
            
            if segue.identifier == Storyboard.AddEntrySegueIdentifier {                
                controller.title = "New Entry"
                controller.addEntry = true
                controller.coreDataStack = coreDataStack
            } else if segue.identifier == Storyboard.ShowDetailSegueIdentifier {
                controller.coreDataStack = coreDataStack
                
                if let indexPath = tableView.indexPathForSelectedRow {
                    if let entry = fetchedResultsController.objectAtIndexPath(indexPath) as? Entry {
                        controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                        controller.navigationItem.leftItemsSupplementBackButton = true
                        controller.entry = entry
                    }
                }
            }
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! ListTableViewCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == .Delete {
            let entry = fetchedResultsController.objectAtIndexPath(indexPath) as? Entry
            if let entry = entry {
                coreDataStack.managedObjectContext.deleteObject(entry)
                coreDataStack.saveContext()
                
                // Send notification
                NSNotificationCenter.defaultCenter().postNotificationName(EntryWasDeletedNotificationKey, object: entry)
            }
        }
    }


    // MARK: - Fetched results controller

    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchedResultsController = Entry.getFetchedResultsController(coreDataStack)
        fetchedResultsController.delegate = self
        _fetchedResultsController = fetchedResultsController
        
        return _fetchedResultsController!
    }    
    var _fetchedResultsController: NSFetchedResultsController? = nil

    
    
    // MARK: - Notification Handling 
    
    // Not working on simulator - http://www.openradar.me/radar?id=6083508816576512 
    @objc private func preferredContentSizeChanged(notification: NSNotification) {
        print("preferredContentSizeChanged")
        tableView.reloadData()
    }
    
    @objc private func persistentStoreCoordinatorStoresDidChange(notification: NSNotification) {
        _fetchedResultsController = nil
        tableView.reloadData()
    }
    
    
    // MARK: - Helper Methods
    
    private func configureCell(cell: ListTableViewCell, atIndexPath indexPath: NSIndexPath) {
        if let entry = fetchedResultsController.objectAtIndexPath(indexPath) as? Entry {
            if let entryText = entry.attributed_text {
                cell.entryTextLabel.text = entryText.string
            }
            
            if let entryDate = entry.created_at {
                let formatter = NSDateFormatter()
                formatter.dateFormat = "dd"
                cell.dayLabel.text = formatter.stringFromDate(entryDate)
                formatter.dateFormat = "MMM yyyy"
                cell.monthYearLabel.text = formatter.stringFromDate(entryDate)
            }
        }
    }
    
}


extension ListTableViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete:
            self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Update:
            //self.configureCell(tableView.cellForRowAtIndexPath(indexPath!)!, atIndexPath: indexPath!)
            self.configureCell(tableView.cellForRowAtIndexPath(indexPath!) as! ListTableViewCell, atIndexPath: indexPath!)
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
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