//
//  Settings.swift
//  Journal
//
//  Created by Morgan Davison on 4/5/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

import Foundation
import CoreData


class Settings: NSManagedObject {

    static func getSettings(withCoreDataStack coreDataStack: CoreDataStack) -> Settings? {
        let fetchRequest = NSFetchRequest(entityName: "Settings")
        
        do {
            if let settingsArray = try coreDataStack.managedObjectContext.executeFetchRequest(fetchRequest) as? [Settings] {
                if let setting = settingsArray.last {
                    return setting
                }
            }
        } catch let error as NSError {
            NSLog("Error: \(error) " + "description \(error.localizedDescription)")
        }
        
        return nil 
    }
    
    static func saveSettings(withCoreDataStack coreDataStack: CoreDataStack, passwordRequired: Bool?, password: String?, hint: String?, touchID: Bool?) -> Settings? {
        
        var savedSettings: Settings? = nil
        
        if let settings = Settings.getSettings(withCoreDataStack: coreDataStack) {
            // Update existing
            if let required = passwordRequired {
                settings.password_required = required
            }
            if let hint = hint {
                settings.password_hint = hint
            }
            if let touchID = touchID {
                settings.use_touch_id = touchID
            }
            
            savedSettings = settings
        } else {
            // Create new
            if let entity = NSEntityDescription.entityForName("Settings", inManagedObjectContext: coreDataStack.managedObjectContext) {
                let settings = Settings(entity: entity, insertIntoManagedObjectContext: coreDataStack.managedObjectContext)
                
                if let required = passwordRequired {
                    settings.password_required = required
                }
                if let hint = hint {
                    settings.password_hint = hint
                }
                if let touchID = touchID {
                    settings.use_touch_id = touchID
                }
                
                savedSettings = settings
            }
        }
        
        if let password = password {
            KeychainWrapper.standardKeychainAccess().setString(password, forKey: "password")
        }
        
        coreDataStack.saveContext()
        
        return savedSettings
    }
    
    static func clearAllSettings(withCoreDataStack coreDataStack: CoreDataStack) {
        print("clearAllSettings")
        let fetchRequest = NSFetchRequest(entityName: "Settings")
        
        do {
            if let settingsArray = try coreDataStack.managedObjectContext.executeFetchRequest(fetchRequest) as? [Settings] {
                for setting in settingsArray {
                    print("deleting object: \(setting)")
                    coreDataStack.managedObjectContext.deleteObject(setting)
                }
                coreDataStack.saveContext()
            }
        } catch let error as NSError {
            NSLog("Error: \(error) " + "description \(error.localizedDescription)")
        }
        
        // Clear keychain password
        KeychainWrapper.standardKeychainAccess().removeObjectForKey("password")
    }

}
