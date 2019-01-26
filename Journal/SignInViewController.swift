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
    let keychainPassword = KeychainWrapper.standard.string(forKey: "password")
    var failedAttempts = 0
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            coreDataStack = appDelegate.coreDataStack
            settings = appDelegate.settings
        }
        
        passwordTextField.delegate = self
        passwordTextField.becomeFirstResponder()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // If already authenticated, dismiss
        if JournalVariables.userIsAuthenticated {
            dismiss(animated: true, completion: nil)
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
    
    @IBAction func submit(_ sender: UIButton) {       
        checkPassword()
    }
    
    
    // MARK: - Notification Handling
    
    @objc fileprivate func keyboardDidToggle(_ notification: Notification) {
        print("keyboardDidToggle notification handled")
    }
    
    @objc fileprivate func keyboardDidShow(_ notification: Notification) {
        print("keyboardDidShow notification handled")
    }

    @objc fileprivate func keyboardDidHide(_ notification: Notification) {
        print("keyboardDidHide notification handled")
    }
    
    
    // MARK: - Helper Methods
    
    fileprivate func authenticateWithTouchID() {
        let laContext = LAContext()
        var error: NSError? = nil
        
        if laContext.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // Authenticate user
            laContext.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics,
                                     localizedReason: "Sign in with Touch ID",
                                     reply: { (success, evaluationError) in

                if success {
                    OperationQueue.main.addOperation({
                        JournalVariables.userIsAuthenticated = true
                        self.dismiss(animated: true, completion: nil)
                    })
                    //JournalVariables.userIsAuthenticated = true
                    //self.dismissViewControllerAnimated(true, completion: nil)
                } else {
                    //print("not the owner")
                    if let error = evaluationError as NSError? {
                        switch error.code {
                        case LAError.Code.systemCancel.rawValue:
                            // Cancelled by user
                            NSLog("SystemCancel")
                        case LAError.Code.userCancel.rawValue:
                            NSLog("UserCancel")
                        case LAError.Code.userFallback.rawValue:
                            // user selected "Enter password"
                            NSLog("UserFallback")
                            OperationQueue.main.addOperation({
                                // dismiss the touch ID
                                return
                            })
                        default:
                            return
                        }
                    }
                    
                    print("Authentication Failed")
                    OperationQueue.main.addOperation({
                        // dismiss the touch ID
                        return
                    })
                }
            })
        } else {
            NSLog("Device doesn't have touch id")
            if let error = error {
                switch error.code {
                case LAError.Code.touchIDNotEnrolled.rawValue:
                    NSLog("TouchID not enrolled")
                case LAError.Code.passcodeNotSet.rawValue:
                    NSLog("Passcode not set")
                default:
                    NSLog("Touch ID not available")
                }
            }
        }
        
    }
    
    fileprivate func checkPassword() {
        if passwordTextField.text == keychainPassword {
            JournalVariables.userIsAuthenticated = true
            dismiss(animated: true, completion: nil)
        } else {
            // Password is wrong - make the stackView shake
            let animation = CABasicAnimation(keyPath: "position")
            animation.duration = 0.05
            animation.repeatCount = 2
            animation.autoreverses = true
            animation.fromValue = NSValue(cgPoint: CGPoint(x: stackView.center.x - 6.0, y: stackView.center.y))
            animation.toValue = NSValue(cgPoint: CGPoint(x: stackView.center.x + 6.0, y: stackView.center.y))
            stackView.layer.add(animation, forKey: "position")
            
            
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        checkPassword()
        resignFirstResponder()
        
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SignInViewController.keyboardDidShow(_:)), name: UIKeyboardDidShowNotification, object: nil)
//        
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SignInViewController.keyboardDidHide(_:)), name: UIKeyboardDidHideNotification, object: nil)
        
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SignInViewController.keyboardDidToggle(_:)), name: UIKeyboardWillChangeFrameNotification, object: nil)
        
        return true
    }
    
}
