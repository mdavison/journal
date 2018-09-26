//
//  SettingsTests.swift
//  Journal
//
//  Created by Morgan Davison on 6/3/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

import XCTest
@testable import Journal
import CoreData


class SettingsTests: XCTestCase {
    
    var coreDataStack: CoreDataStack!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        coreDataStack = TestCoreDataStack()
        
        // Create settings
        Settings.saveSettings(withCoreDataStack: coreDataStack, passwordRequired: true, password: "hello", hint: "greeting", touchID: true)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        Settings.clearAllSettings(withCoreDataStack: coreDataStack)
        coreDataStack = nil

        super.tearDown()
    }

    
    func testGetSettings() {
        let settings = Settings.getSettings(withCoreDataStack: coreDataStack)
        let passwordRequired = settings!.password_required as! Bool
        XCTAssertTrue(passwordRequired)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
