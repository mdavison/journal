//
//  CalendarTests.swift
//  Journal
//
//  Created by Morgan Davison on 6/3/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

import XCTest
@testable import Journal

class CalendarTests: XCTestCase {
    
    var calendar = Calendar()
    var coreDataStack: TestCoreDataStack!
    var entryDate: NSDate! // June 1, 2016
    var numberOfDaysInMonth = 30 // June 2016
    var numberOfBlankDaysToAddForPadding = 3 // June 2016
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        coreDataStack = TestCoreDataStack()
        
        // Insert a new entry for entryDate
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        entryDate = formatter.dateFromString("2016-06-01")
        Entry.save(withEntry: nil, withDate: entryDate, withText: NSAttributedString(string: "Test entry"), withCoreDataStack: coreDataStack)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        if let allEntries = Entry.getAllEntries(coreDataStack) {
            for entry in allEntries {
                coreDataStack.managedObjectContext.deleteObject(entry)
            }
        }
        
        coreDataStack.saveContext()
        coreDataStack = nil
        
        super.tearDown()
    }
    
    
    func testGetMonthsYears() {
        let entries = Entry.getAllEntries(coreDataStack)
        let monthsYears = calendar.getMonthsYears(forEntries: entries!)
        
        XCTAssertTrue(monthsYears.count == 1)
        
        // Get month and year components from entryDate
        let components = NSCalendar.currentCalendar().components([.Month, .Year], fromDate: entryDate)
        
        XCTAssertTrue(monthsYears.first!.entries.count == 1)
        XCTAssertTrue(monthsYears.first!.month == components.month)
        XCTAssertTrue(monthsYears.first!.year == components.year)
    }
    
    func testGetNumberOfMonthsForEntries() {
        let entries = Entry.getAllEntries(coreDataStack)
        let numberOfMonths = calendar.getNumberOfMonths(forEntries: entries!)
        
        XCTAssertTrue(numberOfMonths == 1)
    }
    
    func testGetNumberOfDaysInMonthForMonthYear() {
        let entries = Entry.getAllEntries(coreDataStack)
        let monthsYears = calendar.getMonthsYears(forEntries: entries!)
        
        let numberOfDaysInMonthForMonthYear = calendar.numberOfDaysInMonth(forMonthAndYear: monthsYears.first!)
        
        XCTAssertTrue(numberOfDaysInMonthForMonthYear == numberOfDaysInMonth + numberOfBlankDaysToAddForPadding)
    }
    
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
