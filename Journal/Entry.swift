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
    
    static func getFetchedResultsController(_ coreDataStack: CoreDataStack) -> NSFetchedResultsController<NSFetchRequestResult> {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entity(forEntityName: "Entry", in: coreDataStack.managedObjectContext)
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
    
    static func entryExists(forDate date: Date, coreDataStack: CoreDataStack) -> Bool {
        let calendar = Foundation.Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let entryDateComponents = (calendar as NSCalendar).components([.day, .month, .year], from: date)
        
        let predicateDateBeginString = "\(entryDateComponents.year ?? 0)" +
            "-" + "\(entryDateComponents.month ?? 0)" +
            "-" + "\(entryDateComponents.day ?? 0)" +
            " 00:00:00"
        
        let predicateDateEndString = "\(entryDateComponents.year ?? 0)" +
            "-" + "\(entryDateComponents.month ?? 0)" +
            "-" + "\(entryDateComponents.day ?? 0)" +
            " 23:59:59"
        
        let predicateDateBegin = formatter.date(from: predicateDateBeginString)
        let predicateDateEnd = formatter.date(from: predicateDateEndString)
        
        guard let begin = predicateDateBegin, let end = predicateDateEnd else {
            NSLog("Could not determine predicateDateBegin or predicateDateEnd")
            return false
        }
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Entry")
        let predicate = NSPredicate(format: "(created_at >= %@) AND (created_at <= %@)", begin as CVarArg, end as CVarArg)
        fetchRequest.predicate = predicate
        
        do {
            if let results = try coreDataStack.managedObjectContext.fetch(fetchRequest) as? [Entry] {
                if let _ = results.first {
                    return true
                }
            }
        } catch let error as NSError {
            NSLog("Error: \(error) " + "description \(error.localizedDescription)")
        }
        
        return false
    }
    
    static func getEntry(forDate date: Date, coreDataStack: CoreDataStack) -> Entry? {
        let calendar = Foundation.Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let entryDateComponents = (calendar as NSCalendar).components([.day, .month, .year], from: date)
        
        let predicateDateBeginString = "\(entryDateComponents.year ?? 0)" +
            "-" + "\(entryDateComponents.month ?? 0)" +
            "-" + "\(entryDateComponents.day ?? 0)" +
        " 00:00:00"
        
        let predicateDateEndString = "\(entryDateComponents.year ?? 0)" +
            "-" + "\(entryDateComponents.month ?? 0)" +
            "-" + "\(entryDateComponents.day ?? 0)" +
        " 23:59:59"
        
        let predicateDateBegin = formatter.date(from: predicateDateBeginString)
        let predicateDateEnd = formatter.date(from: predicateDateEndString)
        
        guard let begin = predicateDateBegin, let end = predicateDateEnd else {
            NSLog("Could not determine predicateDateBegin or predicateDateEnd")
            return nil
        }
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Entry")
        let predicate = NSPredicate(format: "(created_at >= %@) AND (created_at <= %@)", begin as CVarArg, end as CVarArg)
        fetchRequest.predicate = predicate
        
        do {
            if let results = try coreDataStack.managedObjectContext.fetch(fetchRequest) as? [Entry] {
                return results.first
            }
        } catch let error as NSError {
            NSLog("Error: \(error) " + "description \(error.localizedDescription)")
        }
        
        return nil 
    }
    
    static func getAllEntries(_ coreDataStack: CoreDataStack) -> [Entry]? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Entry")
        let nameSortDescriptor = NSSortDescriptor(key: "created_at", ascending: false)
        fetchRequest.sortDescriptors = [nameSortDescriptor]
        
        do {
            if let results = try coreDataStack.managedObjectContext.fetch(fetchRequest) as? [Entry] {
                return results
            }
        } catch let error as NSError {
            print("Error: \(error) " + "description \(error.localizedDescription)")
        }
        
        return nil
    }
    
    @discardableResult static func save(withEntry entry: Entry?, withDate date: Date, withText text: NSAttributedString, withCoreDataStack coreDataStack: CoreDataStack) -> Entry? {
        
        var savedEntry: Entry? = nil
        
        if let entry = entry {
            // Save existing
            entry.created_at = date
            entry.updated_at = Date()
            //entry.text = entryTextView.text
            entry.attributed_text = text
            savedEntry = entry
        } else {
            // Create new
            let entryEntity = NSEntityDescription.entity(forEntityName: "Entry", in: coreDataStack.managedObjectContext)
            savedEntry = Entry(entity: entryEntity!, insertInto: coreDataStack.managedObjectContext)
            savedEntry?.created_at = date
            //savedEntry?.text = entryTextView.text
            savedEntry?.attributed_text = text
        }
        
        coreDataStack.saveContext()
        
        JournalVariables.entry = savedEntry 
        
        return savedEntry
    }
    
    static func getExportData(forEntries entries: [Entry]) -> Data? {
        var entriesString = ""
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium

        for entry in entries {
            if let date = entry.created_at {
                entriesString += formatter.string(from: date as Date) + "\n\n"
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
        
        return entriesString.data(using: String.Encoding.utf8, allowLossyConversion: false)
    }
    
    static func getURLForExportData(withCoreDataStack coreDataStack: CoreDataStack) -> (URL?, String?) {
        if let entries = Entry.getAllEntries(coreDataStack) {
            if entries.count == 0 {
                return (nil, "There are no entries to export")
            }
            
            if let data = Entry.getExportData(forEntries: entries) {
                let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                let documentsDirectory = paths[0] as NSString
                let filename = documentsDirectory.appendingPathComponent("journal_entries.txt")
                
                try? data.write(to: URL(fileURLWithPath: filename), options: [.atomic])
                
                return (URL(fileURLWithPath: filename), nil)
            }
        }
        
        return (nil, "Unable to export entries")
    }
    
    static func getButtonDate(forButton button: UIButton) -> Date {
        let formatter = Entry.getFormatter()
        let buttonDate = formatter.date(from: button.currentTitle!)
        if let date = buttonDate {
            return date
        }
        
        return Date()
    }
    
    static func getFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        return formatter
    }
    
    static func setDateButton(forDateButton dateButton: UIButton, withEntry entry: Entry?) {
        if let entry = entry {
            let formatter = Entry.getFormatter()
            dateButton.setTitle(formatter.string(from: entry.created_at! as Date), for: UIControl.State())
        } else {
            let formatter = Entry.getFormatter()
            dateButton.setTitle(formatter.string(from: Date()), for: UIControl.State())
        }
    }
    
    static func setDateButton(forDateButton dateButton: UIButton, withDate date: Date) {
        let formatter = Entry.getFormatter()
        
        dateButton.setTitle(formatter.string(from: date), for: UIControl.State())
    }

    
}
