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
    func setPasswordTableViewController(_ controller: SetPasswordTableViewController, didFinishSettingPassword password: String, hint: String?, touchID: Bool)
    func setPasswordTableViewControllerDidCancel(_ controller: SetPasswordTableViewController)
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

        // Theme
        Theme.setup(withNavigationController: navigationController)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table View data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 3
        case 1:
            return touchIDEnabled() ? 1 : 0
        default: return 0
        }
    }

    // Change header text from default all caps
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if view.isKind(of: UITableViewHeaderFooterView.self) {
            if let tableViewHeaderFooterView = view as? UITableViewHeaderFooterView {
                tableViewHeaderFooterView.textLabel!.text = NSLocalizedString("Create a password for all your journal entries", comment: "")
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func done(_ sender: UIBarButtonItem) {
        validatePassword()
        if passwordIsValid {
            if let password = passwordTextField.text {
                delegate?.setPasswordTableViewController(self, didFinishSettingPassword: password, hint: hintTextField.text, touchID: useTouchIDSwitch.isOn)
                dismiss(animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        delegate?.setPasswordTableViewControllerDidCancel(self)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func useTouchIdSwitchChanged(_ sender: UISwitch) {
        //useTouchID = sender.on
        //print("useTouchID?: \(useTouchID)")
    }
    
    // MARK: - Helper Methods
    
    fileprivate func validatePassword() {
        if passwordTextField.text!.count == 0 {
        //if passwordTextField.text!.characters.count == 0 {
            passwordIsValid = false
            
            invalidPasswordAlert("Enter a Password", titleComment: "Password text field is blank.")
            
            return
        }
        if passwordTextField.text != verifyPasswordTextField.text {
            passwordIsValid = false
            
            invalidPasswordAlert("Passwords Don't Match", titleComment: "Password and Confirm Password text fields are not the same.")
            
            return
        }
        
        passwordIsValid = true
    }
    
    fileprivate func invalidPasswordAlert(_ title: String, titleComment: String) {
        let alertTitle = NSLocalizedString(title, comment: titleComment)
        let alert = UIAlertController(title: alertTitle, message: nil, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alert.addAction(action)
        present(alert, animated: true, completion:nil)

    }
    
    fileprivate func touchIDEnabled() -> Bool {
        let laContext = LAContext()
        var error: NSError? = nil
        
        if laContext.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return true
        }
        
        return false
    }
    
}
