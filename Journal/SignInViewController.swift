//
//  SignInViewController.swift
//  Journal
//
//  Created by Morgan Davison on 4/4/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

import UIKit
import CoreData

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

}
