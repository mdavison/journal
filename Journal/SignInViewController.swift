//
//  SignInViewController.swift
//  Journal
//
//  Created by Morgan Davison on 4/4/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

import UIKit
import CoreData
import LocalAuthentication

class SignInViewController: UIViewController {

    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var passwordIncorrectLabel: UILabel!
    @IBOutlet weak var passwordHintLabel: UILabel!
    @IBOutlet weak var showPasswordHintButton: UIButton!
    
    var coreDataStack: CoreDataStack!
    var settings: Settings?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            coreDataStack = appDelegate.coreDataStack
            settings = appDelegate.settings
        }
        
        passwordTextField.delegate = self
        passwordTextField.becomeFirstResponder()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // If already authenticated, dismiss
        if JournalVariables.userIsAuthenticated {
            dismissViewControllerAnimated(true, completion: nil)
        } else {
            if let settings = settings {
                // Touch ID
                if settings.use_touch_id == true {
                    authenticateWithTouchID()
                }
                if settings.password_hint == nil || settings.password_hint == "" {
                    showPasswordHintButton.hidden = true
                }
            }
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Actions
    
    @IBAction func submit(sender: UIButton) {       
        checkPassword()
    }
    
    @IBAction func showPasswordHint(sender: UIButton) {
        passwordHintLabel.text = settings?.password_hint
        passwordHintLabel.hidden = false
    }
    
    // MARK: - Helper Methods
    
    private func authenticateWithTouchID() {
        let laContext = LAContext()
        var error: NSError? = nil
        
        if laContext.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: &error) {
            // Authenticate user
            laContext.evaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics,
                                     localizedReason: "Sign in with Touch ID",
                                     reply: { (success, evaluationError) in

                if success {
                    NSOperationQueue.mainQueue().addOperationWithBlock({
                        JournalVariables.userIsAuthenticated = true
                        self.dismissViewControllerAnimated(true, completion: nil)
                    })
                    //JournalVariables.userIsAuthenticated = true
                    //self.dismissViewControllerAnimated(true, completion: nil)
                } else {
                    //print("not the owner")
                    if let error = evaluationError {
                        switch error.code {
                        case LAError.SystemCancel.rawValue:
                            // Cancelled by user
                            NSLog("SystemCancel")
                        case LAError.UserCancel.rawValue:
                            NSLog("UserCancel")
                        case LAError.UserFallback.rawValue:
                            // user selected "Enter password"
                            NSLog("UserFallback")
                            NSOperationQueue.mainQueue().addOperationWithBlock({
                                // dismiss the touch ID
                                return
                            })
                        default:
                            return
                        }
                    }
                    
                    print("Authentication Failed")
                    NSOperationQueue.mainQueue().addOperationWithBlock({
                        // dismiss the touch ID
                        return
                    })
                }
            })
        } else {
            NSLog("Device doesn't have touch id")
            if let error = error {
                switch error.code {
                case LAError.TouchIDNotEnrolled.rawValue:
                    NSLog("TouchID not enrolled")
                case LAError.PasscodeNotSet.rawValue:
                    NSLog("Passcode not set")
                default:
                    NSLog("Touch ID not available")
                }
            }
        }
        
    }
    
    private func checkPassword() {
        let keychainPassword = KeychainWrapper.standardKeychainAccess().stringForKey("password")
        
        if passwordTextField.text == keychainPassword {
            JournalVariables.userIsAuthenticated = true
            dismissViewControllerAnimated(true, completion: nil)
        } else {
            passwordIncorrectLabel.hidden = false
            passwordTextField.text = ""
        }
    }


}


extension SignInViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        checkPassword()
        resignFirstResponder()
        
        return true
    }
}
