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
    @IBOutlet weak var changePasswordLabel: UILabel!
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Remove duplicate nav controller
        tabBarController?.navigationController?.isNavigationBarHidden = true
        
        //changePasswordButton.enabled = KeychainWrapper.standardKeychainAccess().hasValueForKey("password")
        changePasswordLabel.isEnabled = KeychainWrapper.standard.hasValue(forKey: "password")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: - Navigation
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == Storyboard.ChangePasswordSegueIdentifier {
            if !KeychainWrapper.standard.hasValue(forKey: "password") {
                return false
            }
        }
        
        return true 
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case Storyboard.SetPasswordSegueIdentifier:
                guard let navigationController = segue.destination as? UINavigationController,
                    let controller = navigationController.topViewController as? SetPasswordTableViewController
                    else { break }
                
                controller.delegate = self
                
            case Storyboard.ChangePasswordSegueIdentifier:
                guard let navigationController = segue.destination as? UINavigationController,
                    let controller = navigationController.topViewController as? ChangePasswordTableViewController
                    else { break }
                
                controller.delegate = self
                controller.settings = settings
            default:
                return
            }
        }
    }
    
    
    // MARK: - Actions
    
    @IBAction func requirePasswordSwitchChanged(_ sender: UISwitch) {
        if sender.isOn { // Switched On
            //let keychainPassword = KeychainWrapper.standardKeychainAccess().stringForKey("password")
            let passwordIsSet = KeychainWrapper.standard.hasValue(forKey: "password")
            
            if passwordIsSet { // Password already in keychain, save settings to require password
                saveSettings(true, password: nil, hint: nil, touchID: nil)
                JournalVariables.userIsAuthenticated = false
            } else { // No password set
                performSegue(withIdentifier: Storyboard.SetPasswordSegueIdentifier, sender: nil)
            }
        } else { // Switched Off
            saveSettings(false, password: nil, hint: nil, touchID: false)
        }
    }
    
    @IBAction func exportEntries(_ sender: UIButton) {
        let (urlForExportData, error) = Entry.getURLForExportData(withCoreDataStack: coreDataStack)
        
        if let url = urlForExportData {
            let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            
            if let popoverController = activityViewController.popoverPresentationController {
                popoverController.sourceView = sender
            }
            
            present(activityViewController, animated: true, completion: nil)
        } else {
            // Show error alert
            if let error = error {
                let alertController = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(action)
                
                present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    fileprivate func setSettings() {
        if let settings = Settings.getSettings(withCoreDataStack: coreDataStack) {
            self.settings = settings
        }
    }
    
    fileprivate func setupView() {
        if let settings = settings {
            if settings.password_required == true {
                passwordRequiredSwitch.isOn = true
            }
        }
    }
    
    fileprivate func saveSettings(_ passwordRequired: Bool?, password: String?, hint: String?, touchID: Bool?) {
        if let settings = Settings.saveSettings(withCoreDataStack: coreDataStack,
                                                passwordRequired: passwordRequired,
                                                password: password,
                                                hint: hint,
                                                touchID: touchID) {
            self.settings = settings
        }
    }
    

    
    // For development 
    fileprivate func clearAllSettings() {
        Settings.clearAllSettings(withCoreDataStack: coreDataStack)
    }
    
}


extension SettingsTableViewController: SetPasswordTableViewControllerDelegate {
    func setPasswordTableViewController(_ controller: SetPasswordTableViewController, didFinishSettingPassword password: String, hint: String?, touchID: Bool) {
        saveSettings(passwordRequiredSwitch.isOn, password: password, hint: hint, touchID: touchID)
    }
    
    func setPasswordTableViewControllerDidCancel(_ controller: SetPasswordTableViewController) {
        passwordRequiredSwitch.isOn = false
    }
}

extension SettingsTableViewController: ChangePasswordTableViewControllerDelegate {
    func changePasswordTableViewController(_ controller: ChangePasswordTableViewController, didFinishChangingPassword password: String, hint: String?,  touchID: Bool) {
        saveSettings(passwordRequiredSwitch.isOn, password: password, hint: hint, touchID: touchID)
    }
}
