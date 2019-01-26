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
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(CalendarCollectionViewController.insertNewEntry(_:)))
        navigationItem.rightBarButtonItem = addButton

        // Do any additional setup after loading the view.
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            entryViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? EntryViewController
            split.view.backgroundColor = UIColor.white
            //split.delegate = self
        }
                
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(CalendarCollectionViewController.entryHasSaved(_:)),
            name: NSNotification.Name(rawValue: HasSavedEntryNotificationKey),
            object: nil)
        
        NotificationCenter.default.addObserver(self,
            selector: #selector(CalendarCollectionViewController.persistentStoreCoordinatorStoresDidChange(_:)),
            name: NSNotification.Name.NSPersistentStoreCoordinatorStoresDidChange,
            object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Remove duplicate nav controller
        tabBarController?.navigationController?.isNavigationBarHidden = true

        setEntries()
        setMonthsYears()
        
        collectionView?.reloadData()
    }
    
    // Redraw view when switches orientation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        coordinator.animate(alongsideTransition: { (context: UIViewControllerTransitionCoordinatorContext) -> Void in
            self.collectionView?.reloadData()
        }) { (context: UIViewControllerTransitionCoordinatorContext) -> Void in
            // complete
        }
        
        super.viewWillTransition(to: size, with: coordinator)
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
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == Storyboard.ShowEntrySegueIdentifier {
            return !calendar.dateIsFuture(forCollectionView: collectionView, withMonthsYears: monthsYears)
        }
        
        return true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let controller = (segue.destination as! UINavigationController).topViewController as! EntryViewController
        
        if segue.identifier == Storyboard.AddEntrySegueIdentifier {
            controller.title = "New Entry"
            controller.coreDataStack = coreDataStack
        } else if segue.identifier == Storyboard.ShowEntrySegueIdentifier {
            controller.coreDataStack = coreDataStack
            
            if let indexPaths = collectionView?.indexPathsForSelectedItems {
                let indexPath = indexPaths[0]
                
                if let cell = collectionView?.cellForItem(at: indexPath) as? CalendarCollectionViewCell {
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
    

    // MARK: - UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return calendar.getNumberOfMonths(forEntries: entries)
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return calendar.numberOfDaysInMonth(forMonthAndYear: monthsYears[section])
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Storyboard.CalendarCellReuseIdentifier, for: indexPath) as! CalendarCollectionViewCell
    
        calendar.configureCell(forCell: cell, withIndexPath: indexPath, withMonthsYears: monthsYears)
    
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionView.elementKindSectionHeader {
            return calendar.getHeaderView(forCollectionView: collectionView, withIndexPath: indexPath, withMonthsYears: monthsYears)
        } else {
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Footer", for: indexPath)
            
            return footerView
        }
    }
        

    
    // MARK: - Notification Handling
    
    @objc func entryHasSaved(_ notification: Notification) {
        setEntries()
        setMonthsYears()
        collectionView?.reloadData()
    }
    
    @objc fileprivate func persistentStoreCoordinatorStoresDidChange(_ notification: Notification) {
        setEntries()
        setMonthsYears()
        collectionView?.reloadData()
    }
    
    
    // MARK: - Helper Methods
    
    fileprivate func setEntries() {
        if let entries = Entry.getAllEntries(coreDataStack) {
            self.entries = entries
        }
    }
    
    fileprivate func setMonthsYears() {
        // Empty the array, otherwise it keeps appending every time view loads
        monthsYears.removeAll()
        monthsYears = calendar.getMonthsYears(forEntries: entries)
    }
  
}


extension CalendarCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = floor(view.frame.size.width / 7.0)
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        
        return 0
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
}

