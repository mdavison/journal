//
//  SetPasswordViewController.swift
//  Journal
//
//  Created by Morgan Davison on 4/4/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

import UIKit

class SetPasswordViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    // MARK: - Actions
    
    @IBAction func save(sender: UIBarButtonItem) {
        // check that passwords match
        compareTextFields()
        
        // Save password
        savePassword()
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        // TODO: Set "password required" switch back to Off - probably through a delegate
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    // MARK: - UITextFieldDelegate Methods
    
    func textFieldDidEndEditing(textField: UITextField) {
        // compare password and confirm password
        compareTextFields()
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        // remove whitespace
        return true 
    }
    
    
    // MARK: - Helper Methods
    
    private func compareTextFields() {
        
    }
    
    private func savePassword() {
        let password = passwordTextField.text
        
        
    }

}
