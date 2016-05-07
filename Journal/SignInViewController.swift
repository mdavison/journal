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
    
    var coreDataStack: CoreDataStack!
    var settings: Settings?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            coreDataStack = appDelegate.coreDataStack
            settings = appDelegate.settings
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // If already authenticated, dismiss
        if JournalVariables.userIsAuthenticated {
            dismissViewControllerAnimated(true, completion: nil)
        } else {
            // Touch ID
            if let _ = settings?.use_touch_id {
                authenticateWithTouchID()
            }
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Actions
    
    @IBAction func submit(sender: UIButton) {       
        if let settings = settings {
            if let passwordEntered = passwordTextField.text {
                if passwordEntered == settings.password {
                    JournalVariables.userIsAuthenticated = true
                    dismissViewControllerAnimated(true, completion: nil)
                }
            }
        }
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


}
