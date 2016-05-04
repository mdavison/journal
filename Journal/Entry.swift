//
//  Entry.swift
//  Journal
//
//  Created by Morgan Davison on 3/14/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

import Foundation
import CoreData


class Entry: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
    
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
    
    // TODO: use this for CalendarCollectionViewController
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

}
