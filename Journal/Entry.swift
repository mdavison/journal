//
//  Entry.swift
//  Journal
//
//  Created by Morgan Davison on 3/14/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

import UIKit
import CoreData


class Entry: NSManagedObject {
    
    static func getFetchedResultsController(coreDataStack: CoreDataStack) -> NSFetchedResultsController {
        let fetchRequest = NSFetchRequest()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entityForName("Entry", inManagedObjectContext: coreDataStack.managedObjectContext)
        fetchRequest.entity = entity
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "created_at", ascending: false)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: coreDataStack.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            NSLog("Error fetching Entry objects: \(error.localizedDescription)")
        }
        
        return fetchedResultsController
    }
    
    static func entryExists(forDate date: NSDate, coreDataStack: CoreDataStack) -> Bool {
        let calendar = NSCalendar.currentCalendar()
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let entryDateComponents = calendar.components([.Day, .Month, .Year], fromDate: date)
        let predicateDateBeginString = "\(entryDateComponents.year)-\(entryDateComponents.month)-\(entryDateComponents.day) 00:00:00"
        let predicateDateEndString = "\(entryDateComponents.year)-\(entryDateComponents.month)-\(entryDateComponents.day) 23:59:59"
        let predicateDateBegin = formatter.dateFromString(predicateDateBeginString)
        let predicateDateEnd = formatter.dateFromString(predicateDateEndString)
        
        guard let begin = predicateDateBegin, let end = predicateDateEnd else {
            NSLog("Could not determine predicateDateBegin or predicateDateEnd")
            return false
        }
        
        let fetchRequest = NSFetchRequest(entityName: "Entry")
        let predicate = NSPredicate(format: "(created_at >= %@) AND (created_at <= %@)", begin, end)
        fetchRequest.predicate = predicate
        
        do {
            if let results = try coreDataStack.managedObjectContext.executeFetchRequest(fetchRequest) as? [Entry] {
                if let _ = results.first {
                    return true
                }
            }
        } catch let error as NSError {
            NSLog("Error: \(error) " + "description \(error.localizedDescription)")
        }
        
        return false
    }
    
    static func getEntry(forDate date: NSDate, coreDataStack: CoreDataStack) -> Entry? {
        let calendar = NSCalendar.currentCalendar()
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let entryDateComponents = calendar.components([.Day, .Month, .Year], fromDate: date)
        let predicateDateBeginString = "\(entryDateComponents.year)-\(entryDateComponents.month)-\(entryDateComponents.day) 00:00:00"
        let predicateDateEndString = "\(entryDateComponents.year)-\(entryDateComponents.month)-\(entryDateComponents.day) 23:59:59"
        let predicateDateBegin = formatter.dateFromString(predicateDateBeginString)
        let predicateDateEnd = formatter.dateFromString(predicateDateEndString)
        
        guard let begin = predicateDateBegin, let end = predicateDateEnd else {
            NSLog("Could not determine predicateDateBegin or predicateDateEnd")
            return nil
        }
        
        let fetchRequest = NSFetchRequest(entityName: "Entry")
        let predicate = NSPredicate(format: "(created_at >= %@) AND (created_at <= %@)", begin, end)
        fetchRequest.predicate = predicate
        
        do {
            if let results = try coreDataStack.managedObjectContext.executeFetchRequest(fetchRequest) as? [Entry] {
                return results.first
            }
        } catch let error as NSError {
            NSLog("Error: \(error) " + "description \(error.localizedDescription)")
        }
        
        return nil 
    }
    
    static func getAllEntries(coreDataStack: CoreDataStack) -> [Entry]? {
        let fetchRequest = NSFetchRequest(entityName: "Entry")
        let nameSortDescriptor = NSSortDescriptor(key: "created_at", ascending: false)
        fetchRequest.sortDescriptors = [nameSortDescriptor]
        
        do {
            if let results = try coreDataStack.managedObjectContext.executeFetchRequest(fetchRequest) as? [Entry] {
                return results
            }
        } catch let error as NSError {
            print("Error: \(error) " + "description \(error.localizedDescription)")
        }
        
        return nil
    }
    
    static func save(withEntry entry: Entry?, withDate date: NSDate, withText text: NSAttributedString, withCoreDataStack coreDataStack: CoreDataStack) -> Entry? {
        
        var savedEntry: Entry? = nil
        
        if let entry = entry {
            // Save existing
            entry.created_at = date
            entry.updated_at = NSDate()
            //entry.text = entryTextView.text
            entry.attributed_text = text
            savedEntry = entry
        } else {
            // Create new
            let entryEntity = NSEntityDescription.entityForName("Entry", inManagedObjectContext: coreDataStack.managedObjectContext)
            savedEntry = Entry(entity: entryEntity!, insertIntoManagedObjectContext: coreDataStack.managedObjectContext)
            savedEntry?.created_at = date
            //savedEntry?.text = entryTextView.text
            savedEntry?.attributed_text = text
        }
        
        coreDataStack.saveContext()
        
        JournalVariables.entry = savedEntry 
        
        return savedEntry
    }
    
    static func getExportData(forEntries entries: [Entry]) -> NSData? {
        var entriesString = ""
        let formatter = NSDateFormatter()
        formatter.dateStyle = .MediumStyle
        formatter.timeStyle = .MediumStyle

        for entry in entries {
            if let date = entry.created_at {
                entriesString += formatter.stringFromDate(date) + "\n\n"
            } else {
                entriesString += "No Date\n\n"
            }
            if let attributedText = entry.attributed_text {
                // Trying to get formatted text for .rtf document not working
//                do {
//                    var range = NSRange(location: 0, length: entry.attributed_text!.length - 1)
//                    let entryAttributes = entry.attributed_text?.attributesAtIndex(0, effectiveRange: &range)
//                    let data = try attributedText.dataFromRange(range, documentAttributes: entryAttributes!)
//                    //return data
//                    entriesString += "\(data)\n\n"
//                } catch {
//                    NSLog("Error getting data from attributed string: \(error)")
//                    entriesString += "\(attributedText.string)\n\n"
//                }
                
                entriesString += "\(attributedText.string)\n\n"
            }
            entriesString += "***\n\n"
        }
        
        return entriesString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
    }
    
    static func getURLForExportData(withCoreDataStack coreDataStack: CoreDataStack) -> (NSURL?, String?) {
        if let entries = Entry.getAllEntries(coreDataStack) {
            if entries.count == 0 {
                return (nil, "There are no entries to export")
            }
            
            if let data = Entry.getExportData(forEntries: entries) {
                let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
                let documentsDirectory = paths[0] as NSString
                let filename = documentsDirectory.stringByAppendingPathComponent("journal_entries.txt")
                
                data.writeToFile(filename, atomically: true)
                
                return (NSURL(fileURLWithPath: filename), nil)
            }
        }
        
        return (nil, "Unable to export entries")
    }
    
    static func getButtonDate(forButton button: UIButton) -> NSDate {
        let formatter = Entry.getFormatter()
        let buttonDate = formatter.dateFromString(button.currentTitle!)
        if let date = buttonDate {
            return date
        }
        
        return NSDate()
    }
    
    static func getFormatter() -> NSDateFormatter {
        let formatter = NSDateFormatter()
        formatter.dateStyle = .MediumStyle
        formatter.timeStyle = .ShortStyle
        
        return formatter
    }
    
    static func setDateButton(forDateButton dateButton: UIButton, withEntry entry: Entry?) {
        if let entry = entry {
            let formatter = Entry.getFormatter()
            dateButton.setTitle(formatter.stringFromDate(entry.created_at!), forState: .Normal)
        } else {
            let formatter = Entry.getFormatter()
            dateButton.setTitle(formatter.stringFromDate(NSDate()), forState: .Normal)
        }
    }
    
    static func setDateButton(forDateButton dateButton: UIButton, withDate date: NSDate) {
        let formatter = Entry.getFormatter()
        
        dateButton.setTitle(formatter.stringFromDate(date), forState: .Normal)
    }
    
    // I think this was only used for Facebook and Twitter integration
//    static func getTimestamps(forEntry entry: Entry?) -> [String: Int] {
//        let calendar = NSCalendar.currentCalendar()
//        let formatter = NSDateFormatter()
//        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
//        var since = NSDate()
//        var until = NSDate()
//        
//        if let entry = entry {
//            if let createdAt = entry.created_at {
//                // get date portion only of createdAt
//                let entryDateComponents = calendar.components([.Day, .Month, .Year], fromDate: createdAt)
//                
//                // set the time to midnight and the last second
//                let entryDateBegin = "\(entryDateComponents.year)-\(entryDateComponents.month)-\(entryDateComponents.day) 00:00:00"
//                let entryDateEnd = "\(entryDateComponents.year)-\(entryDateComponents.month)-\(entryDateComponents.day) 23:59:59"
//                
//                since = formatter.dateFromString(entryDateBegin)!
//                until = formatter.dateFromString(entryDateEnd)!
//            }
//        } else {
//            let currentDateComponents = calendar.components([.Day, .Month, .Year], fromDate: NSDate())
//            let currentDateBegin = "\(currentDateComponents.year)-\(currentDateComponents.month)-\(currentDateComponents.day) 00:00:00"
//            let currentDateEnd = "\(currentDateComponents.year)-\(currentDateComponents.month)-\(currentDateComponents.day) 23:59:59"
//            
//            since = formatter.dateFromString(currentDateBegin)!
//            until = formatter.dateFromString(currentDateEnd)!
//        }
//        
//        let sinceTimestamp = Int(since.timeIntervalSince1970)
//        let untilTimestamp = Int(until.timeIntervalSince1970)
//        
//        return ["since": sinceTimestamp, "until": untilTimestamp]
//    }

    
}
