//
//  MasterViewController.swift
//  Journal
//
//  Created by Morgan Davison on 3/11/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

import UIKit
import CoreData

let EntryWasDeletedNotificationKey = "com.morgandavison.entryWasDeletedNotificationKey"

class MasterViewController: UITableViewController {

    var coreDataStack: CoreDataStack!
    //var entryViewController: EntryViewController? = nil
    var managedObjectContext: NSManagedObjectContext? = nil
    
    struct Storyboard {
        static var AddEntrySegueIdentifier = "AddEntry"
        static var ShowDetailSegueIdentifier = "ShowDetail"
        static var SignInSegueIdentifier = "SignIn"
    }


    override func viewDidLoad() {
        super.viewDidLoad()
                                
        self.navigationController?.navigationBarHidden = true
        tabBarController?.navigationItem.leftBarButtonItem = self.editButtonItem()
        tabBarController?.title = "Main"
        //tabBarController?.tabBar.alpha = 0.9 // Can make tab bar translucent

        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(MasterViewController.insertNewEntry(_:)))
        tabBarController?.navigationItem.rightBarButtonItem = addButton
        
        if let split = self.splitViewController {
            split.view.backgroundColor = UIColor.whiteColor()
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(MasterViewController.preferredContentSizeChanged(_:)),
                                                         name: UIContentSizeCategoryDidChangeNotification,
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
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
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
    
//    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
////        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
////        let textLabel = cell.textLabel
////        let detailTextLabel = cell.detailTextLabel
////        
////        textLabel?.sizeToFit()
////        detailTextLabel?.sizeToFit()
////        
////        return (textLabel!.frame.height + detailTextLabel!.frame.height) * 1.7
//        
//        return tableView.estimatedRowHeight
//    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        let textLabel = cell.textLabel
        let detailTextLabel = cell.detailTextLabel
        
        textLabel?.sizeToFit()
        detailTextLabel?.sizeToFit()
        
        return (textLabel!.frame.height + detailTextLabel!.frame.height) * 1.7
    }
    

    

    // MARK: - Fetched results controller

    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest = NSFetchRequest()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entityForName("Entry", inManagedObjectContext: self.managedObjectContext!)
        fetchRequest.entity = entity
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "created_at", ascending: false)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        //let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Master")
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch let error as NSError {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
             //print("Unresolved error \(error), \(error.userInfo)")
             //abort()
            
            print("Error: \(error) \n" + "Description: \(error.localizedDescription)")
        }
        
        return _fetchedResultsController!
    }    
    var _fetchedResultsController: NSFetchedResultsController? = nil

    
    
    // MARK: - Notification Handling 
    
    // Not working on simulator - http://www.openradar.me/radar?id=6083508816576512 
    @objc private func preferredContentSizeChanged(notification: NSNotification) {
        print("preferredContentSizeChanged")
        tableView.reloadData()
    }
    
    
    // MARK: - Helper Methods
    
    private func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        let entry = fetchedResultsController.objectAtIndexPath(indexPath) as! Entry
        
        let formatter = NSDateFormatter()
        formatter.dateStyle = .ShortStyle
        formatter.timeStyle = .ShortStyle
        
        if let entryText = entry.attributed_text {
            cell.textLabel?.text = entryText.string
        }
        //cell.detailTextLabel?.text = "\(entry.created_at)"
        cell.detailTextLabel?.text = formatter.stringFromDate(entry.created_at!)
    }
    
}


extension MasterViewController: NSFetchedResultsControllerDelegate {
    
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
            self.configureCell(tableView.cellForRowAtIndexPath(indexPath!)!, atIndexPath: indexPath!)
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