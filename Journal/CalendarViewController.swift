//
//  CalendarViewController.swift
//  Journal
//
//  Created by Morgan Davison on 3/21/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

//import UIKit
//
//class CalendarViewController: UICollectionViewController {
//    
//    var coreDataStack: CoreDataStack!
//    var entryViewController: EntryViewController? = nil
//    
//    struct Storyboard {
//        static let AddEntrySegueIdentifier = "AddEntryFromCalendar"
//        static let ShowDetailSegueIdentifier = "ShowDetailFromCalendar"
//        static let CalendarCellReuseIdentifier = "CalendarCell"
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(CalendarViewController.insertNewEntry(_:)))
//        //tabBarController?.navigationItem.rightBarButtonItem = addButton
//        navigationItem.rightBarButtonItem = addButton
//        
//        if let split = self.splitViewController {
//            let controllers = split.viewControllers
//            entryViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? EntryViewController
//            split.view.backgroundColor = UIColor.whiteColor()
//            //split.delegate = self
//        }
//    }
//
//    override func viewWillAppear(animated: Bool) {
//        super.viewWillAppear(animated)
//        
//        // Remove duplicate nav controller
//        tabBarController?.navigationController?.navigationBarHidden = true
//    }
//
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }
//    
//    
//    // MARK: - Actions
//    
//    @IBAction func insertNewEntry(sender: UIBarButtonItem) {
//        performSegueWithIdentifier(Storyboard.AddEntrySegueIdentifier, sender: sender)
//    }
//    
//
//    
//    // MARK: - Navigation
//    
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        if segue.identifier == Storyboard.AddEntrySegueIdentifier {
//            let controller = (segue.destinationViewController as! UINavigationController).topViewController as! EntryViewController
//            controller.title = "New Entry"
//            controller.coreDataStack = coreDataStack
//            
//            // Add the duplicate nav controller back in, else no nav controller shows up in entryViewController
//            // when in portrait/compact
//            // if in portrait/compact, add it back in
//            //tabBarController?.navigationController?.navigationBarHidden = false
//
//            
//            
//        } //else if segue.identifier == Storyboard.ShowDetailSegueIdentifier {
////            let controller = (segue.destinationViewController as! UINavigationController).topViewController as! EntryViewController
////            controller.coreDataStack = coreDataStack
////            
////            if let indexPath = tableView.indexPathForSelectedRow {
////                if let entry = fetchedResultsController.objectAtIndexPath(indexPath) as? Entry {
////                    controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
////                    controller.navigationItem.leftItemsSupplementBackButton = true
////                    controller.entry = entry
////                }
////            }
////        }
//    }
//    
//    
//    
//    // MARK: UICollectionViewDataSource
//    
//    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
//        return 3
//    }
//    
//    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return 30
//    }
//    
//    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Storyboard.CalendarCellReuseIdentifier, forIndexPath: indexPath) as! CalendarCollectionViewCell
//        
//        configureCell(cell, withIndexPath: indexPath)
//        
//        return cell
//    }
//    
//    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
//        
//        if kind == UICollectionElementKindSectionHeader {
//            let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "Header", forIndexPath: indexPath) as! CalendarCollectionReusableHeaderView
//            
//            headerView.backgroundColor = UIColor(red: 230.0/255.0, green: 230.0/255.0, blue: 230.0/255.0, alpha: 1)
//            
////            let dateFormatter = NSDateFormatter()
////            let monthText = dateFormatter.shortMonthSymbols[monthsAndYears[indexPath.section].month - 1]
////            let yearText = monthsAndYears[indexPath.section].year
////            
////            headerView.titleLabel.text = "\(monthText) \(yearText)".uppercaseString
//            return headerView
//        } else {
//            let footerView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "Footer", forIndexPath: indexPath)
//            
//            return footerView
//        }
//    }
//
//    
//    
//    // MARK: - Helper Methods
//    
//    private func configureCell(cell: CalendarCollectionViewCell, withIndexPath indexPath: NSIndexPath) {
//        cell.backgroundColor = UIColor.whiteColor()
//        
//        // Create top border
//        let topBorder = UIView(frame: CGRect(x: 0, y: 0, width: cell.frame.size.width, height: 1))
//        topBorder.backgroundColor = UIColor.lightGrayColor()
//        cell.contentView.addSubview(topBorder)
//        
//        
//        // Determine if this cell should be empty
////        let padding = getPadding(forMonthAndYear: monthsAndYears[indexPath.section])
////        var day = 0
////        
////        if indexPath.row + 1 > padding {
////            day = (indexPath.row + 1) - padding
////        }
////        
////        // Clear any existing red circles, otherwise they will stay and show up in wrong places
////        removeRedCircle(forCell: cell)
////        
////        if day > 0 { // Not a blank cell
////            cell.dayNumberLabel.text = "\(day)"
////            
////            // Draw red circle if there was a headache on this day
////            let dateOfThisCell = getNSDateFromComponents(monthsAndYears[indexPath.section].year, month: monthsAndYears[indexPath.section].month, day: day)
////            let headachesForThisMonth = monthsAndYears[indexPath.section].headaches
////            //print("date of this cell: \(dateOfThisCell)")
////            for ha in headachesForThisMonth {
////                //print("ha date: \(ha.date)")
////                if let headacheDate = ha.date { // Make sure it doesn't crash if we delete a headache
////                    if headacheDate == dateOfThisCell {
////                        drawCircle(forCell: cell, andHeadache: ha)
////                    }
////                }
////            }
////        } else { // Cell is a blank padding cell
////            cell.dayNumberLabel.text = ""
////        }
//    }
//
//
//}



