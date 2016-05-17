//
//  SetPasswordTableViewController.swift
//  Journal
//
//  Created by Morgan Davison on 4/6/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

import UIKit
import LocalAuthentication

protocol SetPasswordTableViewControllerDelegate: class {
    func setPasswordTableViewController(controller: SetPasswordTableViewController, didFinishSettingPassword password: String, hint: String?, touchID: Bool)
    func setPasswordTableViewControllerDidCancel(controller: SetPasswordTableViewController)
}

class SetPasswordTableViewController: UITableViewController {

    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var verifyPasswordTextField: UITextField!
    @IBOutlet weak var hintTextField: UITextField!
    @IBOutlet weak var useTouchIDSwitch: UISwitch!
    
    var delegate: SetPasswordTableViewControllerDelegate?
    var passwordIsValid = true
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table View data source
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 3
        case 1:
            return touchIDEnabled() ? 1 : 0
        default: return 0
        }
    }

    // Change header text from default all caps
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if view.isKindOfClass(UITableViewHeaderFooterView) {
            if let tableViewHeaderFooterView = view as? UITableViewHeaderFooterView {
                tableViewHeaderFooterView.textLabel!.text = NSLocalizedString("Create a password for all your journal entries", comment: "")
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func done(sender: UIBarButtonItem) {
        validatePassword()
        print("hint: \(hintTextField.text)")
        if passwordIsValid {
            if let password = passwordTextField.text {
                delegate?.setPasswordTableViewController(self, didFinishSettingPassword: password, hint: hintTextField.text, touchID: useTouchIDSwitch.on)
                dismissViewControllerAnimated(true, completion: nil)
            }
        }
    }
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        delegate?.setPasswordTableViewControllerDidCancel(self)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func useTouchIdSwitchChanged(sender: UISwitch) {
        //useTouchID = sender.on
        //print("useTouchID?: \(useTouchID)")
    }
    
    // MARK: - Helper Methods
    
    private func validatePassword() {
        if passwordTextField.text!.characters.count == 0 {
            passwordIsValid = false
            
            let alertTitle = NSLocalizedString("Enter a Password", comment: "Password text field is blank.")
            let alert = UIAlertController(title: alertTitle, message: nil, preferredStyle: .Alert)
            let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
            
            alert.addAction(action)
            presentViewController(alert, animated: true, completion:nil)
            
            return
        }
        if passwordTextField.text != verifyPasswordTextField.text {
            passwordIsValid = false
            
            let alertTitle = NSLocalizedString("Passwords Don't Match", comment: "Password and Confirm Password text fields are not the same.")
            let alert = UIAlertController(title: alertTitle, message: nil, preferredStyle: .Alert)
            let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
            
            alert.addAction(action)
            presentViewController(alert, animated: true, completion:nil)
            
            return
        }
        
        passwordIsValid = true
    }
    
    private func touchIDEnabled() -> Bool {
        let laContext = LAContext()
        var error: NSError? = nil
        
        if laContext.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: &error) {
            return true
        }
        
        return false
    }
    
}
