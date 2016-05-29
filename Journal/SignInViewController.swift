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
    @IBOutlet weak var passwordHintLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    
    var coreDataStack: CoreDataStack!
    var settings: Settings?
    let keychainPassword = KeychainWrapper.standardKeychainAccess().stringForKey("password")
    var failedAttempts = 0
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
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
    
    
    // MARK: - Notification Handling
    
    @objc private func keyboardDidToggle(notification: NSNotification) {
        print("keyboardDidToggle notification handled")
    }
    
    @objc private func keyboardDidShow(notification: NSNotification) {
        print("keyboardDidShow notification handled")
    }

    @objc private func keyboardDidHide(notification: NSNotification) {
        print("keyboardDidHide notification handled")
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
        if passwordTextField.text == keychainPassword {
            JournalVariables.userIsAuthenticated = true
            dismissViewControllerAnimated(true, completion: nil)
        } else {
            // Password is wrong - make the stackView shake
            let animation = CABasicAnimation(keyPath: "position")
            animation.duration = 0.05
            animation.repeatCount = 2
            animation.autoreverses = true
            animation.fromValue = NSValue(CGPoint: CGPointMake(stackView.center.x - 6.0, stackView.center.y))
            animation.toValue = NSValue(CGPoint: CGPointMake(stackView.center.x + 6.0, stackView.center.y))
            stackView.layer.addAnimation(animation, forKey: "position")
            
            
            failedAttempts += 1
            passwordTextField.text = ""
            
            if failedAttempts > 2 {
                if let hint = settings?.password_hint {
                    passwordHintLabel.text = "Hint: \(hint)"
                }
            }
        }
    }


}


extension SignInViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        checkPassword()
        resignFirstResponder()
        
        return true
    }
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SignInViewController.keyboardDidShow(_:)), name: UIKeyboardDidShowNotification, object: nil)
//        
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SignInViewController.keyboardDidHide(_:)), name: UIKeyboardDidHideNotification, object: nil)
        
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SignInViewController.keyboardDidToggle(_:)), name: UIKeyboardWillChangeFrameNotification, object: nil)
        
        return true
    }
    
}
