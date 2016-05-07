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
    var entryViewController: EntryViewController? = nil
    var entries = [Entry]()
    var monthsAndYears = [MonthYear]()
    let calendar = NSCalendar.currentCalendar()
    let formatter = NSDateFormatter()
    
    struct Storyboard {
        static let CalendarCellReuseIdentifier = "CalendarCell"
        static let AddEntrySegueIdentifier = "AddEntryFromCalendarCollection"
        static let ShowEntrySegueIdentifier = "ShowEntryFromCalendar"
    }
    
    struct MonthYear {
        var month: Int
        var year: Int
        var entries: [Entry]
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
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Remove duplicate nav controller
        tabBarController?.navigationController?.navigationBarHidden = true

        setEntries()
        setMonthsAndYears()
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
            if let indexPaths = collectionView?.indexPathsForSelectedItems() {
                if let cell = collectionView?.cellForItemAtIndexPath(indexPaths[0]) as? CalendarCollectionViewCell {
                    if let dayString = cell.dayNumberLabel.text {
                        if let day = Int(dayString) {
                            let date = getDate(forIndexPath: indexPaths[0], andDay: day)
                            //let calendar = NSCalendar.currentCalendar()
                            let comparison = calendar.compareDate(date, toDate: NSDate(), toUnitGranularity: .Day)
                            
                            // If selected date is in the future, don't perform segue
                            if comparison == .OrderedDescending {
                                return false
                            }
                        }
                    }
                }
            }
        }
        
        return true
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let tabBarController = (segue.destinationViewController as! UINavigationController).topViewController as! UITabBarController
        //let tabBarNavController = tabBarController.viewControllers![0] as! UINavigationController
        //let controller = tabBarNavController.topViewController as! EntryViewController
        let controller = tabBarController.viewControllers![0] as! EntryViewController
        
        if segue.identifier == Storyboard.AddEntrySegueIdentifier {
            //let controller = (segue.destinationViewController as! UINavigationController).topViewController as! EntryViewController
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
                            if let entry = getEntry(forIndexPath: indexPath, andDay: day) {
                                controller.entry = entry
                            } else {
                                // Selected a cell with a date but no entry
                                controller.entryDate = getDate(forIndexPath: indexPath, andDay: day)
                            }
                        }
                    }
                }
            }
        }
    }
    

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return getNumberOfMonths()
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfDaysInMonth(forMonthAndYear: monthsAndYears[section])
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Storyboard.CalendarCellReuseIdentifier, forIndexPath: indexPath) as! CalendarCollectionViewCell
    
        configureCell(cell, withIndexPath: indexPath)
    
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionElementKindSectionHeader {
            let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "Header", forIndexPath: indexPath) as! CalendarCollectionReusableHeaderView
            
            headerView.backgroundColor = UIColor(red: 230.0/255.0, green: 230.0/255.0, blue: 230.0/255.0, alpha: 1)
            
            let dateFormatter = NSDateFormatter()
            let monthText = dateFormatter.shortMonthSymbols[monthsAndYears[indexPath.section].month - 1]
            let yearText = monthsAndYears[indexPath.section].year
            
            headerView.titleLabel.text = "\(monthText) \(yearText)".uppercaseString
            
            return headerView
        } else {
            let footerView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "Footer", forIndexPath: indexPath)
            
            return footerView
        }
    }
        
    

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */

    
    
    // MARK: - Helper Methods
    
    private func configureCell(cell: CalendarCollectionViewCell, withIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = UIColor.whiteColor()
        
        // Create top border
        let topBorder = UIView(frame: CGRect(x: 0, y: 0, width: cell.frame.size.width + 1, height: 1))
        topBorder.backgroundColor = UIColor.lightGrayColor()
        cell.contentView.addSubview(topBorder)
        
        // Determine if this cell should be empty
        let padding = getPadding(forMonthAndYear: monthsAndYears[indexPath.section])
        var day = 0
        
        if indexPath.row + 1 > padding {
            day = (indexPath.row + 1) - padding
        }
        
        if day > 0 { // Not a blank cell
            cell.dayNumberLabel.text = "\(day)"
            
            //showEntryIfExists(forCell: cell, andIndexPath: indexPath, andDay: day)
            
            // Show entry or mark if today
            setIndication(forCell: cell, andIndexPath: indexPath, andDay: day)
        } else { // Cell is a blank padding cell
            cell.dayNumberLabel.text = ""
        }
    }
    
    private func setEntries() {
        if let entries = Entry.getAllEntries(coreDataStack) {
            self.entries = entries
        }
    }
    
    private func getNumberOfMonths() -> Int {
        let calendar = NSCalendar.currentCalendar()
        
        // Get the number of months between the first and last entry
        if !entries.isEmpty {
            // Get month for last entry
            if let lastEntryDate = entries.last?.created_at {
                let dateComponentsOfLastEntry = calendar.components([.Month, .Year], fromDate: lastEntryDate)
                // Set last date to be the first of the month, as partial months don't get counted
                let modifiedLastDate = calendar.dateFromComponents(dateComponentsOfLastEntry)
                let months = calendar.components(NSCalendarUnit.Month, fromDate: modifiedLastDate!, toDate: entries.first!.created_at!, options: [])
                
                //return months.month
                return months.month + 1 // Need to add one to make sure it includes the last one?
            }
        }
        return 0
    }
    
    private func setMonthsAndYears() {
        // Empty the array, otherwise it keeps appending every time view loads
        monthsAndYears.removeAll()
        
        let calendar = NSCalendar.currentCalendar()
        let monthSpan = getNumberOfMonths()
        
        if let firstEntryDate = entries.first?.created_at {
            let components = calendar.components([.Month, .Year], fromDate: firstEntryDate)
            
            // Create var to hold month component of each item in the loop,
            // Initial value set to first headache
            var nsDateCounter = calendar.dateFromComponents(components)
            
            if monthSpan > 0 {
                for _ in 1...monthSpan {
                    let components = calendar.components([.Month, .Year], fromDate: nsDateCounter!)
                    var entriesArray = [Entry]()
                    
                    for entry in entries {
                        // Get month and year components from the entry
                        let entryComponents = calendar.components([.Month, .Year], fromDate: entry.created_at!)
                        // When they match the outer loop components, add to entry array
                        if (entryComponents.month == components.month) && (entryComponents.year == components.year) {
                            entriesArray.append(entry)
                        }
                    }
                    
                    let monthYear = MonthYear(month: components.month, year: components.year, entries: entriesArray)
                    monthsAndYears.append(monthYear)
                    
                    // decrement nsDateCounter by 1 month
                    nsDateCounter = calendar.dateByAddingUnit(.Month, value: -1, toDate: nsDateCounter!, options: [])
                }
            }
        }
    }
    
    private func numberOfDaysInMonth(forMonthAndYear monthYear: MonthYear) -> Int {
        let calendar = NSCalendar.currentCalendar()
        let date = getNSDateFromComponents(monthYear.year, month: monthYear.month, day: nil)
        let numberOfDaysInMonth = calendar.rangeOfUnit(.Day, inUnit: .Month, forDate: date)
        let padding = getPadding(forMonthAndYear: monthYear)
        
        return numberOfDaysInMonth.toRange()!.last! + padding
    }
    
    private func getNSDateFromComponents(year: Int, month: Int, day: Int?) -> NSDate {
        let calendar = NSCalendar.currentCalendar()
        let components = NSDateComponents()
        components.month = month
        components.year = year
        if let day = day {
            components.day = day
        }
        
        return calendar.dateFromComponents(components)!
    }
    
    private func getPadding(forMonthAndYear monthAndYear: MonthYear) -> Int {
        //let calendar = NSCalendar.currentCalendar()
        
        // Get day of the week for the first day of the month
        let date = getNSDateFromComponents(monthAndYear.year, month: monthAndYear.month, day: 1)
        let components = calendar.components([.Weekday], fromDate: date)
        
        return components.weekday - 1
    }
    
    private func setIndication(forCell cell: UICollectionViewCell, andIndexPath indexPath: NSIndexPath, andDay day: Int) {
        // Indicate entry for this date
        if let _ = getEntry(forIndexPath: indexPath, andDay: day) {
            cell.backgroundColor = UIColor.lightGrayColor()
        }

        // Indicate today
        // TODO: draw a red circle around the number instead of making the background red
        let date = getDate(forIndexPath: indexPath, andDay: day)
        let comparison = calendar.compareDate(date, toDate: NSDate(), toUnitGranularity: .Day)
        if comparison == .OrderedSame {
            cell.backgroundColor = UIColor.redColor()
        }
        
    }
    
    private func getEntry(forIndexPath indexPath: NSIndexPath, andDay day: Int) -> Entry? {
        //let selectedDate = getNSDateFromComponents(monthsAndYears[indexPath.section].year, month: monthsAndYears[indexPath.section].month, day: day)
        let selectedDate = getDate(forIndexPath: indexPath, andDay: day)
        let entriesForThisMonth = monthsAndYears[indexPath.section].entries
        
        for entry in entriesForThisMonth {
            if let entryDate = entry.created_at {
                // Extract the components from the entry date so the hours are the same as the selectedDate
                let entryDateComponents = calendar.components([.Year, .Month, .Day], fromDate: entryDate)
                let entryDateFromComponents = getNSDateFromComponents(entryDateComponents.year, month: entryDateComponents.month, day: entryDateComponents.day)
                
                if entryDateFromComponents == selectedDate {
                    return entry
                }
            }
        }
        
        return nil
    }
    
    private func getDate(forIndexPath indexPath: NSIndexPath, andDay day: Int) -> NSDate {
        return getNSDateFromComponents(monthsAndYears[indexPath.section].year, month: monthsAndYears[indexPath.section].month, day: day)
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

