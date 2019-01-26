//
//  ChangePasswordTableViewController.swift
//  Journal
//
//  Created by Morgan Davison on 5/9/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

import UIKit
import LocalAuthentication

protocol ChangePasswordTableViewControllerDelegate: class {
    func changePasswordTableViewController(_ controller: ChangePasswordTableViewController, didFinishChangingPassword password: String, hint: String?, touchID: Bool)
}

class ChangePasswordTableViewController: UITableViewController {

    @IBOutlet weak var currentPasswordTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var verifyPasswordTextField: UITextField!
    @IBOutlet weak var hintTextField: UITextField!
    @IBOutlet weak var useTouchIDSwitch: UISwitch!
    
    var delegate: ChangePasswordTableViewControllerDelegate?
    var passwordIsValid = true
    var settings:Settings?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Theme
        Theme.setup(withNavigationController: navigationController)
        
        hintTextField.text = settings?.password_hint
        
        if touchIDEnabled() {
            if settings?.use_touch_id == true {
                useTouchIDSwitch.isOn = true 
            }
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 4
        case 1:
            return touchIDEnabled() ? 1 : 0
        default: return 0
        }
    }
    
    // Change header text from default all caps
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if view.isKind(of: UITableViewHeaderFooterView.self) {
            if let tableViewHeaderFooterView = view as? UITableViewHeaderFooterView {
                tableViewHeaderFooterView.textLabel!.text = NSLocalizedString("Change your password", comment: "")
            }
        }
    }
    
    
    // MARK: - Actions
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        validatePassword()
        
        if passwordIsValid {
            if let password = passwordTextField.text {
                delegate?.changePasswordTableViewController(self, didFinishChangingPassword: password, hint: hintTextField.text, touchID: useTouchIDSwitch.isOn)
                dismiss(animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    
    // MARK: - Helper Methods
    
    fileprivate func validatePassword() {
        // Current password field can't be blank
        if currentPasswordTextField.text!.count == 0 {
            passwordIsValid = false
            
            invalidPasswordAlert("Enter current password", alertTitleComment: "Current password text field is blank.")
            
            return
        }
        // Get current password from keychain
        let currentPassword = KeychainWrapper.standard.string(forKey: "password")
        
        // Current password field must match current password
        if currentPasswordTextField.text != currentPassword {
            passwordIsValid = false
            
            invalidPasswordAlert("Current password is incorrect", alertTitleComment: "Current password text does not match saved password.")
            
            return
        }
        
        // Password field can't be blank
        if passwordTextField.text!.count == 0 {
            passwordIsValid = false

            invalidPasswordAlert("Enter a password", alertTitleComment: "Password text field is blank.")
            
            return
        }
        
        // Verify password text field must match password text field
        if passwordTextField.text != verifyPasswordTextField.text {
            passwordIsValid = false

            invalidPasswordAlert("Passwords Don't Match", alertTitleComment: "Password and Confirm Password text fields are not the same.")
            
            return
        }
        
        passwordIsValid = true
        
    }
    
    fileprivate func invalidPasswordAlert(_ alertTitle: String, alertTitleComment: String) {
        let alertTitle = NSLocalizedString(alertTitle, comment: alertTitleComment)
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
