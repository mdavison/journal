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
            app/*@START_MENU_TOKEN@*/.tabBars/*[[".otherElements[\"dismiss popup\"].tabBars",".otherElements[\"PopoverDismissRegion\"].tabBars",".tabBars"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.children(matching: .button).element(boundBy: 1).tap()
            app.collectionViews.children(matching: .cell).element(boundBy: 8).tap();
            app/*@START_MENU_TOKEN@*/.otherElements["PopoverDismissRegion"]/*[[".otherElements[\"dismiss popup\"]",".otherElements[\"PopoverDismissRegion\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        } else if device == UIUserInterfaceIdiom.phone {
            app.tabBars.children(matching: .button).element(boundBy: 1).tap()
            app.navigationBars["Calendar"].buttons["Add"].tap()
        }
        
        let textView = app.tables.cells.children(matching: .textView).element
        textView.tap()
        
        // todo: assert the date day value is the same as the calendar button tapped
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
        
        XCTAssert(app.staticTexts.element(matching: .any, identifier: "Require Password").exists)
    }
    
    func testInsertNewEntry() {
        XCUIDevice.shared.orientation = .portrait
        
        let app = XCUIApplication()
        let device = UIDevice.current.userInterfaceIdiom
        
        if device == UIUserInterfaceIdiom.pad {
            deleteLastEntry()
            app.navigationBars["New Entry"].buttons["List"].tap()
            app.navigationBars["List"].buttons["Add"].tap()
            app.otherElements["PopoverDismissRegion"].tap()
        } else if device == UIUserInterfaceIdiom.phone {
            app.navigationBars["List"].buttons["Add"].tap()
        }
    }
    
    func testSaveEntry() {
        let app = XCUIApplication()
        let device = UIDevice.current.userInterfaceIdiom

        if device == UIUserInterfaceIdiom.pad {
            let textView = app.tables.cells.children(matching: .textView).element
            textView.tap()
            textView.typeText("Foo")
            
            app.navigationBars["New Entry"].buttons["Save"].tap()
            
            let button = app.navigationBars["Journal Entry"].buttons["Save"]
            XCTAssertFalse(button.isEnabled)
        } else if device == UIUserInterfaceIdiom.phone {
            deleteLastEntry()
            app.navigationBars["List"].buttons["Add"].tap()
            
            let textView = app.tables.cells.children(matching: .textView).element
            textView.tap()
            textView.typeText("Foo")
            
            app.navigationBars["New Entry"].buttons["Save"].tap()
            
            let button = app.navigationBars["Journal Entry"].buttons["Save"]
            button.tap()
            XCTAssertFalse(button.isEnabled)
        }
    }
    
    func testExportEntries() {
        XCUIDevice.shared.orientation = .portrait
        
        let app = XCUIApplication()
        let device = UIDevice.current.userInterfaceIdiom
        
        // Make sure we have at least one entry to export
        addNewEntry()
        
        if device == UIUserInterfaceIdiom.pad {
            app.tabBars.children(matching: .button).element(boundBy: 2).tap()
            app.tables.buttons["Export Entries"].tap()
            
            // Assert that the action sheet appears
            app.otherElements["ActivityListView"].tap()
        } else if device == UIUserInterfaceIdiom.phone {
            app.tabBars.children(matching: .button).element(boundBy: 2).tap()
            
            app.tables.buttons["Export Entries"].tap()
            app.buttons["Cancel"].tap()
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
            deleteLastEntry()
            
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
        
        deleteLastEntry()

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
        if device == UIUserInterfaceIdiom.pad {
            textView.swipeRight()
        } else {
//            newEntryNavigationBar.buttons["List"].tap()
            app.navigationBars["Journal Entry"].buttons["List"].tap()
        }
        
        // Enter second entry
        if device == UIUserInterfaceIdiom.pad {
            app.navigationBars["List"].buttons["Add"].tap()
        } else if device == UIUserInterfaceIdiom.phone {
            listEntryNavigationBar.buttons["Add"].tap()
        }
        
        app.datePickers.pickerWheels["Today"].swipeDown()
        app.navigationBars["Select Date"].buttons["Save"].tap()
    }

    
    // MARK: Helper functions
    
    func deleteLastEntry() {
        XCUIDevice.shared.orientation = .portrait
        
        let device = UIDevice.current.userInterfaceIdiom
        let app = XCUIApplication()
        
        if device == UIUserInterfaceIdiom.pad {
            app.navigationBars["New Entry"].buttons["List"].tap()
            
            // What a mess - got this thing from recording and just couldn't find a clean
            // way to get the master view table
            app/*@START_MENU_TOKEN@*/.otherElements["PopoverDismissRegion"]/*[[".otherElements[\"dismiss popup\"]",".otherElements[\"PopoverDismissRegion\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .table).element.cells.element(boundBy: 0).swipeLeft()
            
//            app.tables.cells.firstMatch.swipeLeft() // this dismisses the master view
            
            if app.tables.buttons["Delete"].exists {
                app/*@START_MENU_TOKEN@*/.tables/*[[".otherElements[\"dismiss popup\"].tables",".otherElements[\"PopoverDismissRegion\"].tables",".tables"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.buttons["Delete"].tap()
            }
            
            app.tables.firstMatch.swipeLeft()
        } else if device == UIUserInterfaceIdiom.phone {
            app.tables.cells.firstMatch.swipeLeft()
            if app.tables.buttons["Delete"].exists {
                app.tables.buttons["Delete"].tap()
            }
        }
    }
    
    func addNewEntry() {
        XCUIDevice.shared.orientation = .portrait
        
        let app = XCUIApplication()
        let device = UIDevice.current.userInterfaceIdiom
        
        if device == UIUserInterfaceIdiom.pad {
            let textView = app.tables.cells.children(matching: .textView).element
            textView.tap()
            textView.typeText("Foo")
            
            app.navigationBars["New Entry"].buttons["Save"].tap()
            app.navigationBars["Journal Entry"].buttons["List"].tap()
        } else if device == UIUserInterfaceIdiom.phone {
            if app.tables.cells.count < 1 {
                app.navigationBars["List"].buttons["Add"].tap()
                
                let textView = app.tables.cells.children(matching: .textView).element
                textView.tap()
                textView.typeText("Foo")
                
                app.navigationBars["New Entry"].buttons["Save"].tap()
            }
        }
    }
    
}
