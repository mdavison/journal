//
//  SetPasswordViewController.swift
//  Journal
//
//  Created by Morgan Davison on 4/4/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

//import UIKit
//
//protocol SetPasswordViewControllerDelegate: class {
//    func setPasswordViewController(controller: SetPasswordViewController, didFinishSettingPassword password: String)
//    func setPasswordViewControllerDidCancel(controller: SetPasswordViewController)
//}
//
//class SetPasswordViewController: UIViewController, UITextFieldDelegate {
//
//    @IBOutlet weak var saveButton: UIBarButtonItem!
//    @IBOutlet weak var passwordTextField: UITextField!
//    @IBOutlet weak var confirmPasswordTextField: UITextField!
//    
//    var delegate: SetPasswordViewControllerDelegate?
//    var passwordIsValid = true
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        // Do any additional setup after loading the view.
//        
//        // TODO: Make option to show password text
//    }
//
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }
//    
//
//    /*
//    // MARK: - Navigation
//
//    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        // Get the new view controller using segue.destinationViewController.
//        // Pass the selected object to the new view controller.
//    }
//    */
//    
//    
//    // MARK: - Actions
//    
//    @IBAction func save(sender: UIBarButtonItem) {
//        validatePassword()
//        
//        if passwordIsValid {
//            if let password = passwordTextField.text {
//                delegate?.setPasswordViewController(self, didFinishSettingPassword: password)
//                dismissViewControllerAnimated(true, completion: nil)
//            }
//        }
//    }
//    
//    @IBAction func cancel(sender: UIBarButtonItem) {
//        delegate?.setPasswordViewControllerDidCancel(self)
//        dismissViewControllerAnimated(true, completion: nil)
//    }
//    
//    
//    // MARK: - UITextFieldDelegate Methods
//    
////    func textFieldDidBeginEditing(textField: UITextField) {
////        textField.becomeFirstResponder()
////        print("textFieldDidBeginEditing - textFieldText: \(textField.text)")
////        //validatePassword()
////        //saveButton.enabled = false
////    }
//    
////    func textFieldShouldReturn(textField: UITextField) -> Bool {
////        print("textFieldShouldReturn")
////        resignFirstResponder()
////        
////        return true
////    }
//    
////    func textFieldDidEndEditing(textField: UITextField) {
////        print("textFieldDidEndEditing") // LEFT OFF HERE - hitting "done" on keyboard doesn't end editing
////        //validatePassword()
////    }
//    
//    
////    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
////        let oldText: NSString = textField.text!
////        print("oldText: \(oldText)")
////        let newText: NSString = oldText.stringByReplacingCharactersInRange(range, withString: string)
////        print("newText: \(newText)")
////        //print("textFieldShouldChangeCharactersInRange newTExt: \(newText)")
////        
////        if textField.tag == 1 {
////            validatePassword(newText as String, withConfirmPassword: confirmPasswordTextField.text!)
////        } else if textField.tag == 2 {
////            validatePassword(passwordTextField.text!, withConfirmPassword: newText as String)
////        }
////        
////        // when there is text in the field and user types in that field again, the text field gets cleared in the ui but this method adds to existing
////        
////        return true
////    }
//    
//    
//    // MARK: - Helper Methods
//    
////    private func validatePassword() {
////        print("validate password: \(passwordTextField.text)")
////        print("validate password confirm: \(confirmPasswordTextField.text)")
//////        if let passwordFieldTextString = passwordTextField.text {
//////            if passwordFieldTextString.characters.count == 0 {
//////                saveButton.enabled = false
//////            } else {
//////                
//////            }
//////        }
////        
////        if passwordTextField.text!.characters.count == 0 {
////            // Password field blank
////            saveButton.enabled = false
////        } else {
////            if passwordTextField.text == confirmPasswordTextField.text {
////                // Password fields match
////                saveButton.enabled = true
////            } else {
////                // Password fields do not match
////                saveButton.enabled = false
////                // Show message that passwords not the same
////            }
////        }
////    }
//    
////    private func validatePassword(password: String, withConfirmPassword confirm: String) {
////        //print("password: \(password)")
////        //print("confirm: \(confirm)")
////        saveButton.enabled = (password == confirm)
////    }
//    
//    private func validatePassword() {
//        if passwordTextField.text!.characters.count == 0 {
//            passwordIsValid = false
//            
//            let alertTitle = NSLocalizedString("Enter a Password", comment: "Password text field is blank.")
//            let alert = UIAlertController(title: alertTitle, message: nil, preferredStyle: .Alert)
//            let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
//            
//            alert.addAction(action)
//            presentViewController(alert, animated: true, completion:nil)
//            
//            return
//        }
//        if passwordTextField.text != confirmPasswordTextField.text {
//            passwordIsValid = false
//            
//            let alertTitle = NSLocalizedString("Passwords Don't Match", comment: "Password and Confirm Password text fields are not the same.")
//            let alert = UIAlertController(title: alertTitle, message: nil, preferredStyle: .Alert)
//            let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
//            
//            alert.addAction(action)
//            presentViewController(alert, animated: true, completion:nil)
//            
//            return
//        }
//    }
//    
////    private func passwordsMatch() -> Bool {
////        if passwordTextField.text == confirmPasswordTextField.text {
////            return true
////        }
////        
////        return false
////    }
//    
//    
//
//
//}
