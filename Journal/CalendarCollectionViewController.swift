//
//  CalendarCollectionViewController.swift
//  Journal
//
//  Created by Morgan Davison on 3/31/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

import UIKit
import CoreData

class CalendarCollectionViewController: UICollectionViewController {
    
    var coreDataStack: CoreDataStack!
    var calendar = Calendar()
    var entryViewController: EntryViewController? = nil
    var entries = [Entry]()
    var monthsYears = [MonthYear]()
    
    struct Storyboard {
        static let CalendarCellReuseIdentifier = "CalendarCell"
        static let AddEntrySegueIdentifier = "AddEntryFromCalendarCollection"
        static let ShowEntrySegueIdentifier = "ShowEntryFromCalendar"
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(CalendarCollectionViewController.insertNewEntry(_:)))
        navigationItem.rightBarButtonItem = addButton

        // Do any additional setup after loading the view.
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            entryViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? EntryViewController
            split.view.backgroundColor = UIColor.whiteColor()
            //split.delegate = self
        }
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(CalendarCollectionViewController.entryHasSaved(_:)),
            name: HasSavedEntryNotificationKey,
            object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Remove duplicate nav controller
        tabBarController?.navigationController?.navigationBarHidden = true

        setEntries()
        setMonthsYears()
        
        collectionView?.reloadData()
    }
    
    // Redraw view when switches orientation
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        
        coordinator.animateAlongsideTransition({ (context: UIViewControllerTransitionCoordinatorContext) -> Void in
            self.collectionView?.reloadData()
        }) { (context: UIViewControllerTransitionCoordinatorContext) -> Void in
            // complete
        }
        
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
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
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == Storyboard.ShowEntrySegueIdentifier {
            return !calendar.dateIsFuture(forCollectionView: collectionView, withMonthsYears: monthsYears)
        }
        
        return true
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let controller = (segue.destinationViewController as! UINavigationController).topViewController as! EntryViewController
        
        if segue.identifier == Storyboard.AddEntrySegueIdentifier {
            controller.title = "New Entry"
            controller.coreDataStack = coreDataStack
        } else if segue.identifier == Storyboard.ShowEntrySegueIdentifier {
            controller.coreDataStack = coreDataStack
            
            // If there is an entry for selected cell
            if let indexPaths = collectionView?.indexPathsForSelectedItems() {
                let indexPath = indexPaths[0]
                
                if let cell = collectionView?.cellForItemAtIndexPath(indexPath) as? CalendarCollectionViewCell {
                    // get date from cell
                    if let dayString = cell.dayNumberLabel.text {
                        if let day = Int(dayString) {
                            // See if there is an entry for selected cell
                            if let entry = calendar.getEntry(forIndexPath: indexPath, withDay: day, withMonthsYears: monthsYears) {
                                controller.entry = entry
                            } else {
                                // Selected a cell with a date but no entry
                                controller.entryDate = calendar.getDate(forIndexPath: indexPath, withDay: day, withMonthsYears: monthsYears)
                            }
                        }
                    }
                }
            }
        }
    }
    

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return calendar.getNumberOfMonths(forEntries: entries)
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return calendar.numberOfDaysInMonth(forMonthAndYear: monthsYears[section])
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Storyboard.CalendarCellReuseIdentifier, forIndexPath: indexPath) as! CalendarCollectionViewCell
    
        calendar.configureCell(forCell: cell, withIndexPath: indexPath, withMonthsYears: monthsYears)
    
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionElementKindSectionHeader {
            return calendar.getHeaderView(forCollectionView: collectionView, withIndexPath: indexPath, withMonthsYears: monthsYears)
        } else {
            let footerView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "Footer", forIndexPath: indexPath)
            
            return footerView
        }
    }
        

    
    // MARK: - Notification Handling
    
    @objc func entryHasSaved(notification: NSNotification) {
        setEntries()
        setMonthsYears()
        collectionView?.reloadData()
    }
    
    
    // MARK: - Helper Methods
    
    private func setEntries() {
        if let entries = Entry.getAllEntries(coreDataStack) {
            self.entries = entries
        }
    }
    
    private func setMonthsYears() {
        // Empty the array, otherwise it keeps appending every time view loads
        monthsYears.removeAll()
        monthsYears = calendar.getMonthsYears(forEntries: entries)
    }
  
}


extension CalendarCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let width = floor(view.frame.size.width / 7.0)
        return CGSize(width: width, height: width)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        
        return 0
    }
    
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
}

