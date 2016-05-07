//
//  SettingsTableViewController.swift
//  Journal
//
//  Created by Morgan Davison on 4/4/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

import UIKit
import CoreData

class SettingsTableViewController: UITableViewController {

    @IBOutlet weak var passwordRequiredSwitch: UISwitch!
    
    var coreDataStack: CoreDataStack!
    var settings: Settings?
    
    struct Storyboard {
        static var SetPasswordSegueIdentifier = "SetPassword"
        static var ChangePasswordSegueIdentifier = "ChangePassword"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        //clearAllSettings()
        setSettings()
        setupView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Remove duplicate nav controller
        tabBarController?.navigationController?.navigationBarHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            switch identifier {
            case Storyboard.SetPasswordSegueIdentifier:
                guard let navigationController = segue.destinationViewController as? UINavigationController,
                    let controller = navigationController.topViewController as? SetPasswordTableViewController
                    else { break }
                
                controller.delegate = self
                
            case Storyboard.ChangePasswordSegueIdentifier:
                // todo
                break
            default:
                return
            }
        }
    }
    
    
    // MARK: - Actions
    
    @IBAction func requirePasswordSwitchChanged(sender: UISwitch) {
        if sender.on { // Switched On
            if let settings = settings {
                if settings.password == nil { // No password set
                    performSegueWithIdentifier(Storyboard.SetPasswordSegueIdentifier, sender: nil)
                } else {
                    saveSettings(true, password: nil, touchID: nil) // Password required, password already set
                    JournalVariables.userIsAuthenticated = false
                }
            } else { // No password settings yet
                performSegueWithIdentifier(Storyboard.SetPasswordSegueIdentifier, sender: nil)
            }
        } else { // Switched Off
            saveSettings(false, password: nil, touchID: false)
        }
    }
    
    @IBAction func exportEntries(sender: UIButton) {
        if let entries = Entry.getAllEntries(coreDataStack) {
            if let data = Entry.getExportData(forEntries: entries) {
                let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
                let documentsDirectory = paths[0] as NSString
                let filename = documentsDirectory.stringByAppendingPathComponent("journal_entries.txt")
                
                data.writeToFile(filename, atomically: true)
                let url = NSURL(fileURLWithPath: filename)
                
                let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                
                if let popoverController = activityViewController.popoverPresentationController {
                    popoverController.sourceView = sender
                }
                
                presentViewController(activityViewController, animated: true, completion: nil)
            } else {
                NSLog("Unable to prepare data")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func setSettings() {
        let fetchRequest = NSFetchRequest(entityName: "Settings")
        
        do {
            if let settingsArray = try coreDataStack.managedObjectContext.executeFetchRequest(fetchRequest) as? [Settings] {
                if let setting = settingsArray.last {
                    settings = setting
                }
            }
        } catch let error as NSError {
            NSLog("Error: \(error) " + "description \(error.localizedDescription)")
        }
    }
    
    private func setupView() {
        if let settings = settings {
            if settings.password_required == true {
                passwordRequiredSwitch.on = true
            }
        }
    }
    
    private func saveSettings(passwordRequired: Bool?, password: String?, touchID: Bool?) {
        if let settings = settings {
            // Update existing
            if let required = passwordRequired {
                settings.password_required = required
            }
            if let password = password {
                // TODO: encrypt password
                settings.password = password
            }
            if let touchID = touchID {
                settings.use_touch_id = touchID
            }
        } else {
            // Create new
            if let entity = NSEntityDescription.entityForName("Settings", inManagedObjectContext: coreDataStack.managedObjectContext) {
                let settings = Settings(entity: entity, insertIntoManagedObjectContext: coreDataStack.managedObjectContext)
                
                if let required = passwordRequired {
                    settings.password_required = required
                }
                if let password = password {
                    settings.password = password
                }
                if let touchID = touchID {
                    settings.use_touch_id = touchID
                }
                
            }
        }
        
        coreDataStack.saveContext()
    }
    

    
    // For development 
    private func clearAllSettings() {
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
    }
    
}


extension SettingsTableViewController: SetPasswordTableViewControllerDelegate {
    func setPasswordTableViewController(controller: SetPasswordTableViewController, didFinishSettingPassword password: String, touchID: Bool) {
        saveSettings(passwordRequiredSwitch.on, password: password, touchID: touchID)
    }
    
    func setPasswordTableViewControllerDidCancel(controller: SetPasswordTableViewController) {
        passwordRequiredSwitch.on = false
    }
    
}
