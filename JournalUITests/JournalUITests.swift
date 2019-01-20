//
//  JournalUITests.swift
//  JournalUITests
//
//  Created by Morgan Davison on 3/11/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

import XCTest
@testable import Journal

class JournalUITests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        
        super.tearDown()
    }
    
    
    func testCalendarTab() {
        XCUIDevice.shared.orientation = .portrait
        
        let app = XCUIApplication()
        let device = UIDevice.current.userInterfaceIdiom
        
        if device == UIUserInterfaceIdiom.pad {
            app.navigationBars["New Entry"].buttons["List"].tap()
            app.tabBars.children(matching: .button).element(boundBy: 1).tap()
        } else if device == UIUserInterfaceIdiom.phone {
            XCUIApplication().tabBars.children(matching: .button).element(boundBy: 1).tap()
        }
    }
    
    func testSettingsTab() {
        XCUIDevice.shared.orientation = .portrait
        
        let app = XCUIApplication()
        let device = UIDevice.current.userInterfaceIdiom
        
        if device == UIUserInterfaceIdiom.pad {
            app.navigationBars["New Entry"].buttons["List"].tap()
            app.tabBars.children(matching: .button).element(boundBy: 2).tap()
        } else if device == UIUserInterfaceIdiom.phone {
            app.tabBars.children(matching: .button).element(boundBy: 2).tap()
        }
    }
    
    func testInsertNewEntry() {
        XCUIDevice.shared.orientation = .portrait
        
        let app = XCUIApplication()
        let device = UIDevice.current.userInterfaceIdiom
        
        if device == UIUserInterfaceIdiom.pad {
            app.navigationBars["New Entry"].buttons["List"].tap()
            app.navigationBars["List"].buttons["Add"].tap()
            app.otherElements["PopoverDismissRegion"].tap()
        } else if device == UIUserInterfaceIdiom.phone {
            app.navigationBars["List"].buttons["Add"].tap()
        }
    }
    
    func testInsertNewEntryFromCalendarTab() {
        XCUIDevice.shared.orientation = .portrait
        
        let app = XCUIApplication()
        let device = UIDevice.current.userInterfaceIdiom
        
        if device == UIUserInterfaceIdiom.pad {
            app.navigationBars["New Entry"].buttons["List"].tap()
            
            let app2 = app
            app2.tabBars.children(matching: .button).element(boundBy: 1).tap()
            app2.navigationBars["Calendar"].buttons["Add"].tap()
            app.otherElements["PopoverDismissRegion"].tap()
        } else if device == UIUserInterfaceIdiom.phone {
            app.tabBars.children(matching: .button).element(boundBy: 1).tap()
            //app.navigationBars["List"].buttons["Add"].tap()
            app.navigationBars["Calendar"].buttons["Add"].tap()
        }
    }
    
    func testSaveEntry() {
        let app = XCUIApplication()
        let device = UIDevice.current.userInterfaceIdiom
        
        if device == UIUserInterfaceIdiom.pad {
            app.navigationBars["New Entry"].buttons["Save"].tap()
        }
    }
    
    func testAddEntryFromCalendarBySelectingDate() {
        let app = XCUIApplication()
        let device = UIDevice.current.userInterfaceIdiom
        
        if device == UIUserInterfaceIdiom.pad {
            app.navigationBars["New Entry"].buttons["List"].tap()
            app.tabBars.children(matching: .button).element(boundBy: 1).tap()
        } else if device == UIUserInterfaceIdiom.phone {
            app.tabBars.children(matching: .button).element(boundBy: 1).tap()
            //app.collectionViews.childrenMatchingType(.Cell).elementBoundByIndex(41).staticTexts["6"].tap()
        }
    }
    
    func testExportEntries() {
        XCUIDevice.shared.orientation = .portrait
        
        let app = XCUIApplication()
        let device = UIDevice.current.userInterfaceIdiom
        
        if device == UIUserInterfaceIdiom.pad {
            app.navigationBars["New Entry"].buttons["List"].tap()
            app.tabBars.children(matching: .button).element(boundBy: 2).tap()
            app.tables.buttons["Export Entries"].tap()
            
            // Assert that the action sheet appears
            //XCTAssert(app.sheets.collectionViews.collectionViews.buttons["More"].exists)
        } else if device == UIUserInterfaceIdiom.phone {
            XCUIDevice.shared.orientation = .portrait
            
            app.tabBars.children(matching: .button).element(boundBy: 2).tap()
            
            // Can't get this to work
//            app.tables.buttons["Export Entries"].tap()
//            XCTAssert(app.sheets.collectionViews.collectionViews.buttons["Mail"].exists)
            
        }
    }
    
    func testChangeDateOfEntry() {
        XCUIDevice.shared.orientation = .portrait
        
        let app = XCUIApplication()
        let device = UIDevice.current.userInterfaceIdiom
        
        if device == UIUserInterfaceIdiom.pad {
            app.buttons["Tap to change date"].tap()
            app.datePickers.pickerWheels["Today"].tap()
            app.navigationBars["Select Date"].buttons["Save"].tap()
        } else if device == UIUserInterfaceIdiom.phone {
            XCUIDevice.shared.orientation = .portrait
            
            app.navigationBars["List"].buttons["Add"].tap()
            
            app.buttons["Tap to change date"].tap()
            app.datePickers.pickerWheels["Today"].tap()
            app.navigationBars["Select Date"].buttons["Save"].tap()
        }
    }
    
    // Test when adding a new entry for a date that already has an entry
    func testNewEntryForDateAlreadyExists() {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        let device = UIDevice.current.userInterfaceIdiom
        let newEntryNavigationBar = app.navigationBars["New Entry"]
        let listEntryNavigationBar = app.navigationBars["List"]

        // Enter first entry
        if device == UIUserInterfaceIdiom.pad {
            newEntryNavigationBar.buttons["List"].tap()
            app.navigationBars["List"].buttons["Add"].tap()
            app.otherElements["PopoverDismissRegion"].tap()
        } else if device == UIUserInterfaceIdiom.phone {
            listEntryNavigationBar.buttons["Add"].tap()
        }
        
        let textView = app.tables.cells.children(matching: .textView).element
        
        textView.tap()
        app.typeText("test entry one")

        // Save
        newEntryNavigationBar.buttons["Save"].tap()
        
        // Go back to list
        newEntryNavigationBar.buttons["List"].tap()
        
        // Enter second entry
        if device == UIUserInterfaceIdiom.pad {
            newEntryNavigationBar.buttons["List"].tap()
            app.navigationBars["List"].buttons["Add"].tap()
            app.otherElements["PopoverDismissRegion"].tap()
        } else if device == UIUserInterfaceIdiom.phone {
            listEntryNavigationBar.buttons["Add"].tap()
        }
        
        app.datePickers.pickerWheels["Today"].swipeDown()
        app.navigationBars["Select Date"].buttons["Save"].tap()
        
        // Fixme
//        textView.tap()
//        app.typeText("test entry two")
//        app.navigationBars["New Entry"].buttons["Save"].tap()
        
        // todo: delete the entry(ies)
    }
    
}
