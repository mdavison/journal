//
//  EntryTests.swift
//  Journal
//
//  Created by Morgan Davison on 6/3/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

import XCTest
@testable import Journal
import CoreData


class EntryTests: XCTestCase {
    
    var coreDataStack: CoreDataStack!
    var entryDate = NSDate()
    
    override func setUp() {
        super.setUp()
        
        coreDataStack = TestCoreDataStack()
        
        // Insert a new entry for today
        Entry.save(withEntry: nil, withDate: entryDate, withText: NSAttributedString(string: "Test entry"), withCoreDataStack: coreDataStack)
    }
    
    override func tearDown() {
        // Delete all entries
        // Batch delete wouldn't work for some reason
//        let fetchRequest = NSFetchRequest(entityName: "Entry")
//        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
//        do {
//            try coreDataStack.persistentStoreCoordinator.executeRequest(deleteRequest, withContext: coreDataStack.managedObjectContext)
//        } catch let error as NSError {
//            print("Error: \(error) " + "description \(error.localizedDescription)")
//        }
        
        if let allEntries = Entry.getAllEntries(coreDataStack) {
            for entry in allEntries {
                coreDataStack.managedObjectContext.deleteObject(entry)
            }
        }
        
        coreDataStack.saveContext()
        
        coreDataStack = nil
        
        super.tearDown()
    }
    
    func testGetFetchedResultsController() {
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let fetchedResultsController = Entry.getFetchedResultsController(coreDataStack)
        
        //XCTAssertEqualObjects(NSFetchedResultsController, fetchedResultsController, "Did not get fetchedResultsController")
        //XCTAssertEqual(fetchedResultsController, NSFetchedResultsController)
        XCTAssertTrue(fetchedResultsController.fetchedObjects!.count == 1)
    }
    
    func testEntryExistsForDate() {
        let entryExistsForDate = Entry.entryExists(forDate: entryDate, coreDataStack: coreDataStack)
        
        XCTAssertTrue(entryExistsForDate == true)
    }
    
    func testGetEntryForDate() {
        let entryForDate = Entry.getEntry(forDate: entryDate, coreDataStack: coreDataStack)
        print("test entryForDate: \(entryForDate!.attributed_text!)")
        
        XCTAssertTrue(entryForDate!.attributed_text == NSAttributedString(string: "Test entry"))
    }
    
    func testGetAllEntries() {
        let allEntries = Entry.getAllEntries(coreDataStack)
        
        XCTAssertTrue(allEntries!.count == 1)
    }
    
    
    
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
