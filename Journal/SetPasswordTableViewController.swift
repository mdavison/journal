//
//  SetPasswordTableViewController.swift
//  Journal
//
//  Created by Morgan Davison on 4/6/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

import UIKit

protocol SetPasswordTableViewControllerDelegate: class {
    func setPasswordTableViewController(controller: SetPasswordTableViewController, didFinishSettingPassword password: String)
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
    
    
    // MARK: - Actions
    
    @IBAction func done(sender: UIBarButtonItem) {
        validatePassword()
        
        if passwordIsValid {
            if let password = passwordTextField.text {
                delegate?.setPasswordTableViewController(self, didFinishSettingPassword: password)
                dismissViewControllerAnimated(true, completion: nil)
            }
        }
    }
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        delegate?.setPasswordTableViewControllerDidCancel(self)
        dismissViewControllerAnimated(true, completion: nil)
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
    }
    
}
