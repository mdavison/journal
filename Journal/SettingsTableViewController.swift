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
        if sender.on {
            if let settings = settings {
                if settings.password == nil { // No password set
                    performSegueWithIdentifier(Storyboard.SetPasswordSegueIdentifier, sender: nil)
                } else {
                    saveSettings(sender.on, password: nil)
                }
            } else {
                performSegueWithIdentifier(Storyboard.SetPasswordSegueIdentifier, sender: nil)
            }
        } else {
            saveSettings(sender.on, password: nil)
        }
    }
    
    @IBAction func exportEntries(sender: UIButton) {
        print("export entries")
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
    
    private func saveSettings(passwordRequired: Bool?, password: String?) {
        if let setting = settings {
            // Update existing
            if let required = passwordRequired {
                setting.password_required = required
            }
            if let password = password {
                setting.password = password
            }
            coreDataStack.saveContext()
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
                coreDataStack.saveContext()
            }
        }
    }
    
    // For development only
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
    func setPasswordTableViewController(controller: SetPasswordTableViewController, didFinishSettingPassword password: String) {
        print("password: \(password)")
        saveSettings(passwordRequiredSwitch.on, password: password)
    }
    
    func setPasswordTableViewControllerDidCancel(controller: SetPasswordTableViewController) {
        passwordRequiredSwitch.on = false
    }
}
