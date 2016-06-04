//
//  JournalUITests.swift
//  JournalUITests
//
//  Created by Morgan Davison on 3/11/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

import XCTest
//@testable import Journal

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
        XCUIDevice.sharedDevice().orientation = .Portrait
        
        let app = XCUIApplication()
        let device = UIDevice.currentDevice().userInterfaceIdiom
        
        if device == UIUserInterfaceIdiom.Pad {
            app.navigationBars["New Entry"].buttons["List"].tap()
            app.tabBars.childrenMatchingType(.Button).elementBoundByIndex(1).tap()
        } else if device == UIUserInterfaceIdiom.Phone {
            XCUIApplication().tabBars.childrenMatchingType(.Button).elementBoundByIndex(1).tap()
        }
    }
    
    func testSettingsTab() {
        XCUIDevice.sharedDevice().orientation = .Portrait
        
        let app = XCUIApplication()
        let device = UIDevice.currentDevice().userInterfaceIdiom
        
        if device == UIUserInterfaceIdiom.Pad {
            app.navigationBars["New Entry"].buttons["List"].tap()
            app.tabBars.childrenMatchingType(.Button).elementBoundByIndex(2).tap()
        } else if device == UIUserInterfaceIdiom.Phone {
            app.tabBars.childrenMatchingType(.Button).elementBoundByIndex(2).tap()
        }
    }
    
    func testInsertNewEntry() {
        XCUIDevice.sharedDevice().orientation = .Portrait
        
        let app = XCUIApplication()
        let device = UIDevice.currentDevice().userInterfaceIdiom
        
        if device == UIUserInterfaceIdiom.Pad {
            app.navigationBars["New Entry"].buttons["List"].tap()
            app.navigationBars["List"].buttons["Add"].tap()
            app.otherElements["PopoverDismissRegion"].tap()
        } else if device == UIUserInterfaceIdiom.Phone {
            app.navigationBars["List"].buttons["Add"].tap()
        }
    }
    
    func testInsertNewEntryFromCalendarTab() {
        XCUIDevice.sharedDevice().orientation = .Portrait
        
        let app = XCUIApplication()
        let device = UIDevice.currentDevice().userInterfaceIdiom
        
        if device == UIUserInterfaceIdiom.Pad {
            app.navigationBars["New Entry"].buttons["List"].tap()
            
            let app2 = app
            app2.tabBars.childrenMatchingType(.Button).elementBoundByIndex(1).tap()
            app2.navigationBars["Calendar"].buttons["Add"].tap()
            app.otherElements["PopoverDismissRegion"].tap()
        } else if device == UIUserInterfaceIdiom.Phone {
            app.tabBars.childrenMatchingType(.Button).elementBoundByIndex(1).tap()
            app.navigationBars["List"].buttons["Add"].tap()
        }
    }
    
    func testSaveEntry() {
        let app = XCUIApplication()
        let device = UIDevice.currentDevice().userInterfaceIdiom
        
        if device == UIUserInterfaceIdiom.Pad {
            app.childrenMatchingType(.Window).elementBoundByIndex(0).childrenMatchingType(.Other).element.childrenMatchingType(.Other).elementBoundByIndex(2).childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.TextView).element
            app.navigationBars["New Entry"].buttons["Save"].tap()
        }
    }
    
    func testAddEntryFromCalendarBySelectingDate() {
        let app = XCUIApplication()
        let device = UIDevice.currentDevice().userInterfaceIdiom
        
        if device == UIUserInterfaceIdiom.Pad {
            app.navigationBars["New Entry"].buttons["List"].tap()
            app.tabBars.childrenMatchingType(.Button).elementBoundByIndex(1).tap()
        } else if device == UIUserInterfaceIdiom.Phone {
            app.tabBars.childrenMatchingType(.Button).elementBoundByIndex(1).tap()
            app.collectionViews.childrenMatchingType(.Cell).elementBoundByIndex(41).staticTexts["6"].tap()
        }
    }
    
    func testExportEntries() {
        XCUIDevice.sharedDevice().orientation = .Portrait
        
        let app = XCUIApplication()
        let device = UIDevice.currentDevice().userInterfaceIdiom
        
        if device == UIUserInterfaceIdiom.Pad {
            app.navigationBars["New Entry"].buttons["List"].tap()
            app.tabBars.childrenMatchingType(.Button).elementBoundByIndex(2).tap()
            app.tables.buttons["Export Entries"].tap()
            
            // Assert that the action sheet appears
            XCTAssert(app.sheets.collectionViews.collectionViews.buttons["Mail"].exists)
        } else if device == UIUserInterfaceIdiom.Phone {
            XCUIDevice.sharedDevice().orientation = .Portrait
            
            app.tabBars.childrenMatchingType(.Button).elementBoundByIndex(2).tap()
            
            // Can't get this to work
//            app.tables.buttons["Export Entries"].tap()
//            XCTAssert(app.sheets.collectionViews.collectionViews.buttons["Mail"].exists)
            
        }
    }
    
    func testChangeDateOfEntry() {
        XCUIDevice.sharedDevice().orientation = .Portrait
        
        let app = XCUIApplication()
        let device = UIDevice.currentDevice().userInterfaceIdiom
        
        if device == UIUserInterfaceIdiom.Pad {
            app.buttons["Tap to change date"].tap()
            app.datePickers.pickerWheels["Today"].tap()
            app.navigationBars["Select Date"].buttons["Save"].tap()
        } else if device == UIUserInterfaceIdiom.Phone {
            XCUIDevice.sharedDevice().orientation = .Portrait
            
            app.navigationBars["List"].buttons["Add"].tap()
            
            // Can't get this to work
//            app.buttons["Tap to change date"].tap()
//            app.datePickers.pickerWheels["Today"].tap()
//            app.navigationBars["Select Date"].buttons["Save"].tap()
        }
    }
    
}
