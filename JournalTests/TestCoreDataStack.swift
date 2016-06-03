//
//  TestCoreDataStack.swift
//  Journal
//
//  Created by Morgan Davison on 6/3/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

@testable import Journal
import Foundation
import CoreData

class TestCoreDataStack: CoreDataStack {
    
    override init() {
        super.init()
        
        self.persistentStoreCoordinator = {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
            
            do {
                try persistentStoreCoordinator.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil)
            } catch {
                fatalError()
            }
            
            return persistentStoreCoordinator
        }()
    }
}